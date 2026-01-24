const { StockExcess, HasVolume, StockShortage, Settings } = require('../models');

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
            status: 'active'
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

// Get pending excesses (Admin)
exports.getPendingExcesses = async (req, res) => {
    try {
        const excesses = await StockExcess.find({ status: 'pending' })
            .populate('pharmacy', 'name')
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get available excesses (Admin)
exports.getAvailableExcesses = async (req, res) => {
    try {
        const excesses = await StockExcess.find({ status: 'available' })
            .populate('pharmacy', 'name')
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
    try {
        const excess = await StockExcess.findByIdAndUpdate(
            req.params.id,
            { status: 'available' },
            { new: true }
        );

        if (!excess) {
            return res.status(404).json({ success: false, message: 'Excess not found' });
        }

        // If it was a new price, add it to the product's HasVolume prices list
        if (excess.isNewPrice) {
            const hasVol = await HasVolume.findOne({ product: excess.product, volume: excess.volume });
            if (hasVol) {
                if (!hasVol.prices.includes(excess.selectedPrice)) {
                    hasVol.prices.push(excess.selectedPrice);
                    hasVol.prices.sort((a, b) => a - b);
                    await hasVol.save();
                }
            }
        }

        res.status(200).json({ success: true, data: excess });
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

        // Check ownership
        if (excess.pharmacy.toString() !== req.user.pharmacy.toString()) {
            return res.status(403).json({ success: false, message: 'Not authorized to update this excess' });
        }

        // Only allow update if pending or available
        if (excess.status !== 'pending' && excess.status !== 'available') {
            return res.status(400).json({ success: false, message: 'Cannot update excess that is not pending or available' });
        }

        const settings = await Settings.getSettings();
        const minComm = settings.minimumCommission;

        // Recalculate Sale Info
        let finalSalePercentage = excess.salePercentage;
        let finalSaleAmount = excess.saleAmount;
        let finalShortageFulfillment = shortage_fulfillment !== undefined ? shortage_fulfillment : excess.shortage_fulfillment;

        if (finalShortageFulfillment === false) {
             if (salePercentage !== undefined) {
                if (salePercentage < minComm || salePercentage > 100) {
                    return res.status(400).json({ 
                        success: false, 
                        message: `For real excess, sale percentage must be between ${minComm}% and 100%` 
                    });
                }
                finalSalePercentage = salePercentage;
                finalSaleAmount = ((selectedPrice || excess.selectedPrice) * salePercentage) / 100;
             }
        } else {
            finalSalePercentage = 0;
            finalSaleAmount = 0;
        }

        // Update fields
        excess.originalQuantity = quantity || excess.originalQuantity;
        excess.remainingQuantity = quantity || excess.remainingQuantity; 
        excess.selectedPrice = selectedPrice || excess.selectedPrice;
        excess.salePercentage = finalSalePercentage;
        excess.saleAmount = finalSaleAmount;
        excess.shortage_fulfillment = finalShortageFulfillment;

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
        // Note: req.user.pharmacy is ID for manager/owner. Admin usually doesn't have it set or has special role.
        if (req.user.role !== 'admin' && excess.pharmacy.toString() !== req.user.pharmacy.toString()) {
             return res.status(403).json({ success: false, message: 'Not authorized to delete this excess' });
        }

        await excess.deleteOne();

        res.status(200).json({ success: true, message: 'Excess deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
