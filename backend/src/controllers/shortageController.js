const { StockShortage, StockExcess, Product, Order } = require('../models');

// Create new shortage (Single)
exports.createShortage = async (req, res) => {
    try {
        const { product: productId, volume, quantity, notes } = req.body;

        // Check product status
        const product = await Product.findById(productId);
        if (!product || product.status !== 'active') {
            return res.status(400).json({
                success: false,
                message: 'This product is currently inactive and cannot be added as a shortage.'
            });
        }

        // Check if an Excess exists for this product (Constraint)
        const existingExcess = await StockExcess.findOne({
            pharmacy: req.user.pharmacy,
            product: productId,
            status: { $in: ['pending', 'available', 'partially_fulfilled'] }
        });

        if (existingExcess) {
            return res.status(400).json({ 
                success: false, 
                message: 'You cannot add a shortage for this product because you already have an excess for it.' 
            });
        }

        const shortage = await StockShortage.create({
            pharmacy: req.user.pharmacy,
            product: productId,
            volume,
            quantity,
            remainingQuantity: quantity,
            notes,
            status: 'active'
        });

        res.status(201).json({ success: true, data: shortage });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

// Create bulk order (Multiple Shortages)
// @route   POST /api/shortage/order
// @access  Pharmacy Owner / Manager
exports.createOrder = async (req, res) => {
    
    const mongoose = require('mongoose');
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { items, notes } = req.body; // items: [{ product, volume, quantity, notes }]
        const { Order } = require('../models');

        if (!items || items.length === 0) {
            throw new Error('Order must contain at least one item.');
        }

        // 1. Create Order
        const date = new Date();
        const datePrefix = `${date.getFullYear()}${String(date.getMonth() + 1).padStart(2, '0')}${String(date.getDate()).padStart(2, '0')}`;
        const lastOrder = await Order.findOne({ serial: { $regex: `^ORD-${datePrefix}-` } }).sort({ serial: -1 }).session(session);
        let sequence = 101;
        if (lastOrder && lastOrder.serial) {
            const parts = lastOrder.serial.split('-');
            if (parts.length === 3 && !isNaN(parseInt(parts[2]))) sequence = parseInt(parts[2]) + 1;
        }
        const serial = `ORD-${datePrefix}-${String(sequence).padStart(4, '0')}`;

        const order = new Order({
            pharmacy: req.user.pharmacy,
            serial,
            status: 'pending',
            totalItems: items.length,
            fulfilledItems: 0,
            notes
        });
        await order.save({ session });

        const createdShortages = [];

        // 2. Create StockShortages
        for (const item of items) {
             // Check product status
            const product = await Product.findById(item.product).session(session);
            if (!product || product.status !== 'active') {
                throw new Error(`Product ${item.product} is inactive.`);
            }

            // Check Excess Constraint
            const existingExcess = await StockExcess.findOne({
                pharmacy: req.user.pharmacy,
                product: item.product,
                status: { $in: ['pending', 'available', 'partially_fulfilled'] }
            }).session(session);

            if (existingExcess) {
                 throw new Error(`You cannot order ${product.name} because you have an active excess for it.`);
            }

            const shortage = new StockShortage({
                pharmacy: req.user.pharmacy,
                product: item.product,
                volume: item.volume,
                quantity: item.quantity,
                remainingQuantity: item.quantity,
                notes: item.notes,
                status: 'active',
                order: order._id,
                type: 'market_order', // Orders are market purchases, not real shortages
                targetPrice: item.targetPrice
            });
            await shortage.save({ session });
            createdShortages.push(shortage);
        }
        
        // Calculate Total Amount
        const totalAmount = createdShortages.reduce((sum, s) => sum + ((s.quantity || 0) * (s.targetPrice || 0)), 0);
        order.totalAmount = totalAmount;
        await order.save({ session });


        await session.commitTransaction();
        
        res.status(201).json({ success: true, data: { order, shortages: createdShortages } });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// Get active shortages (Admin)
exports.getActiveShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ remainingQuantity: { $gt: 0 } })
            .populate('pharmacy', 'name address phone')
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: shortages });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get shortages for a specific pharmacy (Manager)
exports.getMyShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ pharmacy: req.user.pharmacy })
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: shortages });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Update shortage (Manager/Owner)
exports.updateShortage = async (req, res) => {
    try {
        const { quantity, notes } = req.body;

        const shortage = await StockShortage.findById(req.params.id);

        if (!shortage) {
            return res.status(404).json({ success: false, message: 'Shortage not found' });
        }

        if (shortage.pharmacy.toString() !== req.user.pharmacy.toString()) {
            return res.status(403).json({ success: false, message: 'Not authorized to update this shortage' });
        }

        if (shortage.status !== 'active' && shortage.status !== 'partially_fulfilled') {
             return res.status(400).json({ success: false, message: 'Cannot update non-active shortage' });
        }

        // Immutability Check
        const { product, volume } = req.body;
        if (product && product !== shortage.product.toString()) {
            return res.status(400).json({ success: false, message: 'Product cannot be modified' });
        }
        if (volume && volume !== shortage.volume.toString()) {
            return res.status(400).json({ success: false, message: 'Volume cannot be modified' });
        }

        const fulfilled = shortage.quantity - shortage.remainingQuantity;

        if (quantity !== undefined) {
            // Rule: Quantity can only be DECREASED
            if (quantity > shortage.quantity) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'Quantity can only be decreased to prevent exploitation.' 
                });
            }
            if (quantity < fulfilled) {
                return res.status(400).json({ 
                    success: false, 
                    message: `New quantity (${quantity}) cannot be less than already fulfilled quantity (${fulfilled}).` 
                });
            }
            shortage.quantity = quantity;
            shortage.remainingQuantity = quantity - fulfilled;
        }

        shortage.notes = notes || shortage.notes;

        await exports.syncShortageStatus(shortage);
        await shortage.save();

        res.status(200).json({ success: true, data: shortage });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Delete shortage (Admin/Owner/Manager)
exports.deleteShortage = async (req, res) => {
    try {
        const shortage = await StockShortage.findById(req.params.id);

        if (!shortage) {
            return res.status(404).json({ success: false, message: 'Shortage not found' });
        }

        if (req.user.role !== 'admin' && shortage.pharmacy.toString() !== req.user.pharmacy.toString()) {
             return res.status(403).json({ success: false, message: 'Not authorized to delete this shortage' });
        }

        // Deletion constraint: Only active shortages with zero fulfillment can be deleted
        const fulfilled = shortage.quantity - shortage.remainingQuantity;
        if (fulfilled > 0) {
            return res.status(400).json({ 
                success: false, 
                message: 'Cannot delete shortage that has already been matched/fulfilled.' 
            });
        }

        if (shortage.status !== 'active') {
            return res.status(400).json({
                success: false,
                message: `Cannot delete shortage in ${shortage.status} state.`
            });
        }

        await shortage.deleteOne();

        res.status(200).json({ success: true, message: 'Shortage deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc   Get Orders (Admin)
// @route  GET /api/shortage/orders
exports.getOrders = async (req, res) => {
    try {
        const { status } = req.query;
        let query = {};
        if (status) query.status = status;

        const { Order } = require('../models');

        const orders = await Order.find(query)
            .populate('pharmacy', 'name address phone')
            .sort({ createdAt: -1 });

        // Optionally, populate shortages for each order? Or let frontend fetch details on demand.
        // User said: "admin can know the order a pharmacy requested and fulfill every item in it"
        // Let's include the shortages in the response for convenience, or at least a count.
        // Order model has totalItems, so that's good.
        // Let's fetch the shortages too.
        
        const ordersWithItems = await Promise.all(orders.map(async (order) => {
            const items = await StockShortage.find({ order: order._id })
                .populate('product', 'name')
                .populate('volume', 'name');
            return {
                ...order.toObject(),
                items
            };
        }));

        res.status(200).json({ success: true, count: ordersWithItems.length, data: ordersWithItems });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get all unique product names with active shortages system-wide (For News Marquee)
// @route   GET /api/shortage/global-active
// @access  Private (Managers/Admin)
exports.getGlobalActiveShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ remainingQuantity: { $gt: 0 } })
            .select('product')
            .populate('product', 'name');

        // Extract unique names
        const productNames = [...new Set(shortages.map(s => s.product?.name).filter(Boolean))];
        console.log("shortage productnames:",productNames)
        res.status(200).json({ success: true, count: productNames.length, data: productNames });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
        }
};

// Helper to sync shortage status based on consistency
exports.syncShortageStatus = async (shortage, session = null) => {
    // 1. Calculate status based on remaining vs original
    if (shortage.remainingQuantity <= 0) {
        shortage.status = 'fulfilled';
    } else if (shortage.remainingQuantity < shortage.quantity) {
        shortage.status = 'partially_fulfilled';
    } else {
        if (shortage.status !== 'cancelled') {
            shortage.status = 'active';
        }
    }
    
    // Sync parent Order if applicable
    if (shortage.order) {
        const { Order } = require('../models');
        // Find all shortages for this order to determine overall status
        const siblings = await StockShortage.find({ order: shortage.order }).session(session);
        
        // Map siblings to use the current shortage status (which might be in memory only)
        const currentId = shortage._id.toString();
        const effectiveSiblings = siblings.map(s => {
            if (s._id.toString() === currentId) return shortage;
            return s;
        });
        
        let allFulfilled = true;
        let anyPartially = false;
        let anyFulfilled = false;
        let fulfilledCount = 0;

        for (const s of effectiveSiblings) {
            if (s.status !== 'fulfilled' && s.status !== 'cancelled') allFulfilled = false;
            if (s.status === 'partially_fulfilled') anyPartially = true;
            if (s.status === 'fulfilled' || s.status === 'partially_fulfilled') anyFulfilled = true;
            if (s.status === 'fulfilled') fulfilledCount++;
        }

        let newOrderStatus = 'pending';
        if (allFulfilled && effectiveSiblings.length > 0) {
            newOrderStatus = 'fulfilled';
        } else if (anyPartially || anyFulfilled) {
            newOrderStatus = 'partially_fulfilled'; 
        }

        await Order.findByIdAndUpdate(shortage.order, { 
            status: newOrderStatus,
            fulfilledItems: fulfilledCount
        }).session(session);
    }
};
