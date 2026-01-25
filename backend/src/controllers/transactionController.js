const { Transaction, StockShortage, StockExcess, Pharmacy, Settings, User } = require('../models');
const mongoose = require('mongoose');
const { addNotificationJob } = require('../utils/queueManager');

// @desc    Get products that have both active shortages and available excesses
// @route   GET /api/transaction/matchable
// @access  Admin
exports.getMatchableProducts = async (req, res) => {
    try {
        // Find products with active shortages
        const shortages = await StockShortage.aggregate([
            { $match: { remainingQuantity: { $gt: 0 } } },
            { $group: { _id: "$product", volumes: { $addToSet: "$volume" } } }
        ]);

        // Find products with available excesses
        const excesses = await StockExcess.aggregate([
            { $match: { status: 'available', remainingQuantity: { $gt: 0 } } },
            { $group: { 
                _id: "$product", 
                volumes: { $addToSet: "$volume" },
                hasShortageFulfillment: { $max: "$shortage_fulfillment" }
            } }
        ]);

        // Filter products that appear in both lists with matching volumes
        const matchable = [];
        for (const s of shortages) {
            const e = excesses.find(ex => ex._id.toString() === s._id.toString());
            if (e) {
                // Check if they share at least one volume
                const commonVolumes = s.volumes.filter(sv => 
                    e.volumes.some(ev => ev.toString() === sv.toString())
                );
                
                if (commonVolumes.length > 0) {
                    // Get product details
                    const product = await mongoose.model('Product').findById(s._id);
                    // CHECK: Product must be active
                    if (product && product.status === 'active') {
                        matchable.push({
                            product,
                            volumes: commonVolumes,
                            hasShortageFulfillment: e.hasShortageFulfillment || false
                        });
                    }
                }
            }
        }

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
            remainingQuantity: { $gt: 0 }
        }).populate('pharmacy', 'name').populate('volume', 'name');

        const excesses = await StockExcess.find({
            product: productId,
            status: 'available',
            remainingQuantity: { $gt: 0 }
        }).populate('pharmacy', 'name').populate('volume', 'name');

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
        const { shortageId, quantityTaken, excessSources } = req.body;

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
            if (!excess || excess.status !== 'available' || excess.remainingQuantity < source.quantity) {
                throw new Error(`Excess ${source.stockExcessId} is no longer available in requested quantity`);
            }

            // Deduct from excess
            excess.remainingQuantity -= source.quantity;
            if (excess.remainingQuantity === 0) {
                excess.status = 'sold';
            }
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
        shortage.status = shortage.remainingQuantity === 0 ? 'fulfilled' : 'partially_fulfilled';
        await shortage.save({ session });

        // 4. Generate Serial
        const date = new Date();
        const yyyy = date.getFullYear();
        const mm = String(date.getMonth() + 1).padStart(2, '0');
        const dd = String(date.getDate()).padStart(2, '0');
        const datePrefix = `${yyyy}${mm}${dd}`;

        // Find latest transaction with this date prefix
        // We need to query OUTSIDE the session if we haven't locked the collection, 
        // to avoid phantom reads if strict isolation level. 
        // But for simplicity and since we are in a transaction, let's use the session.
        // If high concurrency is expected, a separate counter collection is better.
        // For now, sorting by serial desc is sufficient.
        const lastTx = await Transaction.findOne({ serial: { $regex: `^${datePrefix}-` } })
            .sort({ serial: -1 })
            .session(session);

        let sequence = 101; // Start at 0101
        if (lastTx && lastTx.serial) {
            const parts = lastTx.serial.split('-');
            if (parts.length === 2) {
                const lastSeq = parseInt(parts[1], 10);
                if (!isNaN(lastSeq)) {
                    sequence = lastSeq + 1;
                }
            }
        }
        const serial = `${datePrefix}-${String(sequence).padStart(4, '0')}`;

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
            commissionRatio: settings.minimumCommission / 100 // Snapshot
        });

        await transaction.save({ session });

        await session.commitTransaction();

        // Notify Buyer about transaction creation
        try {
            const product = await mongoose.model('Product').findById(shortage.product);
            const buyerPharmacy = await Pharmacy.findById(shortage.pharmacy);
            const buyerUsers = await User.find({ pharmacy: shortage.pharmacy });
            
            for (const buyer of buyerUsers) {
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
            for (const source of transaction.stockExcessSources) {
                const excess = await StockExcess.findById(source.stockExcess).populate('pharmacy');
                if (excess) {
                    const sellerUsers = await User.find({ pharmacy: excess.pharmacy._id });
                    for (const seller of sellerUsers) {
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
        } catch (notifErr) {
            console.error('Notification error in createTransaction:', notifErr);
        }

        res.status(201).json({ success: true, data: transaction });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
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
                    if (excess.status === 'sold' || excess.status === 'reserved') {
                        excess.status = 'available';
                    }
                    await excess.save({ session });
                }
            }

            // 2. Reduce shortage fulfillment
            const shortage = await StockShortage.findById(transaction.stockShortage.shortage).session(session);
            if (shortage) {
                shortage.remainingQuantity += transaction.stockShortage.quantityTaken;
                
                if (shortage.remainingQuantity >= shortage.quantity) {
                    shortage.status = 'active';
                } else {
                    shortage.status = 'partially_fulfilled';
                }
                await shortage.save({ session });
            }
        } else if (status === 'completed') {
            // Financial logic: Balance Transfer
            const settings = await Settings.getSettings();
            const minCommRatio = settings.minimumCommission / 100;
            const shortageCommRatio = settings.shortageCommission / 100;
            
            transaction.commissionRatio = minCommRatio; // Update snapshot to actual at completion if needed, or keep original

            // Buyer: Deduct (100 + shortageCommission)%
            const shortage = await StockShortage.findById(transaction.stockShortage.shortage).session(session);
            const buyerPh = await Pharmacy.findById(shortage.pharmacy).session(session);
            if (buyerPh) {
                const buyerEffect = -(1 + shortageCommRatio) * transaction.totalAmount;
                buyerPh.balance += buyerEffect; // += because buyerEffect is negative
                transaction.stockShortage.balanceEffect = buyerEffect;
                await buyerPh.save({ session });

                // Emit balance update to buyer's users
                try {
                    const { sendToUser } = require('../utils/socketManager');
                    const buyerUsers = await mongoose.model('User').find({ pharmacy: buyerPh._id });
                    for (const user of buyerUsers) {
                        sendToUser(user._id.toString(), 'balanceUpdate', {
                            balance: buyerPh.balance
                        });
                    }
                } catch (err) {
                    console.error('Error emitting balance update to buyer:', err);
                }
            }

            // Sellers: Add full balance if shortage_fulfillment, else (100 - minComm)%
            for (let i = 0; i < transaction.stockExcessSources.length; i++) {
                const source = transaction.stockExcessSources[i];
                const excess = await StockExcess.findById(source.stockExcess).session(session);
                const sellerPh = await Pharmacy.findById(excess.pharmacy).session(session);
                if (sellerPh) {
                    let sellerEffect = 0;
                    if (transaction.shortage_fulfillment) {
                        sellerEffect = source.totalAmount;
                    } else {
                        const excessComm = excess.salePercentage;
                        const finalCommRatio = (excessComm !== undefined && excessComm !== null) 
                            ? (excessComm / 100) 
                            : minCommRatio;
                        
                        sellerEffect = (1 - finalCommRatio) * source.totalAmount;
                    }
                    
                    sellerPh.balance += sellerEffect;
                    transaction.stockExcessSources[i].balanceEffect = sellerEffect;
                    
                    await sellerPh.save({ session });

                    // Emit balance update to seller's users
                    try {
                        const { sendToUser } = require('../utils/socketManager');
                        const sellerUsers = await mongoose.model('User').find({ pharmacy: sellerPh._id });
                        for (const user of sellerUsers) {
                            sendToUser(user._id.toString(), 'balanceUpdate', {
                                balance: sellerPh.balance
                            });
                        }
                    } catch (err) {
                        console.error('Error emitting balance update to seller:', err);
                    }
                }
            }
            // Check if shortage is fully done
            const shortageObj = await StockShortage.findById(transaction.stockShortage.shortage).session(session);
            if (shortageObj) {
                shortageObj.status = shortageObj.remainingQuantity === 0 ? 'fulfilled' : 'partially_fulfilled';
                await shortageObj.save({ session });
            }
        }

        await transaction.save({ session });
        await session.commitTransaction();

        // Notify relevant parties about status change
        try {
            const shortageData = await StockShortage.findById(transaction.stockShortage.shortage);
            if (shortageData) {
                const product = await mongoose.model('Product').findById(shortageData.product);
                
                // 1. Notify Buyer
                const buyerUsers = await User.find({ pharmacy: shortageData.pharmacy });
                for (const buyer of buyerUsers) {
                    await addNotificationJob(
                        buyer._id.toString(),
                        'transaction',
                        `Transaction for "${product?.name || 'medicine'}" has been ${status}.`,
                        {
                            relatedEntity: transaction._id,
                            relatedEntityType: 'Transaction'
                        }
                    );
                }

                // 2. Notify Sellers
                for (const source of transaction.stockExcessSources) {
                    const excess = await StockExcess.findById(source.stockExcess);
                    if (excess) {
                        const sellerUsers = await User.find({ pharmacy: excess.pharmacy });
                        for (const seller of sellerUsers) {
                            await addNotificationJob(
                                seller._id.toString(),
                                'transaction',
                                `Your transaction for "${product?.name || 'medicine'}" has been ${status}.`,
                                {
                                    relatedEntity: transaction._id,
                                    relatedEntityType: 'Transaction'
                                }
                            );
                        }
                    }
                }
                // 3. Notify Delivery User (if assigned)
                if (transaction.delivery) {
                    await addNotificationJob(
                        transaction.delivery.toString(),
                        'transaction',
                        `Transaction #${transaction._id.toString().slice(-6)} has been ${status}.`,
                        {
                            relatedEntity: transaction._id,
                            relatedEntityType: 'Transaction'
                        }
                    );
                }
            }
        } catch (notifErr) {
            console.error('Notification error in updateTransactionStatus:', notifErr);
        }

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
                    { path: 'volume', select: 'name' }
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
                    { path: 'volume', select: 'name' }
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
                    { path: 'punishments.user', select: 'name' },
                    { path: 'punishments.pharmacy', select: 'name' }
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

// @desc    Revert a completed transaction (restores stock, automatic balance reversal + punishments)
// @route   POST /api/transaction/:id/revert
// @access  Admin
exports.revertTransaction = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { id } = req.params;
        const { punishments, description } = req.body; // Array of { userId, amount }

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

        // Validate punishments
        if (punishments && punishments.length > 0) {
            for (const p of punishments) {
                if (p.amount < 0) {
                    throw new Error('Punishment amount cannot be negative');
                }
            }
        }

        // 1. Restore Stock Quantities
        for (const source of transaction.stockExcessSources) {
            const excess = await StockExcess.findById(source.stockExcess._id).session(session);
            if (excess) {
                excess.remainingQuantity += source.quantity;
                if (excess.status === 'sold') excess.status = 'available';
                await excess.save({ session });
            }
        }

        const shortage = await StockShortage.findById(transaction.stockShortage.shortage._id).session(session);
        if (shortage) {
            shortage.remainingQuantity += transaction.stockShortage.quantityTaken;
            shortage.status = shortage.remainingQuantity >= shortage.quantity ? 'active' : 'partially_fulfilled';
            await shortage.save({ session });
        }

        // 2. Financial Reversal (Automatic)
        const { sendToUser } = require('../utils/socketManager');

        // Revert Buyer
        const buyerPh = await Pharmacy.findById(transaction.stockShortage.shortage.pharmacy._id).session(session);
        if (buyerPh && transaction.stockShortage.balanceEffect) {
            buyerPh.balance -= transaction.stockShortage.balanceEffect; // Subtract the effect (which was negative)
            await buyerPh.save({ session });
            
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
                sellerPh.balance -= source.balanceEffect; // Subtract the profit given
                await sellerPh.save({ session });

                // Notify seller users
                const users = await User.find({ pharmacy: sellerPh._id });
                for (const user of users) {
                    sendToUser(user._id.toString(), 'balanceUpdate', { balance: sellerPh.balance });
                }
            }
        }

        // 3. Apply Punishments
        if (punishments && punishments.length > 0) {
            for (const p of punishments) {
                let pharmacy = null;
                let targetUser = null;

                // Try to find as User first
                const user = await User.findById(p.userId).populate('pharmacy').session(session);
                if (user && user.pharmacy) {
                    pharmacy = await Pharmacy.findById(user.pharmacy._id).session(session);
                    targetUser = user._id;
                } else {
                    // Try to find as Pharmacy if not a User
                    const pharm = await Pharmacy.findById(p.userId).session(session);
                    if (pharm) {
                        pharmacy = pharm;
                        // For the ticket, we might still want a user reference. 
                        // If we only have pharmacy, we can try to find an admin user.
                        const adminUser = await User.findOne({ pharmacy: pharm._id, role: 'admin' }).session(session);
                        if (adminUser) targetUser = adminUser._id;
                    }
                }

                if (pharmacy) {
                    pharmacy.balance -= p.amount; // Punishment is deducted
                    await pharmacy.save({ session });
                    
                    // Notify any users of this pharmacy
                    const pharmUsers = await User.find({ pharmacy: pharmacy._id });
                    for (const u of pharmUsers) {
                        sendToUser(u._id.toString(), 'balanceUpdate', { balance: pharmacy.balance });
                    }

                    // Store resolved references for the ticket
                    p.resolvedUserId = targetUser;
                    p.resolvedPharmacyId = pharmacy._id;
                }
            }
        }

        // 4. Create Reversal Ticket
        const ticket = new ReversalTicket({
            transaction: transaction._id,
            punishments: punishments ? punishments
                .filter(p => p.resolvedPharmacyId) // Ensure we have at least a pharmacy to record
                .map(p => ({
                    user: p.resolvedUserId, // May be null if only pharmacy was resolved
                    pharmacy: p.resolvedPharmacyId,
                    amount: p.amount
                })) : [],
            description: description || 'Automatic reversal of original transaction'
                
        });
        await ticket.save({ session });

        // 5. Update Transaction
        transaction.reversalTicket = ticket._id;
        transaction.status = 'cancelled';
        await transaction.save({ session });

        await session.commitTransaction();
        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        if (session.inTransaction()) await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// @desc    Update a reversal ticket (adjusts punishments and balances)
// @route   PUT /api/transaction/reversal/:ticketId
// @access  Admin
exports.updateReversalTicket = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { ticketId } = req.params;
        const { punishments, description } = req.body; // New punishment list

        if (punishments && punishments.some(p => p.amount < 0)) {
            throw new Error('Punishment amount cannot be negative');
        }

        const { ReversalTicket, Pharmacy, User } = require('../models');
        const { sendToUser } = require('../utils/socketManager');

        const ticket = await ReversalTicket.findById(ticketId).session(session);
        if (!ticket) throw new Error('Reversal ticket not found');

        // 1. Revert Old Punishments (Refund the amounts taken)
        for (const oldP of ticket.punishments) {
            if (oldP.pharmacy) {
                const pharmacy = await Pharmacy.findById(oldP.pharmacy).session(session);
                if (pharmacy) {
                    pharmacy.balance += oldP.amount; // Add back the deducted amount
                    await pharmacy.save({ session });
                    
                    // Notify users
                    const users = await User.find({ pharmacy: pharmacy._id });
                    for (const u of users) {
                        sendToUser(u._id.toString(), 'balanceUpdate', { balance: pharmacy.balance });
                    }
                }
            }
        }

        // 2. Apply New Punishments
        const resolvedPunishments = [];
        if (punishments && punishments.length > 0) {
            for (const p of punishments) {
                let pharmacy = null;
                let targetUser = null;

                // Resolve User/Pharmacy (same logic as create)
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
                    pharmacy.balance -= p.amount; // Deduct new amount
                    await pharmacy.save({ session });

                    const users = await User.find({ pharmacy: pharmacy._id });
                    for (const u of users) {
                        sendToUser(u._id.toString(), 'balanceUpdate', { balance: pharmacy.balance });
                    }

                    resolvedPunishments.push({
                        user: targetUser,
                        pharmacy: pharmacy._id,
                        amount: p.amount
                    });
                }
            }
        }

        // 3. Update Ticket
        ticket.punishments = resolvedPunishments;
        if (description) ticket.description = description;
        await ticket.save({ session });

        await session.commitTransaction();
        res.status(200).json({ success: true, data: ticket });
    } catch (error) {
        if (session.inTransaction()) await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};
