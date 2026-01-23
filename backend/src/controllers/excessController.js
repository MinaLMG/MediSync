const { StockExcess, HasVolume, StockShortage } = require('../models');

// Create new excess
exports.createExcess = async (req, res) => {
    try {
        const { 
            product, 
            volume, 
            quantity, 
            expiryDate, 
            selectedPrice, 
            saleType, 
            saleValue 
        } = req.body;

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

        if (saleType && saleValue) {
            if (saleType === 'percentage') {
                finalSalePercentage = saleValue;
                finalSaleAmount = (selectedPrice * saleValue) / 100;
            } else if (saleType === 'flat') {
                finalSaleAmount = saleValue;
                finalSalePercentage = (saleValue / selectedPrice) * 100;
            }
        }

        // 2. Check if Selected Price is New
        // Fetch HasVolume to see strict prices list
        const hasVolume = await HasVolume.findOne({ product, volume });
        let isNewPrice = false;
        if (hasVolume) {
            // Check if selectedPrice exists in the prices array
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
            isNewPrice, // Save trigger
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
        const { quantity, selectedPrice, saleType, saleValue } = req.body;
        
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

        // Recalculate Sale Info
        let finalSalePercentage = excess.salePercentage;
        let finalSaleAmount = excess.saleAmount;

        if (saleType && saleValue) {
            if (saleType === 'percentage') {
                finalSalePercentage = saleValue;
                finalSaleAmount = (selectedPrice * saleValue) / 100;
            } else if (saleType === 'flat') {
                finalSaleAmount = saleValue;
                finalSalePercentage = (saleValue / selectedPrice) * 100;
            }
        }

        // Update fields
        excess.originalQuantity = quantity || excess.originalQuantity;
        excess.remainingQuantity = quantity || excess.remainingQuantity; // Reset remaining if qty changes? Simplify to sync
        excess.selectedPrice = selectedPrice || excess.selectedPrice;
        excess.salePercentage = finalSalePercentage;
        excess.saleAmount = finalSaleAmount;

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
