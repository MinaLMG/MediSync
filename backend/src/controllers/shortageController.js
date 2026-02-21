const shortageService = require('../services/shortageService');
const { StockShortage } = require('../models');
const mongoose = require('mongoose');

// Create new shortage (Single)
exports.createShortage = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const shortage = await shortageService.createShortage(req.body, req.user.pharmacy, req, session);
        await session.commitTransaction();
        res.status(201).json({ success: true, data: shortage });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// Create bulk order (Multiple Shortages)
exports.createOrder = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const order = await shortageService.createOrder(req.body, req.user.pharmacy, req, session);
        await session.commitTransaction();
        res.status(201).json({ success: true, data: order });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// Update shortage (Manager/Owner)
exports.updateShortage = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const updates = {};
        const allowedFields = ['quantity'];
        for (const field of allowedFields) {
            if (req.body[field] !== undefined) updates[field] = req.body[field];
        }

        const shortage = await shortageService.updateShortage(req.params.id, updates, req.user.pharmacy, req, session);
        await session.commitTransaction();
        res.status(200).json({ success: true, data: shortage });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// Cancel shortage (User/Admin)
exports.cancelShortage = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const StockShortage = mongoose.model('StockShortage');
        // Ownership check inside service or here?
        // Service generally handles logic, but controller handles auth.
        // Let's do a quick check here before calling service, or pass pharmacyId to service.
        // The service logic I wrote takes (shortageId, session, req).
        // It doesn't explicitly check pharmacy ownership inside cancelShortage yet.
        // I should probably add ownership check in controller.
        
        const shortage = await StockShortage.findById(req.params.id);
        if (!shortage) throw { message: 'Shortage not found', code: 404 };
        
        if (req.user.role !== 'admin' && shortage.pharmacy.toString() !== req.user.pharmacy.toString()) {
             throw { message: 'Not authorized', code: 403 };
        }

        await shortageService.cancelShortage(req.params.id, session, req);
        await session.commitTransaction();
        res.status(200).json({ success: true, message: 'Cancelled successfully' });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// Delete shortage (Admin/Owner/Manager)
exports.deleteShortage = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        await shortageService.deleteShortage(req.params.id, req.user.pharmacy, req, session);
        await session.commitTransaction();
        res.status(200).json({ success: true, message: 'Deleted successfully' });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
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
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// Get shortages for my pharmacy
exports.getMyShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ 
            pharmacy: req.user.pharmacy,
        })
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: shortages });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// Get orders (Admin)
exports.getOrders = async (req, res) => {
    try {
        const { status } = req.query;
        let query = {};
        if (status) query.status = status;
        const { Order } = require('../models');
        const orders = await Order.find(query).populate('pharmacy', 'name address phone').sort({ createdAt: -1 });
        const ordersWithItems = await Promise.all(orders.map(async (order) => {
            const items = await StockShortage.find({ order: order._id })
                .populate('product', 'name')
                .populate('volume', 'name')
                .select('+expiryDate +originalSalePercentage +salePercentage +targetPrice'); // Ensure all fields are there
            return { ...order.toObject(), items };
        }));
        res.status(200).json({ success: true, count: ordersWithItems.length, data: ordersWithItems });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// Global active for News Marquee
exports.getGlobalActiveShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ remainingQuantity: { $gt: 0 } }).select('product').populate('product', 'name');
        const productNames = [...new Set(shortages.map(s => s.product?.name).filter(Boolean))];
        res.status(200).json({ success: true, count: productNames.length, data: productNames });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// Get fulfilled shortages (Admin)
exports.getFulfilledShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ 
            $or: [
                { status: 'cancelled' },
                { remainingQuantity: 0 }
            ]
        })
            .populate('pharmacy', 'name address phone')
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ updatedAt: -1 });
        res.status(200).json({ success: true, data: shortages });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// Export sync for internal use
exports.syncShortageStatus = async (shortage, session = null) => {
    return shortageService.syncShortageStatus(shortage, session);
};
