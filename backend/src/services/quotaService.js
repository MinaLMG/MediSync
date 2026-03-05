const { ProductQuota, PharmacyQuota } = require('../models');
const mongoose = require('mongoose');
const Product = require('../models/Product');

/**
 * Gets the remaining quota for a pharmacy for a specific product deal.
 * @param {string} pharmacyId
 * @param {Object} dealAttributes - { product, volume, price, expiryDate, salePercentage }
 */
exports.getRemainingQuota = async (pharmacyId, dealAttributes) => {
    const { product, volume, price, expiryDate, salePercentage } = dealAttributes;

    // 1. Get Global Quota for the specific deal
    const productQuota = await ProductQuota.findOne({
        product,
        volume,
        price,
        expiryDate,
        salePercentage: salePercentage || 0
    });

    if (!productQuota) return Infinity; // No quota set means unlimited

    // 2. Get current monthly usage for the pharmacy for this SPECIFIC deal
    const now = new Date();
    const pharmacyQuotaUsage = await PharmacyQuota.findOne({
        pharmacy: pharmacyId,
        product,
        volume,
        price,
        expiryDate,
        salePercentage: salePercentage || 0,
        recordExpiryDate: { $gt: now }
    });

    const quantityTaken = pharmacyQuotaUsage ? pharmacyQuotaUsage.quantityTaken : 0;
    const remaining = productQuota.maxQuantity - quantityTaken;

    return Math.max(0, remaining);
};

/**
 * Checks if a requested quantity exceeds the remaining quota for a specific deal.
 */
exports.checkQuota = async (pharmacyId, dealAttributes, requestedQuantity) => {
    const remaining = await exports.getRemainingQuota(pharmacyId, dealAttributes);

    if (requestedQuantity > remaining) {
        const product = await Product.findById(dealAttributes.product);
        throw {
            message: `Quota exceeded for this specific deal of ${product.name}. You can only purchase ${remaining} more units of this deal this month.`,
            code: 403
        };
    }
};

/**
 * Increments the quota usage for a pharmacy for a specific deal atomically.
 */
exports.incrementQuota = async (pharmacyId, dealAttributes, quantity, session = null) => {
    const { product, volume, price, expiryDate, salePercentage } = dealAttributes;
    const now = new Date();

    const recordExpiryDate = new Date();
    recordExpiryDate.setMonth(recordExpiryDate.getMonth() + 1);

    const pharmacyQuotaUsage = await PharmacyQuota.findOneAndUpdate(
        {
            pharmacy: pharmacyId,
            product,
            volume,
            price,
            expiryDate,
            salePercentage: salePercentage || 0,
            recordExpiryDate: { $gt: now }
        },
        {
            $inc: { quantityTaken: quantity },
            $setOnInsert: { recordExpiryDate }
        },
        {
            upsert: true,
            new: true,
            session,
            runValidators: true
        }
    );

    return pharmacyQuotaUsage;
};

/**
 * Decrements the quota usage for a pharmacy for a specific deal atomically.
 */
exports.decrementQuota = async (pharmacyId, dealAttributes, quantity, session = null) => {
    const { product, volume, price, expiryDate, salePercentage } = dealAttributes;
    const now = new Date();

    const pharmacyQuotaUsage = await PharmacyQuota.findOneAndUpdate(
        {
            pharmacy: pharmacyId,
            product,
            volume,
            price,
            expiryDate,
            salePercentage: salePercentage || 0,
            recordExpiryDate: { $gt: now }
        },
        {
            $inc: { quantityTaken: -quantity }
        },
        {
            new: true,
            session
        }
    );

    if (pharmacyQuotaUsage && pharmacyQuotaUsage.quantityTaken < 0) {
        pharmacyQuotaUsage.quantityTaken = 0;
        await pharmacyQuotaUsage.save({ session });
    }

    return pharmacyQuotaUsage;
};

/**
 * Bulk fetches remaining quotas for a list of items for a specific pharmacy.
 * @param {string} pharmacyId 
 * @param {Array} items - List of items with dealAttributes
 */
exports.bulkGetRemainingQuotas = async (pharmacyId, items) => {
    if (!items || items.length === 0) return {};

    const itemKeys = items.map(item => ({
        product: item.product,
        volume: item.volume,
        price: item.price,
        expiryDate: item.expiryDate,
        salePercentage: item.originalSalePercentage !== undefined ? item.originalSalePercentage : (item.salePercentage || 0)
    }));
    // 1. Fetch relevant Global Quotas
    const globalQuotas = await ProductQuota.find({
        $or: itemKeys
    }).lean();
    // Map for O(1) lookup
    const globalQuotaMap = {};
    globalQuotas.forEach(q => {
        const key = `${q.product}-${q.volume}-${q.price}-${q.expiryDate}-${q.salePercentage}`;
        globalQuotaMap[key] = q.maxQuantity;
    });
    // 2. Fetch current Pharmacy Usage
    const now = new Date();
    const pharmacyUsages = await PharmacyQuota.find({
        pharmacy: pharmacyId,
        recordExpiryDate: { $gt: now },
        $or: itemKeys
    }).lean();

    const usageMap = {};
    pharmacyUsages.forEach(u => {
        const key = `${u.product}-${u.volume}-${u.price}-${u.expiryDate}-${u.salePercentage}`;
        usageMap[key] = u.quantityTaken;
    });

    // 3. Calculate remaining for each item
    const results = {};
    items.forEach(item => {
        const saleToUse = item.originalSalePercentage !== undefined ? item.originalSalePercentage : (item.salePercentage || 0);
        const key = `${item.product}-${item.volume}-${item.price}-${item.expiryDate}-${saleToUse}`;
        const max = globalQuotaMap[key];

        if (max === undefined) {
            results[key] = Infinity;
        } else {
            const used = usageMap[key] || 0;
            results[key] = Math.max(0, max - used);
        }
    });

    return results;
};
