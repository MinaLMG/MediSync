const { StockExcess, Pharmacy } = require('../models');
const mongoose = require('mongoose');

/**
 * Gets cash balance and its history for a hub.
 */
exports.getCashBalanceSummary = async (pharmacyId) => {
    const hub = await Pharmacy.findById(pharmacyId);
    if (!hub || !hub.isHub) throw new Error('Pharmacy is not a hub');

    const history = await mongoose.model('CashBalanceHistory')
        .find({ pharmacy: pharmacyId })
        .sort({ createdAt: -1 })
        .limit(50);

    return {
        cashBalance: hub.cashBalance || 0,
        history
    };
};

/**
 * Gets system summary (optimistic value and items) for a hub.
 */
exports.getSystemSummary = async (pharmacyId) => {
    const { Settings } = require('../models');
    const commissionService = require('./commissionService');
    
    const settings = await Settings.getSettings();
    const systemMinComm = settings.minimumCommission || 10;

    const excesses = await StockExcess.find({
        pharmacy: pharmacyId,
        status: { $in: ['available', 'partially_fulfilled'] },
        remainingQuantity: { $gt: 0 }
    }).populate('product', 'name').populate('volume', 'name');

    let totalOptimisticValue = 0;
    const items = excesses.map(excess => {
        const sale = excess.salePercentage || 0;
        const { commission, agreedSale } = commissionService.calculateAgreedCommissionSync(sale, systemMinComm);
        
        const unitValue = excess.selectedPrice * (1 - (agreedSale / 100));
        const itemValue = unitValue * excess.remainingQuantity;
        
        totalOptimisticValue += itemValue;

        return {
            ...excess.toObject(),
            optimisticValue: itemValue,
            commission,
            agreedSale
        };
    });
    
    // Calculate Non-Hub (Market) Optimistic Value
    // Fetch available excesses from pharmacies that are NOT hubs
    const nonHubExcesses = await StockExcess.find({
        status: { $in: ['available', 'partially_fulfilled'] },
        remainingQuantity: { $gt: 0 }
    }).populate({
        path: 'pharmacy',
        match: { isHub: { $ne: true } },
        select: 'isHub'
    });

    // Filter out those where pharmacy didn't match (meaning they ARE hubs)
    const filteredNonHubExcesses = nonHubExcesses.filter(e => e.pharmacy);

    let totalNonHubOptimisticValue = 0;
    filteredNonHubExcesses.forEach(excess => {
        const sale = excess.salePercentage || 0;
        const { agreedSale } = commissionService.calculateAgreedCommissionSync(sale, systemMinComm);
        const unitValue = excess.selectedPrice * (1 - (agreedSale / 100));
        totalNonHubOptimisticValue += (unitValue * excess.remainingQuantity);
    });

    return {
        totalOptimisticValue,
        totalNonHubOptimisticValue,
        items
    };
};
