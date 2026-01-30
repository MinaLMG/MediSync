const { StockExcess, StockShortage } = require('../models');

// Get combined orders history (Excess + Shortage) for the logged-in user
// Sorted by most recent first
exports.getMyOrders = async (req, res) => {
    try {
        console.log(1)
        // 1. Fetch Requesting User's Excesses
        // We want all statuses presumably, or maybe just active ones? 
        // User asked for "all stockexcesses and stock shortages".
        const excesses = await StockExcess.find({ pharmacy: req.user.pharmacy })
            .populate('product', 'name')
            .populate('volume', 'name')
            .lean(); // Convert to plain JS objects

        // Add 'type' field to distinguish
        const formattedExcesses = excesses.map(item => ({
            ...item,
            type: 'excess',
            displayStatus: item.status // 'pending', 'available', etc.
        }));

        // 2. Fetch Requesting User's Shortages
        const shortages = await StockShortage.find({ pharmacy: req.user.pharmacy })
            .populate('product', 'name')
            .populate('volume', 'name')
            .lean();

        const formattedShortages = shortages.map(item => ({
            ...item,
            type: 'shortage',
            displayStatus: item.status // 'active', 'fulfilled', etc.
        }));

        // 3. Combine and Sort
        const allOrders = [...formattedExcesses, ...formattedShortages];

        // Sort by createdAt descending (most recent first)
        allOrders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

        res.status(200).json({ success: true, data: allOrders });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
// Get pharmacy orders history for admin
// @route   GET /api/orders/pharmacy/:pharmacyId
// @access  Admin
exports.getPharmacyOrders = async (req, res) => {
    try {
        const { pharmacyId } = req.params;
        
        const excesses = await StockExcess.find({ pharmacy: pharmacyId })
            .populate('product', 'name')
            .populate('volume', 'name')
            .lean();

        const formattedExcesses = excesses.map(item => ({
            ...item,
            type: 'excess',
            displayStatus: item.status
        }));

        const shortages = await StockShortage.find({ pharmacy: pharmacyId })
            .populate('product', 'name')
            .populate('volume', 'name')
            .lean();

        const formattedShortages = shortages.map(item => ({
            ...item,
            type: 'shortage',
            displayStatus: item.status
        }));

        const allOrders = [...formattedExcesses, ...formattedShortages];
        allOrders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

        res.status(200).json({ success: true, data: allOrders });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
