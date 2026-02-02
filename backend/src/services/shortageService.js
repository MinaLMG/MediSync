const { StockShortage, StockExcess, Product, Order, Reservation } = require('../models');
const auditService = require('./auditService');
const serialService = require('./serialService');
const mongoose = require('mongoose');

/**
 * Creates a single stock shortage.
 */
exports.createShortage = async (data, pharmacyId, req = null) => {
    const { product: productId, volume, quantity, notes, targetPrice } = data;

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
        targetPrice,
        type: 'request',
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
                targetPrice: item.targetPrice,
                type: 'market_order',
                status: 'active',
                order: order._id,
                notes: item.notes
            });
            await shortage.save({ session });
            createdShortages.push(shortage._id);
        }

        order.items = createdShortages;
        await order.save({ session });

        // Update Order Totals (Items and Amount)
        await exports.updateOrderTotals(order._id, session);

        // Create reservations for each shortage
        for (const item of items) {
            if (item.targetPrice) {
                // Create or update reservation for this product/volume/price combination
                await Reservation.findOneAndUpdate(
                    {
                        product: item.product,
                        volume: item.volume,
                        price: item.targetPrice
                    },
                    {
                        $inc: { quantity: item.quantity }
                    },
                    { upsert: true, session }
                );
            }
        }

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
            
            const oldQuantity = shortage.quantity;
            shortage.quantity = quantity;
            shortage.remainingQuantity = quantity - fulfilled;

            // Update reservation if this shortage has an order and targetPrice
            if (shortage.order && shortage.targetPrice) {
                const quantityDiff = quantity - oldQuantity;
                
                await Reservation.findOneAndUpdate(
                    {
                        product: shortage.product,
                        volume: shortage.volume,
                        price: shortage.targetPrice
                    },
                    {
                        $inc: { quantity: quantityDiff }
                    },
                    { session }
                );

                // Delete reservation if quantity reaches 0 or below
                await Reservation.deleteMany(
                    {
                        quantity: { $lte: 0 }
                    },
                    { session }
                );
            }
        }

        if (notes !== undefined) shortage.notes = notes;

        await exports.syncShortageStatus(shortage, session);
        await shortage.save({ session });

        // Sync order totals if linked
        if (shortage.order) {
            await exports.updateOrderTotals(shortage.order, session);
        }

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
    // Note: We don't save the shortage here; the caller is expected to save it.
};

/**
 * Updates an order's totals and status based on its shortages.
 */
exports.updateOrderTotals = async (orderId, session = null) => {
    const order = await Order.findById(orderId).session(session);
    if (!order) return;

    const remainingShortages = await StockShortage.find({ order: orderId }).session(session);
    
    // 1. Update Counts
    order.totalItems = remainingShortages.length;
    order.fulfilledItems = remainingShortages.filter(s => s.status === 'fulfilled').length;
    
    // 2. Update Total Amount (Sum of Quantity * targetPrice)
    order.totalAmount = remainingShortages.reduce((sum, s) => {
        return sum + (s.quantity * (s.targetPrice || 0));
    }, 0);

    // 3. Update Order Status
    if (order.totalItems === 0) {
        order.status = 'fulfilled'; 
    } else if (order.fulfilledItems === order.totalItems) {
        order.status = 'fulfilled';
    } else if (order.fulfilledItems > 0 || remainingShortages.some(s => s.status === 'partially_fulfilled')) {
        order.status = 'partially_fulfilled';
    } else {
        order.status = 'pending';
    }

    await order.save({ session });
};

/**
 * Deletes a shortage and cleans up its reservation and order.
 */
exports.deleteShortage = async (shortageId, pharmacyId, req = null) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const shortage = await StockShortage.findById(shortageId).session(session);
        if (!shortage) throw new Error('Shortage not found');

        // Check authorized (Manager/Owner or Admin)
        if (req?.user?.role !== 'admin' && shortage.pharmacy.toString() !== pharmacyId.toString()) {
            throw new Error('Not authorized to delete this shortage');
        }

        const fulfilled = shortage.quantity - shortage.remainingQuantity;
        if (fulfilled > 0) throw new Error('Cannot delete a shortage that has been partially or fully fulfilled.');

        // 1. Cleanup Reservation
        if (shortage.order && shortage.targetPrice && shortage.remainingQuantity > 0) {
            await Reservation.findOneAndUpdate(
                {
                    product: shortage.product,
                    volume: shortage.volume,
                    price: shortage.targetPrice
                },
                {
                    $inc: { quantity: -shortage.remainingQuantity }
                },
                { session }
            );

            await Reservation.deleteMany({ quantity: { $lte: 0 } }, { session });
        }

        const orderId = shortage.order;

        // 2. Delete Shortage
        await shortage.deleteOne({ session });

        // 3. Update Order Totals
        if (orderId) {
            await exports.updateOrderTotals(orderId, session);
        }

        await session.commitTransaction();

        await auditService.logAction({
            user: req?.user?._id,
            action: 'DELETE',
            entityType: 'StockShortage',
            entityId: shortageId,
            changes: shortage.toObject()
        }, req);

    } catch (error) {
        await session.abortTransaction();
        throw error;
    } finally {
        session.endSession();
    }
};
