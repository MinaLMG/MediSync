const {
    Transaction,
    StockShortage,
    StockExcess,
    Pharmacy,
    Settings,
    User,
    ReversalTicket,
    Reservation
} = require('../models');
const mongoose = require('mongoose');
const { addNotificationJob } = require('../utils/queueManager');
const { sendToUser } = require('../utils/pusherManager');

// Service dependencies
const transactionService = require('../services/transactionService');
const serialService = require('../services/serialService');
const auditService = require('../services/auditService');

// Lazy-loaded services for circular dependency safety
const getShortageService = () => require('../services/shortageService');
const getExcessService = () => require('../services/excessService');

// =============================================================================
// MATCHING & ANALYTICS
// =============================================================================
exports.getMatchableProducts = async (req, res) => {
    try {
        const search = req.query.search || '';

        let searchRegex = search;
        if (search.includes('*')) {
            // Escape special regex characters except '*'
            const escaped = search.replace(/[.+?^${}()|[\]\\]/g, '\\$&');
            // Replace '*' with '.*' and add .* at start and end for partial matching
            searchRegex = `.*${escaped.replace(/\*/g, '.*')}.*`;
        }
        const matchable = await StockShortage.aggregate([
            { $match: { remainingQuantity: { $gt: 0 }, order: null } },
            { $group: { _id: "$product", shortageVolumes: { $addToSet: "$volume" } } },
            {
                $lookup: {
                    from: "stockexcesses",
                    let: { prodId: "$_id", sVolumes: "$shortageVolumes" },
                    pipeline: [
                        {
                            $match: {
                                $expr: {
                                    $and: [
                                        { $eq: ["$product", "$$prodId"] },
                                        { $in: ["$status", ["available", "partially_fulfilled"]] },
                                        { $gt: ["$remainingQuantity", 0] },
                                        { $in: ["$volume", "$$sVolumes"] }
                                    ]
                                }
                            }
                        },
                        {
                            $group: {
                                _id: "$product",
                                volumes: { $addToSet: "$volume" },
                                hasShortageFulfillment: { $max: "$shortage_fulfillment" }
                            }
                        }
                    ],
                    as: "excessInfo"
                }
            },
            { $unwind: "$excessInfo" },
            {
                $lookup: {
                    from: "products",
                    localField: "_id",
                    foreignField: "_id",
                    as: "product"
                }
            },
            { $unwind: "$product" },
            {
                $match: {
                    "product.status": "active",
                    "product.name": { $regex: searchRegex, $options: 'i' }
                }
            },
            {
                $project: {
                    _id: 0,
                    product: 1,
                    volumes: "$excessInfo.volumes",
                    hasShortageFulfillment: "$excessInfo.hasShortageFulfillment"
                }
            },
            { $sort: { "product.name": 1 } }
        ]);

        // Sort alphabetically by product name
        matchable.sort((a, b) => a.product.name.localeCompare(b.product.name));

        res.status(200).json({ success: true, count: matchable.length, data: matchable });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Get shortages and excesses for a specific product
// @route   GET /api/transaction/matches/:productId
// @access  Admin
exports.getMatchesForProduct = async (req, res) => {
    try {
        const { productId } = req.params;

        const shortages = await StockShortage.find({
            product: productId,
            remainingQuantity: { $gt: 0 },
            order: null
        }).populate('pharmacy', 'name balance address phone').populate('volume', 'name').sort({ createdAt: -1 });


        const excessQuery = {
            product: productId,
            status: { $in: ['available', 'partially_fulfilled'] },
            remainingQuantity: { $gt: 0 }
        };

        // If explicitly requested to exclude shortage fulfillment excesses (e.g. for market orders)
        if (req.query.excludeShortageFulfillment === 'true') {
            excessQuery.shortage_fulfillment = { $ne: true };
        }

        if (req.query.price) {
            // Convert to number for proper comparison
            excessQuery.selectedPrice = parseFloat(req.query.price);
        }

        if (req.query.expiryDate) {
            excessQuery.expiryDate = req.query.expiryDate;
        }

        if (req.query.salePercentage) {
            excessQuery.salePercentage = parseFloat(req.query.salePercentage);
        }

        const excesses = await StockExcess.find(excessQuery)
            .populate('pharmacy', 'name balance address phone')
            .populate('volume', 'name')
            .populate('product', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            data: {
                shortages,
                excesses
            }
        });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// =============================================================================
// TRANSACTION CREATION (ADMIN & SYSTEM)
// =============================================================================

// @desc    Create a new transaction (manual admin match)
// @route   POST /api/transaction
// @access  Admin
exports.createTransaction = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { shortageId, quantityTaken, excessSources } = req.body;

        // --- Manual Validation ---
        if (!shortageId || !quantityTaken || !excessSources || !Array.isArray(excessSources)) {
            throw { message: 'Missing required fields: shortageId, quantityTaken, and excessSources are required.', code: 400 };
        }
        if (quantityTaken <= 0) {
            throw { message: 'Quantity taken must be a positive number.', code: 400 };
        }
        for (const source of excessSources) {
            if (!source.stockExcessId || !source.quantity || source.quantity <= 0) {
                throw { message: 'Invalid excess source: stockExcessId and positive quantity are required.', code: 400 };
            }
        }

        const transaction = await transactionService.createTransaction(req.body, session, req);
        await session.commitTransaction();

        // Centralized Notifications (after commit)
        await transactionService.notifyParties(transaction);

        res.status(201).json({ success: true, data: transaction });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        console.error('❌ [Transaction Controller] createTransaction failed:', error);
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Fulfill an Order Item (Admin)
// Wraps createTransaction but specific for Order context
// @route   POST /api/transaction/fulfill
// @access  Admin
exports.fulfillOrder = async (req, res) => {
    // This is essentially createTransaction but we might want to ensure the excess price 
    // matches the order target price, or just allow admin override.
    // For now, we can reuse createTransaction logic but maybe adding a check?
    // Or just let the Admin decide. The core logic is the same: Shortage + Excess -> Transaction.
    // The Order status update is handled by syncShortageStatus which is called inside createTransaction.

    // So we can alias it or just use createTransaction?
    // User said: "apply this fulfillment for the order in a controller"
    // Let's create a specific endpoint to be explicit and allow for future "Order" specific logic.

    return exports.createTransaction(req, res);
};

// =============================================================================
// STATUS UPDATES
// =============================================================================

// @desc    Update transaction status (Accepted, Rejected, Completed, Cancelled)
// @route   PUT /api/transaction/:id/status
// @access  Admin
exports.updateTransactionStatus = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { status } = req.body;

        // --- Manual Validation ---
        if (!status || !['accepted', 'rejected', 'completed', 'cancelled'].includes(status)) {
            throw { message: 'Invalid status. Must be accepted, rejected, completed, or cancelled.', code: 400 };
        }

        const transaction = await transactionService.updateTransactionStatus(req.params.id, status, req, session);

        await session.commitTransaction();

        // Centralized Notifications (called after commit)
        await transactionService.notifyParties(transaction);

        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        if (session && session.inTransaction()) {
            await session.abortTransaction();
        }
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Assign a delivery user to a transaction
// @route   PUT /api/transaction/:id/assign
// @access  Delivery
exports.assignTransaction = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const transaction = await Transaction.findById(req.params.id).session(session);
        if (!transaction) throw { message: 'Transaction not found', code: 404 };
        if (transaction.delivery) throw { message: 'Transaction already assigned', code: 409 };

        transaction.delivery = req.user._id;
        await transaction.save({ session });
        await session.commitTransaction();

        const updatedTransaction = await Transaction.findById(transaction._id)
            .populate({
                path: 'stockShortage.shortage',
                populate: [
                    { path: 'pharmacy', select: 'name address phone' },
                    { path: 'product', select: 'name' },
                    { path: 'volume', select: 'name' },
                    { path: 'order', select: 'serial' }
                ]
            })
            .populate({
                path: 'stockExcessSources.stockExcess',
                populate: [
                    { path: 'pharmacy', select: 'name address phone' }
                ]
            })
            .populate('delivery', 'name phone');

        res.status(200).json({ success: true, data: updatedTransaction });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Unassign a delivery user from a transaction
// @route   PUT /api/transaction/:id/unassign
// @access  Admin
exports.unassignTransaction = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const transaction = await transactionService.unassignTransaction(req.params.id, session, req);
        await session.commitTransaction();

        // Centralized Notifications (called after commit)
        await transactionService.notifyParties(transaction);

        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        if (session && session.inTransaction()) {
            await session.abortTransaction();
        }
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Get all transactions (with filters for status)
// @route   GET /api/transaction
// @access  Admin, Delivery
exports.getTransactions = async (req, res) => {
    try {
        const { status } = req.query;
        let query = status ? { status } : {};

        let transactions = await Transaction.find(query)
            .populate({
                path: 'stockShortage.shortage',
                populate: [
                    { path: 'pharmacy', select: 'name address phone' },
                    { path: 'product', select: 'name' },
                    { path: 'volume', select: 'name' },
                    { path: 'order', select: 'serial' }
                ]
            })
            .populate({
                path: 'stockExcessSources.stockExcess',
                populate: [
                    { path: 'pharmacy', select: 'name address phone' }
                ]
            })
            .populate('delivery', 'name phone')
            .populate({
                path: 'reversalTicket',
                populate: [
                    { path: 'expenses.user', select: 'name' },
                    { path: 'expenses.pharmacy', select: 'name' }
                ]
            })
            .sort({ createdAt: -1 });

        // Post-fetch filtering for pharmacy owners
        if (req.user.role === 'pharmacy_owner' && req.user.pharmacy) {
            const myPharmacyId = req.user.pharmacy.toString();
            transactions = transactions.filter(t => {
                // Check if user's pharmacy is buyer
                const buyerPhId = t.stockShortage?.shortage?.pharmacy?._id?.toString();
                if (buyerPhId === myPharmacyId) return true;

                // Check if user's pharmacy is one of the sellers
                const isSeller = t.stockExcessSources?.some(source =>
                    source.stockExcess?.pharmacy?._id?.toString() === myPharmacyId
                );
                return isSeller;
            });
        }

        res.status(200).json({ success: true, count: transactions.length, data: transactions });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// =============================================================================
// REVERSALS & FINANCIAL CORRECTIONS
// =============================================================================

// @desc    Revert a completed transaction (restores stock, automatic balance reversal + expenses)
// @route   POST /api/transaction/:id/revert
// @access  Admin
exports.revertTransaction = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { id } = req.params;
        const { expenses, description } = req.body; // Array of { userId, amount }

        const transaction = await Transaction.findById(id).populate({
            path: 'stockShortage.shortage',
            populate: { path: 'pharmacy' }
        }).populate({
            path: 'stockExcessSources.stockExcess',
            populate: { path: 'pharmacy product volume' }
        }).session(session);

        if (!transaction) throw { message: 'Transaction not found', code: 404 };
        if (transaction.status !== 'completed') throw { message: 'Only completed transactions can be reverted', code: 409 };
        if (transaction.reversalTicket) throw { message: 'Transaction already reverted', code: 409 };

        // --- Manual Validation for Expenses ---
        if (expenses && expenses.length > 0) {
            for (const p of expenses) {
                if (p.amount < 0) {
                    throw { message: 'Expense amount cannot be negative', code: 400 };
                }
                if (!p.userId) {
                    throw { message: 'userId is required for each expense item.', code: 400 };
                }
            }
        }

        // Special handling for "Add to Hub" transactions
        if (transaction.added_to_hub && transaction.added_to_hub.excessId) {
            await transactionService.revertAddToHub(transaction, session, req);
            await session.commitTransaction();
            await transactionService.notifyParties(transaction);
            return res.status(200).json({ success: true, data: transaction });
        }

        // Change transaction status FIRST so sync status helpers ignore this transaction
        transaction.status = 'cancelled';
        await transaction.save({ session });

        // 1. Restore Stock Quantities
        const excessService = getExcessService();
        for (const source of transaction.stockExcessSources) {
            const excess = await StockExcess.findById(source.stockExcess._id).session(session);
            if (excess) {
                excess.remainingQuantity += source.quantity;
                await excessService.syncExcessStatus(excess, session);
            }
        }

        const shortageService = getShortageService();
        const shortage = await StockShortage.findById(transaction.stockShortage.shortage._id).session(session);
        if (shortage) {
            shortage.remainingQuantity += transaction.stockShortage.quantityTaken;
            await shortageService.syncShortageStatus(shortage, session);
        }

        // 2. Restore Reservations
        if (shortage && shortage.order) {
            const saleToLookup = shortage.originalSalePercentage || shortage.salePercentage || 0;
            for (const source of transaction.stockExcessSources) {
                await Reservation.findOneAndUpdate(
                    {
                        product: shortage.product,
                        volume: shortage.volume,
                        price: shortage.targetPrice,
                        expiryDate: shortage.expiryDate || "ANY",
                        salePercentage: saleToLookup
                    },
                    {
                        $inc: { quantity: source.quantity }
                    },
                    { upsert: true, session }
                );
            }
        }

        // 3. Financial Reversal (Automatic)

        // Revert Buyer
        const buyerPh = await Pharmacy.findById(transaction.stockShortage.shortage.pharmacy._id).session(session);
        if (buyerPh && transaction.stockShortage.balanceEffect) {
            const BalanceHistory = require('../models/BalanceHistory');
            const prevBalance = buyerPh.balance;
            buyerPh.balance -= transaction.stockShortage.balanceEffect; // Subtract the effect (which was negative)
            const newBalance = buyerPh.balance;
            await buyerPh.save({ session });

            // Record History
            await BalanceHistory.create([{
                pharmacy: buyerPh._id,
                type: 'transaction_payment',
                amount: -transaction.stockShortage.balanceEffect,
                previousBalance: prevBalance,
                newBalance: newBalance,
                relatedEntity: transaction._id,
                relatedEntityType: 'Transaction',
                description: `Reversal of payment for transaction #${transaction.serial}`,
                description_ar: `عكس عملية الدفع للمعاملة #${transaction.serial}`,
                product: transaction.stockShortage.shortage.product,
                quantity: transaction.stockShortage.quantityTaken,
                details: { type: 'reversal' }
            }], { session });

            // Notify buyer users
            const users = await User.find({ pharmacy: buyerPh._id });
            for (const user of users) {
                sendToUser(user._id.toString(), 'balanceUpdate', { balance: buyerPh.balance });
            }
        }

        // Revert Sellers
        for (const source of transaction.stockExcessSources) {
            const sellerPh = await Pharmacy.findById(source.stockExcess.pharmacy._id).session(session);
            if (sellerPh && source.balanceEffect) {
                const BalanceHistory = require('../models/BalanceHistory');
                const prevBalance = sellerPh.balance;
                sellerPh.balance -= source.balanceEffect; // Subtract the profit given
                const newBalance = sellerPh.balance;
                await sellerPh.save({ session });

                // Record History
                await BalanceHistory.create([{
                    pharmacy: sellerPh._id,
                    type: 'transaction_revenue',
                    amount: -source.balanceEffect,
                    previousBalance: prevBalance,
                    newBalance: newBalance,
                    relatedEntity: transaction._id,
                    relatedEntityType: 'Transaction',
                    description: `Reversal of revenue for transaction #${transaction.serial}`,
                    description_ar: `عكس عملية التحصيل للمعاملة #${transaction.serial}`,
                    product: source.stockExcess.product,
                    quantity: source.quantity,
                    details: { type: 'reversal' }
                }], { session });

                // Notify seller users
                const users = await User.find({ pharmacy: sellerPh._id });
                for (const user of users) {
                    sendToUser(user._id.toString(), 'balanceUpdate', { balance: sellerPh.balance });
                }
            }
        }

        // 4. Apply Expenses
        const resolvedExpenses = [];
        if (expenses && expenses.length > 0) {
            for (const p of expenses) {
                let pharmacy = null;
                let targetUser = null;

                // Resolve User/Pharmacy
                const user = await User.findById(p.userId).populate('pharmacy').session(session);
                if (user && user.pharmacy) {
                    pharmacy = await Pharmacy.findById(user.pharmacy._id).session(session);
                    targetUser = user._id;
                } else {
                    const pharm = await Pharmacy.findById(p.userId).session(session);
                    if (pharm) {
                        pharmacy = pharm;
                        const adminUser = await User.findOne({ pharmacy: pharm._id, role: 'admin' }).session(session);
                        if (adminUser) targetUser = adminUser._id;
                    }
                }

                if (pharmacy) {
                    const BalanceHistory = require('../models/BalanceHistory');
                    const prevBalance = pharmacy.balance;
                    pharmacy.balance -= p.amount; // Expense is deducted
                    const newBalance = pharmacy.balance;
                    await pharmacy.save({ session });

                    // Record History
                    await BalanceHistory.create([{
                        pharmacy: pharmacy._id,
                        type: 'expenses',
                        amount: -p.amount,
                        previousBalance: prevBalance,
                        newBalance: newBalance,
                        relatedEntity: transaction._id,
                        relatedEntityType: 'Transaction',
                        description: `Expense ticket for transaction #${transaction.serial}`,
                        description_ar: `تذكرة مصروفات للمعاملة #${transaction.serial}`,
                        details: { type: 'expenses' }
                    }], { session });

                    // Notify users

                    // Notify users
                    const pharmUsers = await User.find({ pharmacy: pharmacy._id });
                    for (const u of pharmUsers) {
                        sendToUser(u._id.toString(), 'balanceUpdate', { balance: pharmacy.balance });
                    }

                    resolvedExpenses.push({
                        user: targetUser,
                        pharmacy: pharmacy._id,
                        amount: p.amount
                    });
                }
            }
        }

        // 5. Create Reversal Ticket
        const ticket = new ReversalTicket({
            transaction: transaction._id,
            expenses: resolvedExpenses,
            description: description || 'Automatic reversal of original transaction'
        });
        await ticket.save({ session });

        // 6. Update Transaction
        transaction.reversalTicket = ticket._id;
        await transaction.save({ session });

        await session.commitTransaction();

        // Notify stakeholders about reversal
        await transactionService.notifyParties(transaction);

        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        console.error('❌ [Transaction Controller] revertTransaction failed:', error);
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// #region Update Reversal Ticket
// @desc    Update an existing reversal ticket
// @route   PUT /api/transaction/reversal/:id
// @access  Admin
exports.updateReversalTicket = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { expenses, description } = req.body;
        const ticket = await ReversalTicket.findById(req.params.id).session(session);

        if (!ticket) throw { message: 'Ticket not found', code: 404 };

        // 1. Revert Old Expenses
        for (const p of ticket.expenses) {
            const pharmacy = await Pharmacy.findById(p.pharmacy).session(session);
            if (pharmacy) {
                const BalanceHistory = require('../models/BalanceHistory');
                const prevBalance = pharmacy.balance;
                pharmacy.balance += p.amount; // Add back the deducted expense
                const newBalance = pharmacy.balance;
                await pharmacy.save({ session });

                // Record History
                await BalanceHistory.create([{
                    pharmacy: pharmacy._id,
                    type: 'expenses',
                    amount: p.amount,
                    previousBalance: prevBalance,
                    newBalance: newBalance,
                    relatedEntity: ticket.transaction,
                    relatedEntityType: 'Transaction',
                    description: `Reversal of expense for adjustment on transaction #${ticket.transaction.toString().slice(-6)}`,
                    description_ar: `عكس المصروفات لتعديل تذكرة المعاملة #${ticket.transaction.toString().slice(-6)}`,
                    details: { type: 'expense_reversal' }
                }], { session });

                const users = await User.find({ pharmacy: pharmacy._id });
                for (const u of users) {
                    sendToUser(u._id.toString(), 'balanceUpdate', { balance: pharmacy.balance });
                }
            }
        }

        // 2. Apply New Expenses
        const resolvedExpenses = [];
        if (expenses && expenses.length > 0) {
            for (const p of expenses) {
                // --- Manual Validation ---
                if (p.amount < 0) throw { message: 'Expense amount cannot be negative', code: 400 };

                let pharmacy = null;
                let targetUser = null;

                const user = await User.findById(p.userId).populate('pharmacy').session(session);
                if (user && user.pharmacy) {
                    pharmacy = await Pharmacy.findById(user.pharmacy._id).session(session);
                    targetUser = user._id;
                } else {
                    const pharm = await Pharmacy.findById(p.userId).session(session);
                    if (pharm) {
                        pharmacy = pharm;
                        const adminUser = await User.findOne({ pharmacy: pharm._id, role: 'admin' }).session(session);
                        if (adminUser) targetUser = adminUser._id;
                    }
                }

                if (pharmacy) {
                    const BalanceHistory = require('../models/BalanceHistory');
                    const prevBalance = pharmacy.balance;
                    pharmacy.balance -= p.amount; // Deduct new amount
                    const newBalance = pharmacy.balance;
                    await pharmacy.save({ session });

                    // Record History
                    await BalanceHistory.create([{
                        pharmacy: pharmacy._id,
                        type: 'expenses',
                        amount: -p.amount,
                        previousBalance: prevBalance,
                        newBalance: newBalance,
                        relatedEntity: ticket.transaction,
                        relatedEntityType: 'Transaction',
                        description: `Adjusted expense for transaction #${ticket.transaction.toString().slice(-6)}`,
                        description_ar: `تم تعديل تكاليف المعاملة #${ticket.transaction.toString().slice(-6)}`,
                        details: { type: 'expense_adjustment' }
                    }], { session });

                    const users = await User.find({ pharmacy: pharmacy._id });
                    for (const u of users) {
                        sendToUser(u._id.toString(), 'balanceUpdate', { balance: pharmacy.balance });
                    }

                    resolvedExpenses.push({
                        user: targetUser,
                        pharmacy: pharmacy._id,
                        amount: p.amount
                    });
                }
            }
        }

        // 3. Update Ticket
        ticket.expenses = resolvedExpenses;
        if (description) ticket.description = description;
        await ticket.save({ session });

        await ticket.populate([
            { path: 'expenses.user', select: 'name' },
            { path: 'expenses.pharmacy', select: 'name' }
        ]);

        await session.commitTransaction();
        res.status(200).json({ success: true, data: ticket });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        console.error('❌ [Transaction Controller] updateReversalTicket failed:', error);
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};
// #endregion

// #region Update Transaction Ratios
// @desc    Update transaction ratios (Admin)
// @route   PUT /api/transaction/:id/ratios
// @access  Admin
exports.updateTransactionRatios = async (req, res) => {
    try {
        const { buyerCommissionRatio, sellerBonusRatio } = req.body;
        const transaction = await Transaction.findById(req.params.id);

        if (!transaction) {
            throw { message: 'Transaction not found', code: 404 };
        }

        if (['completed', 'cancelled'].includes(transaction.status)) {
            throw { message: 'Cannot update ratios of a finished transaction', code: 409 };
        }

        if (buyerCommissionRatio !== undefined) {
            if (buyerCommissionRatio < 0 || buyerCommissionRatio > 100) {
                throw { message: 'Buyer commission ratio must be between 0 and 100.', code: 400 };
            }
            transaction.buyerCommissionRatio = buyerCommissionRatio / 100;
        }
        if (sellerBonusRatio !== undefined) {
            if (sellerBonusRatio < 0 || sellerBonusRatio > 100) {
                throw { message: 'Seller bonus ratio must be between 0 and 100.', code: 400 };
            }
            transaction.sellerBonusRatio = sellerBonusRatio / 100;
        }

        await transaction.save();

        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        console.error('[Error] updateTransactionRatios failed:', error);
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Update an existing transaction (modify quantities and resources)
// @route   PUT /api/transaction/:id
// @access  Admin
exports.updateTransaction = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { id } = req.params;
        const { quantityTaken, excessSources } = req.body;

        // --- Manual Validation ---
        if (quantityTaken !== undefined && quantityTaken <= 0) {
            throw { message: 'Quantity taken must be a positive number.', code: 400 };
        }
        if (excessSources && !Array.isArray(excessSources)) {
            throw { message: 'excessSources must be an array.', code: 400 };
        }

        // 1. Find transaction
        const transaction = await Transaction.findById(id).session(session);
        if (!transaction) throw { message: 'Transaction not found', code: 404 };

        if (!['pending', 'accepted'].includes(transaction.status)) {
            throw { message: 'Cannot modify a completed or cancelled transaction', code: 409 };
        }

        const shortageService = getShortageService();
        const excessService = getExcessService();

        // 2. Revert old stock changes
        // Restore shortage
        const shortage = await StockShortage.findById(transaction.stockShortage.shortage).session(session);
        if (!shortage) throw { message: 'Related shortage not found', code: 404 };

        shortage.remainingQuantity += transaction.stockShortage.quantityTaken;

        // Restore excesses
        for (const source of transaction.stockExcessSources) {
            const excess = await StockExcess.findById(source.stockExcess).session(session);
            if (excess) {
                excess.remainingQuantity += source.quantity;
                await excessService.syncExcessStatus(excess, session);
                // Restore reservation
                if (shortage && shortage.order) {
                    await Reservation.findOneAndUpdate(
                        {
                            product: excess.product,
                            volume: excess.volume,
                            price: excess.selectedPrice
                        },
                        { $inc: { quantity: source.quantity } },
                        { upsert: true, session }
                    );
                }
            }
        }

        // 3. Apply new changes
        if (quantityTaken > shortage.remainingQuantity) {
            throw { message: `Requested quantity (${quantityTaken}) exceeds remaining available needed (${shortage.remainingQuantity})`, code: 409 };
        }

        let newTotalAmount = 0;
        let newTotalQuantity = 0;
        const refinedSources = [];

        for (const source of excessSources) {
            const excess = await StockExcess.findById(source.stockExcessId).session(session);
            if (!excess || !['available', 'partially_fulfilled'].includes(excess.status) || excess.remainingQuantity < source.quantity) {
                throw { message: `Excess ${source.stockExcessId} is no longer available in requested quantity`, code: 409 };
            }

            // Deduct from excess
            excess.remainingQuantity -= source.quantity;
            await excessService.syncExcessStatus(excess, session);

            // Deduct from reservation
            if (shortage && shortage.order) {
                await Reservation.findOneAndUpdate(
                    {
                        product: excess.product,
                        volume: excess.volume,
                        price: excess.selectedPrice
                    },
                    { $inc: { quantity: -source.quantity } },
                    { session }
                );
            }

            const amount = source.quantity * excess.selectedPrice;
            newTotalAmount += amount;
            newTotalQuantity += source.quantity;

            refinedSources.push({
                stockExcess: excess._id,
                quantity: source.quantity,
                agreedPrice: excess.selectedPrice,
                totalAmount: amount
            });
        }

        if (newTotalQuantity !== quantityTaken) {
            throw { message: 'Total quantity from sources does not match quantity taken from shortage', code: 400 };
        }

        // 4. Update shortage
        shortage.remainingQuantity -= quantityTaken;
        await shortageService.syncShortageStatus(shortage, session);

        // 5. Update transaction record
        transaction.stockShortage.quantityTaken = quantityTaken;
        transaction.stockExcessSources = refinedSources;
        transaction.totalQuantity = newTotalQuantity;
        transaction.totalAmount = newTotalAmount;

        await transaction.save({ session });

        await session.commitTransaction();
        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        console.error('❌ [Transaction Controller] updateTransaction failed:', error);
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};
