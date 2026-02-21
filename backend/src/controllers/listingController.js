const { StockExcess, StockShortage } = require('../models');

// Get combined listings (Excess + Shortage) for the logged-in user
// Sorted by most recent first
exports.getMyListings = async (req, res) => {
    try {
        // 1. Fetch Requesting User's Excesses
        const excesses = await StockExcess.find({ pharmacy: req.user.pharmacy })
            .populate('product', 'name')
            .populate('volume', 'name')
            .lean(); // Convert to plain JS objects

        // Add 'type' field to distinguish
        const formattedExcesses = excesses.map(item => ({
            ...item,
            type: 'excess',
            displayStatus: item.status
        }));

        // 2. Fetch Requesting User's Shortages
        const shortages = await StockShortage.find({ pharmacy: req.user.pharmacy })
            .populate('product', 'name')
            .populate('volume', 'name')
            .lean();

        const formattedShortages = shortages.map(item => ({
            ...item,
            type: 'shortage',
            displayStatus: item.status
        }));

        // 3. Combine and Sort
        const allListings = [...formattedExcesses, ...formattedShortages];

        // Sort by createdAt descending (most recent first)
        allListings.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

        res.status(200).json({ success: true, data: allListings });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};
