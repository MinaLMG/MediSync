const { StockShortage } = require('../models');

// Create new shortage
exports.createShortage = async (req, res) => {
    try {
        const { product, volume, quantity, maxSurplus, notes } = req.body;

        const shortage = await StockShortage.create({
            pharmacy: req.user.pharmacy, // From authMiddleware
            product,
            volume,
            quantity,
            maxSurplus: maxSurplus || undefined,
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
        const shortages = await StockShortage.find({ status: 'active' })
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

// Delete shortage (Admin/Owner)
exports.deleteShortage = async (req, res) => {
    try {
        const shortage = await StockShortage.findByIdAndDelete(req.params.id);

        if (!shortage) {
            return res.status(404).json({ success: false, message: 'Shortage not found' });
        }

        res.status(200).json({ success: true, message: 'Shortage deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
