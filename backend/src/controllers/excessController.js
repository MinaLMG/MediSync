const { StockExcess, HasVolume, StockShortage, Settings, Product } = require('../models');

// Create new excess
exports.createExcess = async (req, res) => {
    try {
        const { 
            product, 
            volume, 
            quantity, 
            expiryDate, 
            selectedPrice, 
            salePercentage, // Using direct salePercentage from request
            shortage_fulfillment // New field
        } = req.body;

        // Check product status
        const productObj = await Product.findById(product);
        if (!productObj || productObj.status !== 'active') {
            return res.status(400).json({
                success: false,
                message: 'This product is currently inactive and cannot be added as an excess.'
            });
        }

        const settings = await Settings.getSettings();
        const minComm = settings.minimumCommission;

        // Validation for real excess
        if (shortage_fulfillment === false) {
            if (salePercentage !== undefined && (salePercentage < 0 || salePercentage > 100)) {
                return res.status(400).json({ 
                    success: false, 
                    message: `Sale percentage must be between 0% and 100%` 
                });
            }
        }

        // Check if a Shortage exists for this product (Constraint)
        const existingShortage = await StockShortage.findOne({
            pharmacy: req.user.pharmacy,
            product,
            status: { $in: ['active', 'partially_fulfilled'] }
        });

        if (existingShortage) {
            return res.status(400).json({ 
                success: false, 
                message: 'You cannot add an excess for this product because you already have an active shortage for it.' 
            });
        }

        // 1. Calculate Dual Sale Info (Percentage & Amount)
        let finalSalePercentage = undefined;
        let finalSaleAmount = undefined;

        if (shortage_fulfillment === false) {
            finalSalePercentage = salePercentage;
            finalSaleAmount = (selectedPrice * salePercentage) / 100;
        } else {
            // Shortage fulfillment usually means no discount from seller, 
            // or we use system default. Per request: "give him the full balance".
            finalSalePercentage = 0;
            finalSaleAmount = 0;
        }

        // 2. Check if Selected Price is New
        const hasVolume = await HasVolume.findOne({ product, volume });
        let isNewPrice = false;
        if (hasVolume) {
            if (!hasVolume.prices.includes(selectedPrice)) {
                isNewPrice = true;
            }
        }

        const excess = await StockExcess.create({
            pharmacy: req.user.pharmacy, 
            product,
            volume,
            originalQuantity: quantity,
            remainingQuantity: quantity,
            expiryDate,
            selectedPrice,
            salePercentage: finalSalePercentage,
            saleAmount: finalSaleAmount,
            shortage_fulfillment: shortage_fulfillment !== false, // default true
            isNewPrice,
            status: 'pending'
        });

        res.status(201).json({ success: true, data: excess });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

// Reject excess (Admin)
exports.rejectExcess = async (req, res) => {
    try {
        const { rejectionReason } = req.body;
        
        if (!rejectionReason) {
            return res.status(400).json({ success: false, message: 'Rejection reason is required' });
        }

        const excess = await StockExcess.findByIdAndUpdate(
            req.params.id,
            { 
                status: 'rejected',
                rejectionReason
            },
            { new: true }
        );
if (!excess) {
            return res.status(404).json({ success: false, message: 'Excess not found' });
        }

        res.status(200).json({ success: true, data: excess });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get pending excesses (Admin)
exports.getPendingExcesses = async (req, res) => {
    try {
        const excesses = await StockExcess.find({ status: 'pending' })
            .populate('pharmacy', 'name address phone')
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get market excesses (Public for pharmacies)
// Get market excesses (Public for pharmacies)
// Aggregated by Product + Volume + Price
exports.getMarketExcesses = async (req, res) => {
    try {
        const mongoose = require('mongoose');
        const { product, volume } = req.query;
        
        let matchStage = {
            remainingQuantity: { $gt: 0 },
            status: { $in: ['available', 'partially_fulfilled'] }
        };

        if (product) matchStage.product = new mongoose.Types.ObjectId(product);
        if (volume) matchStage.volume = new mongoose.Types.ObjectId(volume);
        
        if (req.query.excludeShortageFulfillment === 'true') {
            matchStage.shortage_fulfillment = { $ne: true };
        }

        // Exclude own excesses
        if (req.user.pharmacy) {
            matchStage.pharmacy = { $ne: new mongoose.Types.ObjectId(req.user.pharmacy) };
        }

        const aggregated = await StockExcess.aggregate([
            { $match: matchStage },
            {
                $group: {
                    _id: {
                        product: "$product",
                        volume: "$volume",
                        price: "$selectedPrice"
                    },
                    totalQuantity: { $sum: "$remainingQuantity" },
                    // Keep one doc details (first one) for display names if needed, 
                    // though usually we fetch names separately or use lookups
                    sampleExpiry: { $first: "$expiryDate" } 
                }
            },
            // Lookup product details
            {
                $lookup: {
                    from: "products",
                    localField: "_id.product",
                    foreignField: "_id",
                    as: "productDetails"
                }
            },
            { $unwind: "$productDetails" },
            // Lookup volume details
            {
                $lookup: {
                    from: "volumes",
                    localField: "_id.volume",
                    foreignField: "_id",
                    as: "volumeDetails"
                }
            },
            { $unwind: "$volumeDetails" },
            {
                $project: {
                    _id: 0,
                    product: { 
                        _id: "$_id.product", 
                        name: "$productDetails.name" 
                    },
                    volume: { 
                        _id: "$_id.volume", 
                        name: "$volumeDetails.name" 
                    },
                    price: "$_id.price",
                    totalQuantity: 1
                }
            },
            { $sort: { "product.name": 1, price: 1 } }
        ]);

        res.status(200).json({ success: true, count: aggregated.length, data: aggregated });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get available excesses (Admin)
exports.getAvailableExcesses = async (req, res) => {
    try {
        const excesses = await StockExcess.find({ 
            status: { $in: ['available', 'partially_fulfilled'] } 
        })
            .populate('pharmacy', 'name address phone')
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Approve excess (Admin)
exports.approveExcess = async (req, res) => {
    const mongoose = require('mongoose');
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const excess = await StockExcess.findByIdAndUpdate(
            req.params.id,
            { status: 'available' },
            { new: true, session }
        );

        if (!excess) {
            throw new Error('Excess not found');
        }

        // If it was a new price, add it to the product's HasVolume prices list
        if (excess.isNewPrice) {
            const hasVol = await HasVolume.findOne({ product: excess.product, volume: excess.volume }).session(session);
            if (hasVol) {
                if (!hasVol.prices.includes(excess.selectedPrice)) {
                    hasVol.prices.push(excess.selectedPrice);
                    hasVol.prices.sort((a, b) => a - b);
                    await hasVol.save({ session });
                }
            }
        }

        await session.commitTransaction();
        res.status(200).json({ success: true, data: excess });
    } catch (error) {
        await session.abortTransaction();
        res.status(500).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// Get excesses for a specific pharmacy (Manager)
exports.getMyExcesses = async (req, res) => {
    try {
        const excesses = await StockExcess.find({ pharmacy: req.user.pharmacy })
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Update excess (Manager/Owner)
exports.updateExcess = async (req, res) => {
    try {
        const { quantity, selectedPrice, salePercentage, shortage_fulfillment } = req.body;
        
        // Find existing excess
        const excess = await StockExcess.findById(req.params.id);
        
        if (!excess) {
            return res.status(404).json({ success: false, message: 'Excess not found' });
        }

        // Check ownership (Admins can bypass)
        if (req.user.role !== 'admin' && excess.pharmacy.toString() !== req.user.pharmacy.toString()) {
            return res.status(403).json({ success: false, message: 'Not authorized to update this excess' });
        }

        const status = excess.status;

        // 1. Terminal Statuses: LOCKED (No edits)
        if (['sold', 'expired', 'rejected'].includes(status)) {
            return res.status(400).json({ 
                success: false, 
                message: `Cannot update excess with status ${status}. it is locked.` 
            });
        }

        const taken = excess.originalQuantity - excess.remainingQuantity;

        // 2. Immutability Check (Product, Volume, Expiry)
        const { product, volume, expiryDate } = req.body;
        if (product && product !== excess.product.toString()) {
            return res.status(400).json({ success: false, message: 'Product cannot be modified after creation' });
        }
        if (volume && volume !== excess.volume.toString()) {
            return res.status(400).json({ success: false, message: 'Volume cannot be modified after creation' });
        }
        if (expiryDate && expiryDate !== excess.expiryDate) {
            return res.status(400).json({ success: false, message: 'Expiry date cannot be modified after creation' });
        }

        // 3. Field Locking based on Status/Consumption
        // Categories:
        // - Category A: Reserved, Fulfilled, Partially Fulfilled -> ONLY Sale Info (Percentage/Shortage Fulfillment)
        // - Category B: Available -> Sale Info + Quantity (No Price change if taken > 0)
        // - Category C: Pending -> All (Sale, Quantity, Price)

        if (['reserved', 'fulfilled', 'partially_fulfilled'].includes(status)) {
            // ONLY sale info (but NOT selectedPrice)
            if (selectedPrice !== undefined && selectedPrice !== excess.selectedPrice) {
                return res.status(400).json({ success: false, message: 'Price is locked for this status.' });
            }
            // Allow quantity decrease only
            if (quantity !== undefined) {
                if (quantity > excess.originalQuantity) {
                    return res.status(400).json({ success: false, message: 'Quantity can only be decreased in this status.' });
                }
                if (quantity < taken) {
                    return res.status(400).json({ success: false, message: `Quantity cannot be less than taken (${taken}).` });
                }
            }
        } else if (status === 'available') {
            // Sale Info + Quantity (Decrease only). No price change if theoretically something was taken.
            if (taken > 0 && selectedPrice !== undefined && selectedPrice !== excess.selectedPrice) {
                return res.status(400).json({ success: false, message: 'Price can no longer be modified.' });
            }
            if (quantity !== undefined) {
                if (quantity > excess.originalQuantity) {
                    return res.status(400).json({ success: false, message: 'Quantity can only be decreased.' });
                }
                if (quantity < taken) {
                    return res.status(400).json({ success: false, message: 'Quantity cannot be less than taken.' });
                }
            }
        }

        const settings = await Settings.getSettings();
        const minComm = settings.minimumCommission;

        // Recalculate Sale Info
        let finalSalePercentage = excess.salePercentage;
        let finalSaleAmount = excess.saleAmount;
        let finalShortageFulfillment = shortage_fulfillment !== undefined ? shortage_fulfillment : excess.shortage_fulfillment;

        // If price is changed by non-admin, reset to pending
        if (selectedPrice !== undefined && selectedPrice !== excess.selectedPrice && req.user.role !== 'admin') {
            excess.status = 'pending';
        }

        if (taken === 0) {
            if (finalShortageFulfillment === false) {
                if (salePercentage !== undefined) {
                   if (salePercentage < 0 || salePercentage > 100) {
                       return res.status(400).json({ 
                           success: false, 
                           message: `Sale percentage must be between 0% and 100%` 
                       });
                   }
                   finalSalePercentage = salePercentage;
                   finalSaleAmount = ((selectedPrice || excess.selectedPrice) * salePercentage) / 100;
                }
            } else {
                finalSalePercentage = 0;
                finalSaleAmount = 0;
            }
            excess.selectedPrice = selectedPrice || excess.selectedPrice;
            excess.salePercentage = finalSalePercentage;
            excess.saleAmount = finalSaleAmount;
            excess.shortage_fulfillment = finalShortageFulfillment;
        } else {
            // If taken > 0, we can still update sale info but not price (price locked above)
            if (finalShortageFulfillment === false) {
                if (salePercentage !== undefined) {
                    finalSalePercentage = salePercentage;
                    finalSaleAmount = (excess.selectedPrice * salePercentage) / 100;
                }
            } else {
                finalSalePercentage = 0;
                finalSaleAmount = 0;
            }
            excess.salePercentage = finalSalePercentage;
            excess.saleAmount = finalSaleAmount;
            excess.shortage_fulfillment = finalShortageFulfillment;
        }

        if (quantity !== undefined) {
            excess.originalQuantity = quantity;
            excess.remainingQuantity = quantity - taken;
        }

        // Sync status based on new quantities and related transactions
        await exports.syncExcessStatus(excess);

        await excess.save();

        res.status(200).json({ success: true, data: excess });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Delete excess (Admin/Owner/Manager)
exports.deleteExcess = async (req, res) => {
    try {
        const excess = await StockExcess.findById(req.params.id);

        if (!excess) {
            return res.status(404).json({ success: false, message: 'Excess not found' });
        }

        // Check if user is owner/manager of this pharmacy OR admin
        if (req.user.role !== 'admin' && excess.pharmacy.toString() !== req.user.pharmacy.toString()) {
             return res.status(403).json({ success: false, message: 'Not authorized to delete this excess' });
        }

        // Constraints: No deletion if taken > 0 or terminal/active statuses beyond pending/available
        const taken = excess.originalQuantity - excess.remainingQuantity;
        if (taken > 0) {
            return res.status(400).json({ success: false, message: 'Cannot delete excess with taken stock.' });
        }

        if (!['pending', 'available', 'rejected'].includes(excess.status)) {
            return res.status(400).json({ success: false, message: `Cannot delete excess in ${excess.status} state.` });
        }

        await excess.deleteOne();

        res.status(200).json({ success: true, message: 'Excess deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Helper to sync excess status based on transactions and quantity
exports.syncExcessStatus = async (excess, session = null) => {
    const { Transaction } = require('../models');
    const mongoose = require('mongoose');
    const TransactionModel = mongoose.model('Transaction');
    
    // Find transactions involving this excess
    const query = TransactionModel.find({ 'stockExcessSources.stockExcess': excess._id });
    if (session) {
        query.session(session);
    }
    const transactions = await query;
    
    // Status counts
    const hasActive = transactions.some(t => ['pending', 'accepted'].includes(t.status));
    const hasCompleted = transactions.some(t => t.status === 'completed');

    // Logic based on remaining quantity
    if (excess.remainingQuantity > 0) {
        if (hasActive || hasCompleted) {
            excess.status = 'partially_fulfilled';
        } else if (excess.status !== 'pending' && excess.status !== 'rejected') {
            excess.status = 'available';
        }
    } else {
        // remainingQuantity == 0
        if (hasActive) {
            if (hasCompleted) {
                excess.status = 'fulfilled'; 
            } else {
                excess.status = 'reserved'; 
            }
        } else if (hasCompleted) {
            excess.status = 'sold';
        } else {
            excess.status = 'fulfilled';
        }
    }
};
