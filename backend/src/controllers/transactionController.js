const { Transaction, StockShortage, StockExcess, Pharmacy } = require('../models');
const mongoose = require('mongoose');

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
            { $group: { _id: "$product", volumes: { $addToSet: "$volume" } } }
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
                    if (product) {
                        matchable.push({
                            product,
                            volumes: commonVolumes
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
        const transaction = new Transaction({
            stockShortage: {
                shortage: shortageId,
                quantityTaken
            },
            stockExcessSources: refinedSources,
            totalQuantity,
            totalAmount,
            status: 'pending'
        });

        await transaction.save({ session });

        await session.commitTransaction();
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
            // 1% Commission margin
            const commissionRatio = 0.01;
            transaction.commissionRatio = commissionRatio;

            // Buyer: Deduct 101%
            const shortage = await StockShortage.findById(transaction.stockShortage.shortage).session(session);
            const buyerPh = await Pharmacy.findById(shortage.pharmacy).session(session);
            if (buyerPh) {
                // current balance - (100+margin)/100 * transaction
                buyerPh.balance -= (1 + commissionRatio) * transaction.totalAmount;
                await buyerPh.save({ session });
            }

            // Sellers: Add 99%
            for (const source of transaction.stockExcessSources) {
                const excess = await StockExcess.findById(source.stockExcess).session(session);
                const sellerPh = await Pharmacy.findById(excess.pharmacy).session(session);
                if (sellerPh) {
                    // current balance + (100-margin)/100 * source_amount
                    sellerPh.balance += (1 - commissionRatio) * source.totalAmount;
                    await sellerPh.save({ session });
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
        res.status(200).json({ success: true, data: transaction });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// @desc    Get all transactions (with filters for status)
// @route   GET /api/transaction
// @access  Admin
exports.getTransactions = async (req, res) => {
    try {
        const { status } = req.query;
        const query = status ? { status } : {};

        const transactions = await Transaction.find(query)
            .populate({
                path: 'stockShortage.shortage',
                populate: [
                    { path: 'pharmacy', select: 'name' },
                    { path: 'product', select: 'name' },
                    { path: 'volume', select: 'name' }
                ]
            })
            .populate({
                path: 'stockExcessSources.stockExcess',
                populate: [
                    { path: 'pharmacy', select: 'name' }
                ]
            })
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, count: transactions.length, data: transactions });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
