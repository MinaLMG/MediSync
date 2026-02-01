const { StockShortage, StockExcess, Product, Order } = require('../models');
const auditService = require('./auditService');
const serialService = require('./serialService');
const mongoose = require('mongoose');

/**
 * Creates a single stock shortage.
 */
exports.createShortage = async (data, pharmacyId, req = null) => {
    const { product: productId, volume, quantity, notes } = data;

    const product = await Product.findById(productId);
    if (!product || product.status !== 'active') {
        throw new Error('This product is currently inactive and cannot be added as a shortage.');
    }

    const existingExcess = await StockExcess.findOne({
        pharmacy: pharmacyId,
        product: productId,
        status: { $in: ['pending', 'available', 'partially_fulfilled'] }
    });

    if (existingExcess) {
        throw new Error('You cannot add a shortage for this product because you already have an excess for it.');
    }

    const shortage = await StockShortage.create({
        pharmacy: pharmacyId,
        product: productId,
        volume,
        quantity,
        remainingQuantity: quantity,
        notes,
        status: 'active'
    });

    await auditService.logAction({
        user: req?.user?._id,
        action: 'CREATE',
        entityType: 'StockShortage',
        entityId: shortage._id,
        changes: shortage.toObject()
    }, req);

    return shortage;
};

/**
 * Creates a bulk order containing multiple shortages.
 */
exports.createOrder = async (orderData, pharmacyId, req = null) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { items, notes } = orderData;
        
        const serial = await serialService.generateOrderSerial();

        const order = new Order({
            pharmacy: pharmacyId,
            serial,
            status: 'pending',
            totalItems: items.length,
            fulfilledItems: 0,
            notes
        });
        await order.save({ session });

        const createdShortages = [];
        for (const item of items) {
            const product = await Product.findById(item.product).session(session);
            if (!product || product.status !== 'active') throw new Error(`Product ${item.product} is inactive.`);

            const shortage = new StockShortage({
                pharmacy: pharmacyId,
                product: item.product,
                volume: item.volume,
                quantity: item.quantity,
                remainingQuantity: item.quantity,
                status: 'active',
                order: order._id,
                notes: item.notes
            });
            await shortage.save({ session });
            createdShortages.push(shortage._id);
        }

        order.items = createdShortages;
        await order.save({ session });

        await session.commitTransaction();

        await auditService.logAction({
            user: req?.user?._id,
            action: 'CREATE',
            entityType: 'Order',
            entityId: order._id,
            changes: { serial, itemsCount: items.length }
        }, req);

        return order;
    } catch (error) {
        await session.abortTransaction();
        throw error;
    } finally {
        session.endSession();
    }
};

/**
 * Updates an existing shortage.
 */
exports.updateShortage = async (shortageId, updateData, pharmacyId, req = null) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const shortage = await StockShortage.findById(shortageId).session(session);
        if (!shortage) throw new Error('Shortage not found');

        if (shortage.pharmacy.toString() !== pharmacyId.toString()) {
            throw new Error('Not authorized to update this shortage');
        }

        if (shortage.status !== 'active' && shortage.status !== 'partially_fulfilled') {
            throw new Error('Cannot update non-active shortage');
        }

        const { quantity, notes } = updateData;
        const fulfilled = shortage.quantity - shortage.remainingQuantity;

        if (quantity !== undefined) {
            if (quantity > shortage.quantity) throw new Error('Quantity can only be decreased.');
            if (quantity < fulfilled) throw new Error(`Cannot be less than fulfilled (${fulfilled}).`);
            
            shortage.quantity = quantity;
            shortage.remainingQuantity = quantity - fulfilled;
        }

        if (notes !== undefined) shortage.notes = notes;

        await exports.syncShortageStatus(shortage, session);
        await shortage.save({ session });

        await session.commitTransaction();

        await auditService.logAction({
            user: req?.user?._id,
            action: 'UPDATE',
            entityType: 'StockShortage',
            entityId: shortage._id,
            changes: updateData
        }, req);

        return shortage;
    } catch (error) {
        await session.abortTransaction();
        throw error;
    } finally {
        session.endSession();
    }
};

/**
 * Synchronizes the status of a shortage.
 */
exports.syncShortageStatus = async (shortage, session = null) => {
    if (shortage.remainingQuantity === 0) {
        shortage.status = 'fulfilled';
    } else if (shortage.remainingQuantity < shortage.quantity) {
        shortage.status = 'partially_fulfilled';
    } else {
        shortage.status = 'active';
    }

    if (shortage.order) {
        const Order = mongoose.model('Order');
        const query = Order.findById(shortage.order);
        if (session) query.session(session);
        const order = await query;

        if (order) {
            const shortageQuery = StockShortage.find({ order: order._id });
            if (session) shortageQuery.session(session);
            const allShortages = await shortageQuery;
            
            const fulfilledCount = allShortages.filter(s => s.status === 'fulfilled').length;
            order.fulfilledItems = fulfilledCount;
            if (fulfilledCount === order.totalItems) {
                order.status = 'completed';
            } else if (fulfilledCount > 0 || allShortages.some(s => s.status === 'partially_fulfilled')) {
                order.status = 'partially_fulfilled';
            }
            await order.save(session ? { session } : undefined);
        }
    }
};
