const { StockExcess, StockShortage } = require('../models');

// Get combined requests history (Excess + Shortage) for the logged-in user
// Sorted by most recent first
exports.getMyRequestsHistory = async (req, res) => {
    try {
        // 1. Fetch Requesting User's Excesses
        const excesses = await StockExcess.find({ pharmacy: req.user.pharmacy })
            .populate('product', 'name')
            .populate('volume', 'name')
            .lean(); // Convert to plain JS objects

        // Add 'type' field and calculate sale info
        const formattedExcesses = excesses.map(item => {
            const salePercent = item.salePercentage || 0;
            const price = item.selectedPrice || 0;
            const saleAmount = price * (salePercent / 100);
            return {
                ...item,
                type: 'excess',
                displayStatus: item.status,
                saleAmount
            };
        });

        // 2. Fetch Requesting User's Shortages
        const shortages = await StockShortage.find({ pharmacy: req.user.pharmacy })
            .populate('product', 'name')
            .populate('volume', 'name')
            .lean();

        const formattedShortages = shortages.map(item => {
            const salePercent = item.salePercentage || 0;
            const price = item.targetPrice || 0;
            const saleAmount = price * (salePercent / 100);
            return {
                ...item,
                type: 'shortage',
                itemCategory: item.type, // Preserve original type (request/market_order)
                displayStatus: item.status,
                saleAmount
            };
        });

        // 3. Combine and Sort
        const allRequests = [...formattedExcesses, ...formattedShortages];

        // Sort by createdAt descending (most recent first)
        allRequests.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

        res.status(200).json({ success: true, data: allRequests });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};
