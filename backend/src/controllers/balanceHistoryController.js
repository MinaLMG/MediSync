const { BalanceHistory } = require('../models');

// @desc    Get pharmacy balance history
// @route   GET /api/balance-history
// @access  Private (Pharmacy owner)
exports.getMyBalanceHistory = async (req, res) => {
    try {
        if (!req.user.pharmacy) {
            return res.status(400).json({ success: false, message: 'User is not associated with a pharmacy' });
        }

        const history = await BalanceHistory.find({ pharmacy: req.user.pharmacy })
            .sort({ createdAt: -1 })
            .populate('relatedEntity')
            .populate('product', 'name');

        res.status(200).json({
            success: true,
            count: history.length,
            data: history
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get pharmacy balance history for admin
// @route   GET /api/balance-history/:pharmacyId
// @access  Admin
exports.getPharmacyBalanceHistory = async (req, res) => {
    try {
        const history = await BalanceHistory.find({ pharmacy: req.params.pharmacyId })
            .sort({ createdAt: -1 })
            .populate('relatedEntity')
            .populate('product', 'name');

        res.status(200).json({
            success: true,
            count: history.length,
            data: history
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
