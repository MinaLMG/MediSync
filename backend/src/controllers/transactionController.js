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

        // 4. Create transaction
        const settings = await Settings.getSettings();
        const transaction = new Transaction({
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
                    `A new transaction has been created for your shortage of "${product?.name || 'unknown medicine'}".`,
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
                            `New transaction request for "${product?.name || 'unknown medicine'}" from ${buyerPharmacy?.name || 'a pharmacy'}.`,
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
                // current balance - (100+shortage_commision)/100 * transaction
                buyerPh.balance -= (1 + shortageCommRatio) * transaction.totalAmount;
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
            for (const source of transaction.stockExcessSources) {
                const excess = await StockExcess.findById(source.stockExcess).session(session);
                const sellerPh = await Pharmacy.findById(excess.pharmacy).session(session);
                if (sellerPh) {
                    if (transaction.shortage_fulfillment) {
                        // Full balance
                        sellerPh.balance += source.totalAmount;
                  
                    } else {
                        // Use excess-specific sale percentage if it exists, otherwise use system minimum
                        const excessComm = excess.salePercentage;
                        const finalCommRatio = (excessComm !== undefined && excessComm !== null) 
                            ? (excessComm / 100) 
                            : minCommRatio;
                        
                        sellerPh.balance += (1 - finalCommRatio) * source.totalAmount;
                     }
                    
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
