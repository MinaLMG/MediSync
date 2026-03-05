const mongoose = require('mongoose');
const {
    StockShortage,
    StockExcess,
    Order,
    Settings,
    Product,
    Pharmacy,
    Reservation
} = require('../models');
const serialService = require('./serialService');
const auditService = require('./auditService');

// Lazy-loaded services for circular dependency safety
const getExcessService = () => require('./excessService');
const getQuotaService = () => require('./quotaService');

// =============================================================================
// SHORTAGE CREATION (SINGLE & BULK)
// =============================================================================

/**
 * Creates a new stock shortage.
 * Handles serial number generation, product validation, and initial status sync.
 *
 * @param {Object} data - Shortage data.
 * @param {string} pharmacyId - Pharmacy ID.
 * @param {Object} [req] - Request for auditing.
 * @param {Object} [session] - Mongoose session.
 */
exports.createShortage = async (data, pharmacyId, req = null, session = null) => {
    const { product: productId, volume, quantity, targetPrice, expiryDate, salePercentage, isSystemGenerated } = data;

    const product = await Product.findById(productId).session(session);
    if (!product || product.status !== 'active') {
        throw { message: 'This product is currently inactive and cannot be added as a shortage.', code: 400 };
    }

    const existingExcess = await StockExcess.findOne({
        pharmacy: pharmacyId,
        product: productId,
        status: { $in: ['pending', 'available', 'partially_fulfilled'] }
    }).session(session);

    if (existingExcess) {
        // Allow ONLY hubs to have both shortage and excess for the same product
        const pharmacy = await Pharmacy.findById(pharmacyId).session(session);
        if (!pharmacy || !pharmacy.isHub) {
            throw { message: 'You cannot add a shortage for this product because you already have an excess for it.', code: 409 };
        }
    }

    const shortage = await StockShortage.create([{
        pharmacy: pharmacyId,
        product: productId,
        volume,
        quantity,
        remainingQuantity: quantity,
        targetPrice,
        salePercentage,
        type: 'request',
        status: 'active',
        isSystemGenerated: isSystemGenerated || false
    }], { session });

    const shortageDoc = shortage[0];

    // Note: Quota check is skipped for standalone shortages per last refinement


    return shortageDoc;
};

/**
 * Creates a bulk order containing multiple shortages.
 * Links all shortages to a single Order document.
 *
 * @param {Object} orderData - Data containing items array.
 * @param {string} pharmacyId - Pharmacy ID.
 * @param {Object} [req] - Request for auditing.
 * @param {Object} session - Mongoose session (Required for bulk operations).
 */
exports.createOrder = async (orderData, pharmacyId, req = null, session = null) => {
    try {
        const { items } = orderData;

        // Validate items array
        if (!items || items.length === 0) {
            throw { message: 'Order must contain at least one item', code: 400 };
        }

        const quotaService = getQuotaService();
        // Pre-validate quotas for all items and increment usage
        for (const item of items) {
            const dealAttributes = {
                product: item.product,
                volume: item.volume,
                price: item.targetPrice,
                expiryDate: item.expiryDate || "ANY",
                salePercentage: item.originalSalePercentage || item.salePercentage || 0
            };
            await quotaService.checkQuota(pharmacyId, dealAttributes, item.quantity, session);
            await quotaService.incrementQuota(pharmacyId, dealAttributes, item.quantity, session);
        }

        const serial = await serialService.generateOrderSerial();

        const order = new Order({
            pharmacy: pharmacyId,
            serial,
            status: 'pending',
            totalItems: items.length,
            fulfilledItems: 0
        });
        await order.save({ session });

        const createdShortages = [];
        for (const item of items) {
            // Validate quantity
            if (!item.quantity || item.quantity <= 0) {
                throw { message: `Invalid quantity for product ${item.product}. Quantity must be a positive number.`, code: 400 };
            }

            const product = await Product.findById(item.product).session(session);
            if (!product || product.status !== 'active') throw { message: `Product ${item.product} is inactive.`, code: 400 };
            const existingExcess = await StockExcess.findOne({
                pharmacy: pharmacyId,
                product: item.product,
                status: { $in: ['pending', 'available', 'partially_fulfilled'] }
            }).session(session);
            if (existingExcess) {
                throw { message: `You cannot add a shortage for ${product.name} because you already have an excess for it.`, code: 409 };
            }
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
                originalSalePercentage: item.originalSalePercentage || 0,
                salePercentage: item.salePercentage || 0,
                expiryDate: item.expiryDate // Store selected expiry
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
                // MUST match specific batch attributes (Original Sale)
                const saleToReserve = item.originalSalePercentage || 0;

                await Reservation.findOneAndUpdate(
                    {
                        product: item.product,
                        volume: item.volume,
                        price: item.targetPrice,
                        expiryDate: item.expiryDate || "ANY",
                        salePercentage: saleToReserve
                    },
                    {
                        $inc: { quantity: item.quantity }
                    },
                    { upsert: true, session }
                );
            }
        }


        return order;
    } catch (error) {
        throw error;
    }
};

// =============================================================================
// SHORTAGE MANAGEMENT (LIFE CYCLE)
// =============================================================================

/**
 * Updates shortage quantity and synchronizes its status.
 *
 * @param {string} shortageId - Shortage ID.
 * @param {Object} updateData - Data to update.
 * @param {string} pharmacyId - Pharmacy ID (for authorization).
 * @param {Object} [req] - Request for auditing.
 * @param {Object} [session] - Mongoose session.
 */
exports.updateShortage = async (shortageId, updateData, pharmacyId, req = null, session = null) => {
    try {
        const shortage = await StockShortage.findById(shortageId).session(session);
        if (!shortage) throw { message: 'Shortage not found', code: 404 };

        if (shortage.pharmacy.toString() !== pharmacyId.toString()) {
            throw { message: 'Not authorized to update this shortage', code: 403 };
        }

        if (shortage.status !== 'active' && shortage.status !== 'partially_fulfilled') {
            throw { message: 'Cannot update non-active shortage', code: 409 };
        }

        const { quantity } = updateData;
        const fulfilled = shortage.quantity - shortage.remainingQuantity;

        if (quantity !== undefined) {
            if (quantity > shortage.quantity) throw { message: 'Quantity can only be decreased.', code: 400 };
            if (quantity < fulfilled) throw { message: `Cannot be less than fulfilled (${fulfilled}).`, code: 400 };

            const oldQuantity = shortage.quantity;
            shortage.quantity = quantity;
            shortage.remainingQuantity = quantity - fulfilled;

            // Update quota usage ONLY for order-linked shortages
            if (shortage.order) {
                const quotaService = getQuotaService();
                const dealAttributes = {
                    product: shortage.product,
                    volume: shortage.volume,
                    price: shortage.targetPrice,
                    expiryDate: shortage.expiryDate || "ANY",
                    salePercentage: shortage.originalSalePercentage || shortage.salePercentage || 0
                };
                const quantityDiff = quantity - oldQuantity;
                if (quantityDiff > 0) {
                    //check quota then increment 
                    await quotaService.checkQuota(pharmacyId, dealAttributes, quantityDiff, session);
                    await quotaService.incrementQuota(pharmacyId, dealAttributes, quantityDiff, session);
                } else if (quantityDiff < 0) {
                    await quotaService.decrementQuota(pharmacyId, dealAttributes, Math.abs(quantityDiff), session);
                }
            }

            // Update reservation if this shortage has an order and targetPrice
            if (shortage.order && shortage.targetPrice) {
                const quantityDiff = quantity - oldQuantity;

                await Reservation.findOneAndUpdate(
                    {
                        product: shortage.product,
                        volume: shortage.volume,
                        price: shortage.targetPrice,
                        expiryDate: shortage.expiryDate || "ANY",
                        salePercentage: shortage.originalSalePercentage || shortage.salePercentage || 0
                    },
                    {
                        $inc: { quantity: quantityDiff }
                    },
                    { session }
                );

            }
        }

        await exports.syncShortageStatus(shortage, session);
        // shortage.save() and order sync handled inside sync


        return shortage;
    } catch (error) {
        throw error;
    }
};

// =============================================================================
// ORDER SYNCHRONIZATION
// =============================================================================

/**
 * Synchronizes shortage status based on remaining quantity.
 * Transitions between 'active', 'partially_fulfilled', 'fulfilled', or 'cancelled'.
 * Also triggers parent order synchronization if applicable.
 *
 * @param {Object} shortage - Shortage document.
 * @param {Object} session - Mongoose session.
 */
exports.syncShortageStatus = async (shortage, session = null) => {
    // Don't change cancelled status
    if (shortage.status === 'cancelled') return;

    if (shortage.remainingQuantity === 0) {
        shortage.status = 'fulfilled';
    } else if (shortage.remainingQuantity < shortage.quantity) {
        shortage.status = 'partially_fulfilled';
    } else {
        shortage.status = 'active';
    }

    // Save the shortage state first so updateOrderTotals sees correct data
    if (session)
        await shortage.save({ session });

    // Update parent order if exists
    if (shortage.order) {
        await exports.updateOrderTotals(shortage.order, session);
    }
};

/**
 * Synchronizes the status and fulfillment data of a parent Order.
 * Called whenever a linked shortage changes status or quantity.
 *
 * @param {string} orderId - Order ID.
 * @param {Object} session - Mongoose session.
 */
exports.updateOrderTotals = async (orderId, session = null) => {
    const order = await Order.findById(orderId).session(session);
    if (!order) return;

    const remainingShortages = await StockShortage.find({ order: orderId, status: { $ne: 'cancelled' } }).session(session);

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
/**
 * Cancels a shortage (instead of deleting it).
 * Sets status to 'cancelled', remainingQuantity to 0, and updates linked entities.
 */
exports.cancelShortage = async (shortageId, session, req = null) => {

    const shortage = await StockShortage.findById(shortageId).session(session);
    if (!shortage) throw { message: 'Shortage not found', code: 404 };

    // Check if fully available (no transactions/fulfillments yet)
    // The user requested: "same conditions for deleting the shortage, it should have the quantiy equal to remaining quantity"
    if (shortage.remainingQuantity !== shortage.quantity) {
        throw { message: 'Cannot cancel a shortage that has been partially or fully fulfilled.', code: 409 };
    }

    // 1. Cleanup Reservation (similar to delete)
    if (shortage.order && shortage.targetPrice && shortage.remainingQuantity > 0) {
        await Reservation.findOneAndUpdate(
            {
                product: shortage.product,
                volume: shortage.volume,
                price: shortage.targetPrice,
                expiryDate: shortage.expiryDate || "ANY",
                salePercentage: shortage.originalSalePercentage || shortage.salePercentage || 0
            },
            {
                $inc: { quantity: -shortage.remainingQuantity }
            },
            { session }
        );

    }

    // 2. Set Status to Cancelled and Clear Quantity
    shortage.status = 'cancelled';
    shortage.remainingQuantity = 0;
    await shortage.save({ session });

    // Decrement quota usage ONLY if linked to an order
    if (shortage.order) {
        const dealAttributes = {
            product: shortage.product,
            volume: shortage.volume,
            price: shortage.targetPrice,
            expiryDate: shortage.expiryDate || "ANY",
            salePercentage: shortage.originalSalePercentage || shortage.salePercentage || 0
        };
        await getQuotaService().decrementQuota(shortage.pharmacy, dealAttributes, shortage.quantity, session);
    }

    // 3. Update Order Totals if linked
    if (shortage.order) {
        // We need to update order totals. 
        // Note: updateOrderTotals fetches *all* shortages for the order.
        // Since we didn't delete the record, but set status to 'cancelled', 
        // we need to make sure updateOrderTotals handles 'cancelled' correctly (invokes sync logic or ignores).
        // Let's check updateOrderTotals logic.
        // It fetches ALL shortages.
        // It sums quantity * targetPrice. 
        // If status is cancelled, should it count towards totals? Probably not.
        // We should modify updateOrderTotals to exclude cancelled/rejected shortages from sums if that's the desired behavior.
        // Or, since we set remainingQuantity to 0, maybe that's enough?
        // Wait, updateOrderTotals uses `s.quantity` for total amount, not `s.remainingQuantity`.
        // So we might need to adjust logic there too or ensure cancelled items are skipped.
        // Let's modify updateOrderTotals as well to be safe.
        await exports.updateOrderTotals(shortage.order, session);
    }

    // Log action

    return shortage;
};

exports.deleteShortage = async (shortageId, pharmacyId, req = null, session = null) => {
    try {
        const shortage = await StockShortage.findById(shortageId).session(session);
        if (!shortage) throw { message: 'Shortage not found', code: 404 };

        // Check authorized (Manager/Owner or Admin)
        if (req?.user?.role !== 'admin' && shortage.pharmacy.toString() !== pharmacyId.toString()) {
            throw { message: 'Not authorized to delete this shortage', code: 403 };
        }

        const fulfilled = shortage.quantity - shortage.remainingQuantity;
        if (fulfilled > 0) throw { message: 'Cannot delete a shortage that has been partially or fully fulfilled.', code: 409 };

        // 1. Cleanup Reservation
        if (shortage.order && shortage.targetPrice && shortage.remainingQuantity > 0) {
            await Reservation.findOneAndUpdate(
                {
                    product: shortage.product,
                    volume: shortage.volume,
                    price: shortage.targetPrice,
                    expiryDate: shortage.expiryDate || "ANY",
                    salePercentage: shortage.originalSalePercentage || shortage.salePercentage || 0
                },
                {
                    $inc: { quantity: -shortage.remainingQuantity }
                },
                { session }
            );
        }

        const orderId = shortage.order;

        // 2. Delete Shortage
        await shortage.deleteOne({ session });

        // Decrement quota usage ONLY if linked to an order
        if (orderId) {
            const dealAttributes = {
                product: shortage.product,
                volume: shortage.volume,
                price: shortage.targetPrice,
                expiryDate: shortage.expiryDate || "ANY",
                salePercentage: shortage.originalSalePercentage || shortage.salePercentage || 0
            };
            await getQuotaService().decrementQuota(pharmacyId, dealAttributes, shortage.quantity, session);
        }

        // 3. Update Order Totals
        if (orderId) {
            await exports.updateOrderTotals(orderId, session);
        }


    } catch (error) {
        throw error;
    }
};
