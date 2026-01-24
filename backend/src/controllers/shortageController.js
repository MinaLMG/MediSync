const { StockShortage, StockExcess } = require('../models');

// Create new shortage
exports.createShortage = async (req, res) => {
    try {
        const { product, volume, quantity, notes } = req.body;

        // Check if an Excess exists for this product (Constraint)
        const existingExcess = await StockExcess.findOne({
            pharmacy: req.user.pharmacy,
            product,
            status: { $in: ['pending', 'available'] }
        });

        if (existingExcess) {
            return res.status(400).json({ 
                success: false, 
                message: 'You cannot add a shortage for this product because you already have an excess for it.' 
            });
        }

        const shortage = await StockShortage.create({
            pharmacy: req.user.pharmacy,
            product,
            volume,
            quantity,
            remainingQuantity: quantity,
            notes,
            status: 'active'
        });

        res.status(201).json({ success: true, data: shortage });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

// Get active shortages (Admin)
exports.getActiveShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ remainingQuantity: { $gt: 0 } })
            .populate('pharmacy', 'name')
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: shortages });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get shortages for a specific pharmacy (Manager)
exports.getMyShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ pharmacy: req.user.pharmacy })
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: shortages });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Update shortage (Manager/Owner)
exports.updateShortage = async (req, res) => {
    try {
        const { quantity, notes } = req.body;

        const shortage = await StockShortage.findById(req.params.id);

        if (!shortage) {
            return res.status(404).json({ success: false, message: 'Shortage not found' });
        }

        if (shortage.pharmacy.toString() !== req.user.pharmacy.toString()) {
            return res.status(403).json({ success: false, message: 'Not authorized to update this shortage' });
        }

        if (shortage.status !== 'active') {
             return res.status(400).json({ success: false, message: 'Cannot update non-active shortage' });
        }

        const qtyDiff = (quantity || shortage.quantity) - shortage.quantity;
        shortage.quantity = quantity || shortage.quantity;
        shortage.remainingQuantity += qtyDiff;
        shortage.notes = notes || shortage.notes;

        await shortage.save();

        res.status(200).json({ success: true, data: shortage });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Delete shortage (Admin/Owner/Manager)
exports.deleteShortage = async (req, res) => {
    try {
        const shortage = await StockShortage.findById(req.params.id);

        if (!shortage) {
            return res.status(404).json({ success: false, message: 'Shortage not found' });
        }

        if (req.user.role !== 'admin' && shortage.pharmacy.toString() !== req.user.pharmacy.toString()) {
             return res.status(403).json({ success: false, message: 'Not authorized to delete this shortage' });
        }

        await shortage.deleteOne();

        res.status(200).json({ success: true, message: 'Shortage deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get all unique product names with active shortages system-wide (For News Marquee)
// @route   GET /api/shortage/global-active
// @access  Private (Managers/Admin)
exports.getGlobalActiveShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ remainingQuantity: { $gt: 0 } })
            .select('product')
            .populate('product', 'name');

        // Extract unique names
        const productNames = [...new Set(shortages.map(s => s.product?.name).filter(Boolean))];
        console.log("shortage productnames:",productNames)
        res.status(200).json({ success: true, count: productNames.length, data: productNames });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};


// End of file
