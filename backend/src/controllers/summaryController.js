const hubSummaryService = require('../services/hubSummaryService');
const transactionSummaryService = require('../services/transactionSummaryService');
const { Pharmacy } = require('../models');

exports.getHubCashSummary = async (req, res) => {
    try {
        const summary = await hubSummaryService.getCashBalanceSummary(req.user.pharmacy);
        res.status(200).json({ success: true, data: summary });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getAdminSummary = async (req, res) => {
    try {
        const summary = await transactionSummaryService.getTransactionsSummary(req.query);
        res.status(200).json({ success: true, data: summary });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getPharmaciesList = async (req, res) => {
    try {
        const pharmacies = await Pharmacy.find({ status: 'active' }).select('name address phone').sort({ name: 1 });
        res.status(200).json({ success: true, data: pharmacies });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
