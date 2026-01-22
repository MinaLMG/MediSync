const { StockExcess, HasVolume } = require('../models');

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
            await HasVolume.findOneAndUpdate(
                { product: excess.product, volume: excess.volume },
                { $addToSet: { prices: excess.selectedPrice } }
            );
        }

        res.status(200).json({ success: true, data: excess });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Delete excess (Admin/Owner)
exports.deleteExcess = async (req, res) => {
    try {
        const excess = await StockExcess.findByIdAndDelete(req.params.id);

        if (!excess) {
            return res.status(404).json({ success: false, message: 'Excess not found' });
        }

        res.status(200).json({ success: true, message: 'Excess deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
