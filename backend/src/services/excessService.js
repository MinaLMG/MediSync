const { StockExcess, HasVolume, StockShortage, Settings, Product, Transaction } = require('../models');
const auditService = require('./auditService');
const mongoose = require('mongoose');

/**
 * Creates a new stock excess.
 */
exports.createExcess = async (userData, pharmacyId, req = null) => {
    const { 
        product, 
        volume, 
        quantity, 
        expiryDate, 
        selectedPrice, 
        salePercentage, 
        shortage_fulfillment 
    } = userData;

    // Check product status
    const productObj = await Product.findById(product);
    if (!productObj || productObj.status !== 'active') {
        throw new Error('This product is currently inactive and cannot be added as an excess.');
    }

    // Check if a Shortage exists for this product (Constraint)
    const existingShortage = await StockShortage.findOne({
        pharmacy: pharmacyId,
        product,
        status: { $in: ['active', 'partially_fulfilled'] }
    });

    if (existingShortage) {
        throw new Error('You cannot add an excess for this product because you already have an active shortage for it.');
    }

    let finalSalePercentage = 0;
    let finalSaleAmount = 0;

    if (shortage_fulfillment === false) {
        finalSalePercentage = salePercentage || 0;
        finalSaleAmount = (selectedPrice * finalSalePercentage) / 100;
    }

    // Check if Selected Price is New
    const hasVolume = await HasVolume.findOne({ product, volume });
    let isNewPrice = false;
    if (hasVolume && !hasVolume.prices.includes(selectedPrice)) {
        isNewPrice = true;
    }

    const excess = await StockExcess.create({
        pharmacy: pharmacyId, 
        product,
        volume,
        originalQuantity: quantity,
        remainingQuantity: quantity,
        expiryDate,
        selectedPrice,
        salePercentage: finalSalePercentage,
        saleAmount: finalSaleAmount,
        shortage_fulfillment: shortage_fulfillment !== false,
        isNewPrice,
        status: 'pending'
    });

    await auditService.logAction({
        user: req?.user?._id,
        action: 'CREATE',
        entityType: 'StockExcess',
        entityId: excess._id,
        changes: excess.toObject()
    }, req);

    return excess;
};

/**
 * Updates an existing excess.
 */
exports.updateExcess = async (excessId, updateData, user, req = null) => {
    const { quantity, selectedPrice, salePercentage, shortage_fulfillment } = updateData;
    
    const excess = await StockExcess.findById(excessId);
    if (!excess) throw new Error('Excess not found');

    // Ownership Check
    if (user.role !== 'admin' && excess.pharmacy.toString() !== user.pharmacy.toString()) {
        throw new Error('Not authorized to update this excess');
    }

    if (['sold', 'expired', 'rejected'].includes(excess.status)) {
        throw new Error(`Cannot update excess with status ${excess.status}. It is locked.`);
    }

    const taken = excess.originalQuantity - excess.remainingQuantity;

    // Validate quantity decrease
    if (quantity !== undefined) {
        if (quantity < taken) throw new Error(`Quantity cannot be less than taken (${taken}).`);
        excess.originalQuantity = quantity;
        excess.remainingQuantity = quantity - taken;
    }

    // Update sale info
    if (shortage_fulfillment !== undefined) excess.shortage_fulfillment = shortage_fulfillment;
    
    if (excess.shortage_fulfillment) {
        excess.salePercentage = 0;
        excess.saleAmount = 0;
    } else if (salePercentage !== undefined) {
        excess.salePercentage = salePercentage;
        excess.saleAmount = (selectedPrice || excess.selectedPrice) * salePercentage / 100;
    }

    if (selectedPrice !== undefined && excess.status === 'pending') {
        excess.selectedPrice = selectedPrice;
    }

    await exports.syncExcessStatus(excess);
    await excess.save();

    await auditService.logAction({
        user: user._id,
        action: 'UPDATE',
        entityType: 'StockExcess',
        entityId: excess._id,
        changes: updateData
    }, req);

    return excess;
};

/**
 * Synchronizes the status of an excess based on remaining quantity and active transactions.
 */
exports.syncExcessStatus = async (excess, session = null) => {
    const query = Transaction.find({ 'stockExcessSources.stockExcess': excess._id });
    if (session) query.session(session);
    const transactions = await query;
    
    const hasActive = transactions.some(t => ['pending', 'accepted'].includes(t.status));
    const hasCompleted = transactions.some(t => t.status === 'completed');

    if (excess.remainingQuantity > 0) {
        if (hasActive || hasCompleted) {
            excess.status = 'partially_fulfilled';
        } else if (!['pending', 'rejected'].includes(excess.status)) {
            excess.status = 'available';
        }
    } else {
        if (hasActive) {
            excess.status = hasCompleted ? 'fulfilled' : 'reserved';
        } else {
            excess.status = hasCompleted ? 'sold' : 'fulfilled';
        }
    }
};
