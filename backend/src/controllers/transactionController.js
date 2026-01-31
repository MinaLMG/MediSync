const { Transaction, StockShortage, StockExcess, Pharmacy, Settings, User, ReversalTicket, } = require('../models');
const mongoose = require('mongoose');
const { addNotificationJob } = require('../utils/queueManager');
const { syncExcessStatus } = require('../services/excessService');
const { syncShortageStatus } = require('../services/shortageService');
const { sendToUser } = require('../utils/pusherManager');
const transactionService = require('../services/transactionService');
const serialService = require('../services/serialService');
const auditService = require('../services/auditService');
// @desc    Get products that have both active shortages and available excesses
// @route   GET /api/transaction/matchable
// @access  Admin
exports.getMatchableProducts = async (req, res) => {
    try {
        const search = req.query.search || '';
        let matchQuery = { remainingQuantity: { $gt: 0 } };
        // Optimization: If search is provided, we can filter earlier or later.
        // Let's filter after grouping for simplicity or use $match after $lookup.
        const matchable = await StockShortage.aggregate([
            { $match: { remainingQuantity: { $gt: 0 }, order: null } },
            { $group: { _id: "$product", shortageVolumes: { $addToSet: "$volume" } } },
            {
                $lookup: {
                    from: "stockexcesses",
                    let: { prodId: "$_id", sVolumes: "$shortageVolumes" },
                    pipeline: [
                        { $match: { 
                            $expr: { 
                                $and: [
                                    { $eq: ["$product", "$$prodId"] },
                                    { $in: ["$status", ["available", "partially_fulfilled"]] },
                                    { $gt: ["$remainingQuantity", 0] },
                                    { $in: ["$volume", "$$sVolumes"] }
                                ]
                            }
                        } },
                        { $group: { 
                            _id: "$product", 
                            volumes: { $addToSet: "$volume" },
                            hasShortageFulfillment: { $max: "$shortage_fulfillment" }
                        } }
                    ],
                    as: "excessInfo"
                }
            },
            { $unwind: "$excessInfo" },
            { $lookup: {
                from: "products",
                localField: "_id",
                foreignField: "_id",
                as: "product"
            } },
            { $unwind: "$product" },
            { $match: { 
                "product.status": "active",
                "product.name": { $regex: search, $options: 'i' }
            } },
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
        res.status(500).json({ success: false, message: error.message });
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
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Create a new transaction
// @route   POST /api/transaction
// @access  Admin
exports.createTransaction = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { shortageId, quantityTaken, excessSources, buyerCommissionRatio, sellerBonusRatio, commissionRatio } = req.body;

        // 1. Check shortage
        const shortage = await StockShortage.findById(shortageId).session(session);
        if (!shortage || !['active', 'partially_fulfilled'].includes(shortage.status)) {
            throw new Error('Shortage not found or not active');
        }

        // 1.1 Check Product Status
        const productObj = await mongoose.model('Product').findById(shortage.product).session(session);
        if (!productObj || productObj.status !== 'active') {
            throw new Error('This product is currently inactive and cannot be transacted.');
        }

        const remainingNeeded = shortage.remainingQuantity;
        if (quantityTaken > remainingNeeded) {
            throw new Error(`Requested quantity (${quantityTaken}) exceeds remaining needed (${remainingNeeded})`);
        }

        let totalAmount = 0;
        let totalQuantity = 0;
        const refinedSources = [];

        // 2. Check and update excesses
        for (const source of excessSources) {
            const excess = await StockExcess.findById(source.stockExcessId).session(session);
            if (!excess || !['available', 'partially_fulfilled'].includes(excess.status) || excess.remainingQuantity < source.quantity) {
                throw new Error(`Excess ${source.stockExcessId} is no longer available in requested quantity`);
            }

            // Deduct from excess (don't sync status yet - transaction not saved)
            excess.remainingQuantity -= source.quantity;
            await excess.save({ session });

            const amount = source.quantity * excess.selectedPrice;
            totalAmount += amount;
            totalQuantity += source.quantity;

            refinedSources.push({
                stockExcess: excess._id,
                quantity: source.quantity,
                agreedPrice: excess.selectedPrice,
                totalAmount: amount
            });
        }

        if (totalQuantity !== quantityTaken) {
            throw new Error('Total quantity from sources does not match quantity taken from shortage');
        }

        // 3. Update shortage
        shortage.remainingQuantity -= quantityTaken;
        await syncShortageStatus(shortage);
        await shortage.save({ session });

        // 4. Generate Serial atomically
        const serial = await serialService.generateDateSerial('transaction');

        // 5. Create transaction
        const settings = await Settings.getSettings();
        const transaction = new Transaction({
            serial, // Add serial
            stockShortage: {
                shortage: shortageId,
                quantityTaken
            },
            stockExcessSources: refinedSources,
            totalQuantity,
            totalAmount,
            status: 'pending',
            shortage_fulfillment: req.body.shortage_fulfillment !== undefined ? req.body.shortage_fulfillment : true,
            commissionRatio: commissionRatio !== undefined ? commissionRatio / 100 : settings.minimumCommission / 100, // Default snapshot for real excess
            buyerCommissionRatio: buyerCommissionRatio !== undefined ? buyerCommissionRatio / 100 : settings.shortageCommission / 100,
            sellerBonusRatio: sellerBonusRatio !== undefined ? sellerBonusRatio / 100 : settings.shortageSellerReward / 100
        });

        await transaction.save({ session });

        // 6. NOW sync excess statuses (after transaction is saved)
        for (const source of excessSources) {
            const excess = await StockExcess.findById(source.stockExcessId).session(session);
            await syncExcessStatus(excess, session);
            await excess.save({ session });
        }

        await session.commitTransaction();

        // Notify Buyer about transaction creation
        try {
            console.log('🔔 [Transaction] Notifying Buyer(s)...');
            const product = await mongoose.model('Product').findById(shortage.product);
            const buyerPharmacy = await Pharmacy.findById(shortage.pharmacy);
            const buyerUsers = await User.find({ pharmacy: shortage.pharmacy });
            
            for (const buyer of buyerUsers) {
                console.log(`   -> Queueing for Buyer: ${buyer._id}`);
                await addNotificationJob(
                    buyer._id.toString(),
                    'transaction',
                    `Transaction #${serial}: New transaction created for "${product?.name || 'unknown medicine'}".`,
                    {
                        relatedEntity: transaction._id,
                        relatedEntityType: 'Transaction'
                    }
                );
            }

            // Notify Seller(s) about new transaction request
            console.log('🔔 [Transaction] Notifying Seller(s)...');
            for (const source of transaction.stockExcessSources) {
                const excess = await StockExcess.findById(source.stockExcess).populate('pharmacy');
                if (excess) {
                    const sellerUsers = await User.find({ pharmacy: excess.pharmacy._id });
                    for (const seller of sellerUsers) {
                        console.log(`   -> Queueing for Seller: ${seller._id} (Pharmacy: ${excess.pharmacy.name})`);
                        await addNotificationJob(
                            seller._id.toString(),
                            'transaction',
                            `Transaction #${serial}: New request for "${product?.name}"`,
                            {
                                relatedEntity: transaction._id,
                                relatedEntityType: 'Transaction'
                            }
                        );
                    }
                }
            }
            console.log('✅ [Transaction] Notification jobs queued successfully.');
        } catch (notifErr) {
            console.error('❌ [Transaction] Notification error in createTransaction:', notifErr);
        }

        res.status(201).json({ success: true, data: transaction });
    } catch (error) {
        console.error('❌ [Transaction] Transaction creation failed:', error);
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// @desc    Buy directly from market (Pharmacy)
// @route   POST /api/transaction/buy
// @access  Pharmacy Owner / Manager
exports.buyFromMarket = async (req, res) => {
    try {
        const { excessId, quantity } = req.body;
        
        if (!quantity || quantity < 1) {
            throw new Error('Quantity must be at least 1');
        }

        const excess = await StockExcess.findById(excessId).populate('product').populate('pharmacy').session(session);
        if (!excess || !['available', 'partially_fulfilled'].includes(excess.status) || excess.remainingQuantity < quantity) {
            throw new Error('This item is no longer available in the requested quantity.');
        }

        if (req.user.pharmacy && excess.pharmacy._id.toString() === req.user.pharmacy.toString()) {
            throw new Error('You cannot buy your own excess stock.');
        }

        // 1. Create a "Market Order" Shortage
        const shortage = new StockShortage({
            pharmacy: req.user.pharmacy,
            product: excess.product._id,
            volume: excess.volume,
            quantity: quantity,
            remainingQuantity: quantity, // Will be reduced immediately by transaction creation logic below
            status: 'active',
            type: 'market_order',
            notes: `Market purchase from ${excess.pharmacy.name}`
        });
        await shortage.save({ session });

        // 2. Prepare Transaction Data
        // Reuse logic from createTransaction but for single source
        const settings = await Settings.getSettings();
        
        // Deduct from excess
        excess.remainingQuantity -= quantity;
        await syncExcessStatus(excess, session);
        await excess.save({ session });

        const amount = quantity * excess.selectedPrice;
        
        // Deduct from shortage immediately as it is "filled" by this order
        shortage.remainingQuantity -= quantity;
        await syncShortageStatus(shortage);
        await shortage.save({ session });

        // Generate Serial atomically
        const serial = await serialService.generateDateSerial('transaction');

        // Create Transaction
        const transaction = new Transaction({
            serial,
            stockShortage: {
                shortage: shortage._id,
                quantityTaken: quantity
            },
            stockExcessSources: [{
                stockExcess: excess._id,
                quantity: quantity,
                agreedPrice: excess.selectedPrice,
                totalAmount: amount
            }],
            totalQuantity: quantity,
            totalAmount: amount,
            status: 'pending', // Awaiting Seller/Admin confirmation?
            shortage_fulfillment: excess.shortage_fulfillment, 
            commissionRatio: settings.minimumCommission / 100,
            buyerCommissionRatio: settings.shortageCommission / 100,
            sellerBonusRatio: settings.shortageSellerReward / 100
        });

        await transaction.save({ session });
        await session.commitTransaction();

        // 3. Notifications
        try {
            const buyerIds = [req.user._id]; // The current user
            // Notify Seller
            const sellerUsers = await User.find({ pharmacy: excess.pharmacy._id });

            // Notify Buyer (Confirmation)
            await addNotificationJob(
                req.user._id.toString(),
                'transaction',
                `Market Order #${serial}: Purchase of ${quantity} x ${excess.product.name} initiated.`,
                { relatedEntity: transaction._id, relatedEntityType: 'Transaction' }
            );

            // Notify Seller
            for (const seller of sellerUsers) {
                await addNotificationJob(
                    seller._id.toString(),
                    'transaction',
                    `Market Order #${serial}: New purchase request for ${excess.product.name} from market.`,
                    { relatedEntity: transaction._id, relatedEntityType: 'Transaction' }
                );
            }
        } catch (notifErr) {
            console.error('Notification error in buyFromMarket:', notifErr);
        }

        res.status(201).json({ success: true, data: transaction });

    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
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

// @desc    Update transaction status (Accepted, Rejected, Completed, Cancelled)
// @route   PUT /api/transaction/:id/status
// @access  Admin
exports.updateTransactionStatus = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { status } = req.body;
        const transaction = await Transaction.findById(req.params.id).session(session);

        if (!transaction) {
            throw new Error('Transaction not found');
        }

        if (transaction.status === 'completed' || transaction.status === 'cancelled') {
            throw new Error('Cannot change status of a finished transaction');
        }

        const oldStatus = transaction.status;
        transaction.status = status;

        if (status === 'cancelled' || status === 'rejected') {
            // Rollback logic
            // 1. Restore excess quantities
            for (const source of transaction.stockExcessSources) {
                const excess = await StockExcess.findById(source.stockExcess).session(session);
                if (excess) {
                    excess.remainingQuantity += source.quantity;
                    await syncExcessStatus(excess, session);
                    await excess.save({ session });
                }
            }

            // 2. Reduce shortage fulfillment
            const shortage = await StockShortage.findById(transaction.stockShortage.shortage).session(session);
            if (shortage) {
                shortage.remainingQuantity += transaction.stockShortage.quantityTaken;
                await syncShortageStatus(shortage, session);
                await shortage.save({ session });
            }
        } else if (status === 'completed') {
            await transactionService.settleTransaction(transaction, session);
        }

        await transaction.save({ session });
        await session.commitTransaction();

        // Centralized Notifications
        await transactionService.notifyParties(transaction);

        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// @desc    Assign a delivery user to a transaction
// @route   PUT /api/transaction/:id/assign
// @access  Delivery
exports.assignTransaction = async (req, res) => {
    try {
        const transaction = await Transaction.findById(req.params.id);
        if (!transaction) {
            return res.status(404).json({ success: false, message: 'Transaction not found' });
        }

        if (transaction.delivery) {
            return res.status(400).json({ success: false, message: 'Transaction already assigned' });
        }

        transaction.delivery = req.user._id;
        await transaction.save();

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
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Unassign a delivery user from a transaction
// @route   PUT /api/transaction/:id/unassign
// @access  Admin
exports.unassignTransaction = async (req, res) => {
    try {
        const transaction = await Transaction.findById(req.params.id);
        if (!transaction) {
            return res.status(404).json({ success: false, message: 'Transaction not found' });
        }

        const deliveryUserId = transaction.delivery;
        transaction.delivery = undefined;
        await transaction.save();

        if (deliveryUserId) {
            try {
                await addNotificationJob(
                    deliveryUserId.toString(),
                    'transaction',
                    `You have been detached from Transaction #${transaction._id.toString().slice(-6)}.`,
                    {
                        relatedEntity: transaction._id,
                        relatedEntityType: 'Transaction'
                    }
                );
            } catch (notifErr) {
                console.error('Notification error in unassignTransaction:', notifErr);
            }
        }

        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
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
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Revert a completed transaction (restores stock, automatic balance reversal + expenses)
// @route   POST /api/transaction/:id/revert
// @access  Admin
exports.revertTransaction = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { id } = req.params;
        const { expenses, description } = req.body; // Array of { userId, amount }

        const { Transaction, StockShortage, StockExcess, Pharmacy, User, ReversalTicket } = require('../models');

        const transaction = await Transaction.findById(id).populate({
            path: 'stockShortage.shortage',
            populate: { path: 'pharmacy' }
        }).populate({
            path: 'stockExcessSources.stockExcess',
            populate: { path: 'pharmacy' }
        }).session(session);

        if (!transaction) throw new Error('Transaction not found');
        if (transaction.status !== 'completed') throw new Error('Only completed transactions can be reverted');
        if (transaction.reversalTicket) throw new Error('Transaction already reverted');

        // Validate expenses
        if (expenses && expenses.length > 0) {
            for (const p of expenses) {
                if (p.amount < 0) {
                    throw new Error('Expense amount cannot be negative');
                }
            }
        }

        // Change transaction status FIRST so sync status helpers ignore this transaction
        transaction.status = 'cancelled';
        // Note: we don't save yet, we save at the end, but the in-memory object 
        // will be used by some logic, and the session will handle the rest.
        // Actually, we must save it if syncExcessStatus queries the DB.
        // Let's check syncExcessStatus. It queries TransactionModel.find.
        // So we MUST save it (within the session) before calling sync status.
        await transaction.save({ session });

        // 1. Restore Stock Quantities
        for (const source of transaction.stockExcessSources) {
            const excess = await StockExcess.findById(source.stockExcess._id).session(session);
            if (excess) {
                excess.remainingQuantity += source.quantity;
                await syncExcessStatus(excess, session);
                await excess.save({ session });
            }
        }

        const shortage = await StockShortage.findById(transaction.stockShortage.shortage._id).session(session);
        if (shortage) {
            shortage.remainingQuantity += transaction.stockShortage.quantityTaken;
            await syncShortageStatus(shortage, session);
            await shortage.save({ session });
        }

        // 2. Financial Reversal (Automatic)

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
                    details: { type: 'reversal' }
                }], { session });

                // Notify seller users
                const users = await User.find({ pharmacy: sellerPh._id });
                for (const user of users) {
                    sendToUser(user._id.toString(), 'balanceUpdate', { balance: sellerPh.balance });
                }
            }
        }

        // 3. Apply Expenses
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
                        details: { type: 'expenses' }
                    }], { session });

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

        // 4. Create Reversal Ticket
        const ticket = new ReversalTicket({
            transaction: transaction._id,
            expenses: resolvedExpenses,
            description: description || 'Automatic reversal of original transaction'
        });
        await ticket.save({ session });

        // 5. Update Transaction
        transaction.reversalTicket = ticket._id;
        // Status already set to cancelled at the beginning
        await transaction.save({ session });

        await session.commitTransaction();

        // Notify stakeholders about reversal
        await transactionService.notifyParties(transaction);

        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        if (session.inTransaction()) await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// @desc    Update a reversal ticket (adjusts expenses and balances)
// @route   PUT /api/transaction/reversal/:ticketId
// @access  Admin
exports.updateReversalTicket = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { ticketId } = req.params;
        const { expenses, description } = req.body; // New expense list

        const ticket = await ReversalTicket.findById(ticketId).session(session);
        if (!ticket) throw new Error('Reversal ticket not found');

        // 1. Revert Old Expenses (Refund the amounts taken)
        for (const oldE of ticket.expenses) {
            if (oldE.pharmacy) {
                const pharmacy = await Pharmacy.findById(oldE.pharmacy).session(session);
                if (pharmacy) {
                    const BalanceHistory = require('../models/BalanceHistory');
                    const prevBalance = pharmacy.balance;
                    pharmacy.balance += oldE.amount; // Add back the deducted amount
                    const newBalance = pharmacy.balance;
                    await pharmacy.save({ session });
                    
                    // Record History
                    await BalanceHistory.create([{
                        pharmacy: pharmacy._id,
                        type: 'expenses',
                        amount: oldE.amount,
                        previousBalance: prevBalance,
                        newBalance: newBalance,
                        relatedEntity: ticket.transaction,
                        relatedEntityType: 'Transaction',
                        description: `Refund for adjusted expense in transaction #${ticket.transaction.toString().slice(-6)}`,
                        details: { type: 'expense_refund' }
                    }], { session });

                    // Notify users
                    const users = await User.find({ pharmacy: pharmacy._id });
                    for (const u of users) {
                        sendToUser(u._id.toString(), 'balanceUpdate', { balance: pharmacy.balance });
                    }
                }
            }
        }

        // 2. Apply New Expenses
        const resolvedExpenses = [];
        if (expenses && expenses.length > 0) {
            for (const p of expenses) {
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
        if (session.inTransaction()) await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// @desc    Update transaction ratios (Admin)
// @route   PUT /api/transaction/:id/ratios
// @access  Admin
exports.updateTransactionRatios = async (req, res) => {
    try {
        const {  buyerCommissionRatio, sellerBonusRatio } = req.body;
        const transaction = await Transaction.findById(req.params.id);

        if (!transaction) {
            return res.status(404).json({ success: false, message: 'Transaction not found' });
        }

        if (['completed', 'cancelled'].includes(transaction.status)) {
            return res.status(400).json({ success: false, message: 'Cannot update ratios of a finished transaction' });
        }

        if (buyerCommissionRatio !== undefined) transaction.buyerCommissionRatio = buyerCommissionRatio / 100;
        if (sellerBonusRatio !== undefined) transaction.sellerBonusRatio = sellerBonusRatio / 100;

        await transaction.save();

        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
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

        // 1. Find transaction
        const transaction = await Transaction.findById(id).session(session);
        if (!transaction) {
            throw new Error('Transaction not found');
        }

        if (!['pending', 'accepted'].includes(transaction.status)) {
            throw new Error('Cannot modify a completed or cancelled transaction');
        }

        // 2. Revert old stock changes
        // Restore shortage
        const shortage = await StockShortage.findById(transaction.stockShortage.shortage).session(session);
        if (shortage) {
            shortage.remainingQuantity += transaction.stockShortage.quantityTaken;
            // Note: We'll sync status after applying new changes
        } else {
            throw new Error('Related shortage not found');
        }

        // Restore excesses
        for (const source of transaction.stockExcessSources) {
            const excess = await StockExcess.findById(source.stockExcess).session(session);
            if (excess) {
                excess.remainingQuantity += source.quantity;
                await syncExcessStatus(excess, session);
                await excess.save({ session });
            }
        }

        // 3. Apply new changes
        if (quantityTaken > shortage.remainingQuantity) {
             // This check is slightly different now because we restored the quantity
             // We need to check against the actual needs. 
             // Actually, shortage.quantity is the ORIGINAL target. 
             // remainingQuantity (after revert) is what's left if we hadn't made THIS transaction.
             // If they try to take more than remains, it's an error.
             throw new Error(`Requested quantity (${quantityTaken}) exceeds remaining available needed (${shortage.remainingQuantity})`);
        }

        let newTotalAmount = 0;
        let newTotalQuantity = 0;
        const refinedSources = [];

        for (const source of excessSources) {
            const excess = await StockExcess.findById(source.stockExcessId).session(session);
            if (!excess || !['available', 'partially_fulfilled'].includes(excess.status) || excess.remainingQuantity < source.quantity) {
                 throw new Error(`Excess ${source.stockExcessId} is no longer available in requested quantity`);
            }

            // Deduct from excess
            excess.remainingQuantity -= source.quantity;
            await syncExcessStatus(excess, session);
            await excess.save({ session });

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
            throw new Error('Total quantity from sources does not match quantity taken from shortage');
        }

        // 4. Update shortage
        shortage.remainingQuantity -= quantityTaken;
        await syncShortageStatus(shortage, session);
        await shortage.save({ session });

        // 5. Update transaction record
        transaction.stockShortage.quantityTaken = quantityTaken;
        transaction.stockExcessSources = refinedSources;
        transaction.totalQuantity = newTotalQuantity;
        transaction.totalAmount = newTotalAmount;

        await transaction.save({ session });

        await session.commitTransaction();

        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};
