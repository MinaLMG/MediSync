const mongoose = require('mongoose');
const {
    StockExcess,
    HasVolume,
    Settings,
    Reservation,
    Product,
    User
} = require('../models');

// Services
const excessService = require('../services/excessService');
const hubSummaryService = require('../services/hubSummaryService');
const { addNotificationJob } = require('../utils/queueManager');
const auditService = require('../services/auditService');

// =============================================================================
// EXCESS MANAGEMENT (LIFE CYCLE)
// =============================================================================

// @desc    Create a new stock excess
// @route   POST /api/excess
// @access  Pharmacy Owner / Manager
exports.createExcess = async (req, res) => {
    try {
        const { product, quantity, selectedPrice, expiryDate } = req.body;

        // --- Hub Restriction ---
        const Pharmacy = mongoose.model('Pharmacy');
        const pharmacy = await Pharmacy.findById(req.user.pharmacy);
        if (pharmacy && pharmacy.isHub) {
            throw { message: 'Hub pharmacies cannot create excesses. Use Purchase Invoices instead.', code: 403 };
        }

        // --- Manual Validation ---
        if (!product || !quantity || !selectedPrice || !expiryDate) {
            throw { message: 'Missing required fields: product, quantity, selectedPrice, and expiryDate are required.', code: 400 };
        }
        if (quantity <= 0) {
            throw { message: 'Quantity must be a positive number.', code: 400 };
        }
        if (selectedPrice < 0) {
            throw { message: 'Price cannot be negative.', code: 400 };
        }

        // Validate expiryDate format (MM/YY)
        if (!/^(0[1-9]|1[0-2])\/\d{2}$/.test(expiryDate)) {
            throw { message: 'Expiry date must be in MM/YY format.', code: 400 };
        }

        const excess = await excessService.createExcess(req.body, req.user.pharmacy, req);

        await auditService.logAction({
            user: req.user._id,
            action: 'CREATE',
            entityType: 'StockExcess',
            entityId: excess._id,
            changes: excess.toObject()
        }, req);

        res.status(201).json({ success: true, data: excess });
    } catch (error) {
        console.error('❌ [Excess Controller] createExcess failed:', error);
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Update an existing excess
// @route   PUT /api/excess/:id
// @access  Pharmacy Owner / Manager
exports.updateExcess = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { quantity, selectedPrice } = req.body;

        // --- Manual Validation ---
        if (quantity !== undefined && quantity <= 0) {
            throw { message: 'Quantity must be a positive number.', code: 400 };
        }
        if (selectedPrice !== undefined && selectedPrice < 0) {
            throw { message: 'Price cannot be negative.', code: 400 };
        }

        const updates = {};
        const allowedFields = ['quantity', 'selectedPrice', 'salePercentage', 'shortage_fulfillment', 'expiryDate'];
        for (const field of allowedFields) {
            if (req.body[field] !== undefined) updates[field] = req.body[field];
        }

        const excess = await excessService.updateExcess(req.params.id, updates, req.user, req, session);

        await auditService.logAction({
            user: req.user._id,
            action: 'UPDATE',
            entityType: 'StockExcess',
            entityId: excess._id,
            changes: updates
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, data: excess });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        console.error('❌ [Excess Controller] updateExcess failed:', error);
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

exports.deleteExcess = async (req, res) => {
    try {
        const excess = await StockExcess.findById(req.params.id);
        if (!excess) throw { message: 'Excess not found', code: 404 };

        if (req.user.role !== 'admin' && excess.pharmacy.toString() !== req.user.pharmacy.toString()) {
            throw { message: 'Unauthorized', code: 403 };
        }
        if ((excess.originalQuantity - excess.remainingQuantity) > 0) {
            throw { message: 'Cannot delete fulfilled excess', code: 409 };
        }
        if (excess.isHubGenerated || excess.isHubPurchase) {
            throw { message: 'Hub stock (transfers or purchases) cannot be deleted directly. Please use the source document to manage this stock.', code: 409 };
        }
        await excess.deleteOne();

        await auditService.logAction({
            user: req.user._id,
            action: 'DELETE',
            entityType: 'StockExcess',
            entityId: req.params.id,
            changes: excess.toObject()
        }, req);

        res.status(200).json({ success: true, message: 'Deleted' });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Approve a pending excess
// @route   PUT /api/excess/:id/approve
// @access  Admin
exports.approveExcess = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const excess = await excessService.approveExcess(req.params.id, session);

        await auditService.logAction({
            user: req.user._id,
            action: 'APPROVE',
            entityType: 'StockExcess',
            entityId: excess._id,
            changes: { status: 'available' }
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, data: excess });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

exports.rejectExcess = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { rejectionReason } = req.body;
        if (!rejectionReason) throw { message: 'Reason required', code: 400 };

        const excess = await StockExcess.findById(req.params.id).session(session);
        if (!excess) throw { message: 'Excess not found', code: 404 };

        if (excess.status === 'rejected') {
            await session.commitTransaction();
            return res.status(200).json({ success: true, data: excess });
        }

        if (excess.isHubGenerated || excess.isHubPurchase) {
            throw { message: 'Hub stock (transfers or purchases) cannot be rejected. Please use the source document to manage this stock.', code: 409 };
        }

        excess.status = 'rejected';
        excess.rejectionReason = rejectionReason;
        await excess.save({ session });

        await auditService.logAction({
            user: req.user._id,
            action: 'REJECT',
            entityType: 'StockExcess',
            entityId: excess._id,
            changes: { status: 'rejected', rejectionReason }
        }, req);

        // Notify User
        const { addNotificationJob } = require('../utils/queueManager');
        const { Product, User } = require('../models');
        const product = await Product.findById(excess.product).session(session);
        const productName = product ? product.name : 'Unknown Product';
        const owner = await User.findOne({ pharmacy: excess.pharmacy }).session(session);

        if (owner) {
            setImmediate(() => addNotificationJob(
                owner._id.toString(),
                'system',
                `Your stock excess listing for "${productName}" was rejected. Reason: ${rejectionReason}`,
                {
                    relatedEntity: excess._id,
                    relatedEntityType: 'StockExcess'
                },
                `تم رفض عرض المخزون الزائد الخاص بك لـ "${productName}". السبب: ${rejectionReason}`
            ));
        }

        await session.commitTransaction();
        res.status(200).json({ success: true, data: excess });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// =============================================================================
// QUERY OPERATIONS
// =============================================================================

// @desc    Get all pending excesses
// @route   GET /api/excess/pending
// @access  Admin
exports.getPendingExcesses = async (req, res) => {
    try {
        const excesses = await StockExcess.find({ status: 'pending' }).populate('pharmacy', 'name phone').populate('product', 'name').populate('volume', 'name').sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Get excesses listed by the authenticated pharmacy
// @route   GET /api/excess/my
// @access  Pharmacy Owner / Manager
exports.getMyExcesses = async (req, res) => {
    try {
        const excesses = await StockExcess.find({
            pharmacy: req.user.pharmacy,
        }).populate('product', 'name').populate('volume', 'name').sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Get all available and partially fulfilled excesses for the market
// @route   GET /api/excess/available
// @access  Pharmacy Owner / Manager
exports.getAvailableExcesses = async (req, res) => {
    try {
        const excesses = await StockExcess.find({
            status: { $in: ['available', 'partially_fulfilled'] }
        })
            .populate('pharmacy', 'name address phone isHub')
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Get all fulfilled, rejected, or expired excesses
// @route   GET /api/excess/fulfilled
// @access  Pharmacy Owner / Manager
exports.getFulfilledExcesses = async (req, res) => {
    try {
        const excesses = await StockExcess.find({
            status: { $in: ['fulfilled', 'rejected', 'expired'] }
        })
            .populate('pharmacy', 'name address phone')
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ updatedAt: -1 });

        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Synchronize the status of an excess based on its remaining quantity
// @access  Internal (called by other services/controllers)
exports.syncExcessStatus = async (excess, session = null) => {
    return excessService.syncExcessStatus(excess, session);
};

// =============================================================================
// HUB OPERATIONS
// =============================================================================

// @desc    Transfer excess stock to a hub
// @route   POST /api/excess/hub
// @access  Admin / Pharmacy Owner
exports.addToHub = async (req, res) => {
    try {
        const { excessId, hubId, quantity } = req.body;

        // --- Manual Validation ---
        if (!excessId || !hubId || !quantity) {
            throw { message: 'Missing required fields: excessId, hubId, and quantity are required.', code: 400 };
        }
        if (quantity <= 0) {
            throw { message: 'Quantity must be a positive number.', code: 400 };
        }

        const result = await excessService.addToHub(excessId, hubId, quantity, req);

        await auditService.logAction({
            user: req.user._id,
            action: 'ADD_TO_HUB',
            entityType: 'StockExcess',
            entityId: excessId,
            changes: { hubId, quantity, newExcessId: result.hubExcess._id }
        }, req);

        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error('❌ [Excess Controller] addToHub failed:', error);
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Get market excesses grouped by product -> prices -> items
// @route   GET /api/excess/market
// @access  Pharmacy Owner, Manager
exports.getMarketExcesses = async (req, res) => {
    try {
        const settings = await Settings.getSettings();
        const systemMinComm = settings.minimumCommission || 10;
        const commissionService = require('../services/commissionService');
        let match = {
            pharmacy: { $ne: req.user.pharmacy },
            status: { $in: ['available', 'partially_fulfilled'] },
            remainingQuantity: { $gt: 0 },
            // Filter out shortage fulfillment (specific requests)
            shortage_fulfillment: { $ne: true }
        }
        if (req.user.pharmacy) {
            match.relatedPharmacy = { $ne: req.user.pharmacy }; // Cannot see own stock even in Hub
        }
        // 1. Get raw aggregated excesses (Grouped by Product -> Price -> Expiry/Sale)
        const marketItems = await StockExcess.aggregate([
            {
                $match: match
            },
            { $sort: { expiryDate: 1 } },
            // Group by strict criteria: Product, Volume, Price, Expiry, Sale
            {
                $group: {
                    _id: {
                        product: "$product",
                        volume: "$volume",
                        price: "$selectedPrice",
                        expiryDate: "$expiryDate",
                        salePercentage: "$salePercentage"
                    },
                    totalQuantity: { $sum: "$remainingQuantity" } // Sum quantity for this batch
                }
            },
            // Lookup Product and Volume details early or later?
            // We need to deduct reservations first.
        ]);
        // 2. Get Active Reservations for these products
        // We can match reservations that correspond to the found products?
        // Or just getAll reservations for safety (or optimize).
        // Optimization: Get reservations where product IN [marketItems.products].
        const productIds = marketItems.map(i => i._id.product);
        const reservations = await Reservation.aggregate([
            {
                $match: {
                    product: { $in: productIds }
                }
            },
            {
                $group: {
                    _id: {
                        product: "$product",
                        volume: "$volume",
                        price: "$price",
                        expiryDate: "$expiryDate",
                        salePercentage: "$salePercentage"
                    },
                    reservedQuantity: { $sum: "$quantity" }
                }
            }
        ]);
        // Map Reservations for O(1) lookup
        const reservationMap = {};
        reservations.forEach(r => {
            const key = `${r._id.product}-${r._id.volume}-${r._id.price}-${r._id.expiryDate}-${r._id.salePercentage}`;
            reservationMap[key] = r.reservedQuantity;
        });
        // 3. Process Market Items: Deduct Reservations & Calculate Sale
        const tempItems = [];

        for (const group of marketItems) {
            const key = `${group._id.product}-${group._id.volume}-${group._id.price}-${group._id.expiryDate}-${group._id.salePercentage}`;

            const reserved = reservationMap[key] || 0;
            const available = group.totalQuantity - reserved;

            if (available > 0) {
                const originalSale = group._id.salePercentage || 0;
                // Use commission service for consistent calculation
                const { agreedSale } = commissionService.calculateAgreedCommissionSync(originalSale, systemMinComm);
                tempItems.push({
                    product: group._id.product,
                    volume: group._id.volume,
                    price: group._id.price,
                    // Item Details
                    quantity: available,
                    // Deal Details
                    expiryDate: group._id.expiryDate || "ANY",
                    originalSalePercentage: originalSale, // To backend
                    salePercentage: agreedSale, // To frontend (User sees this)
                    userSale: agreedSale // Compatibility
                });
            }
        }
        // Apply Quota Capping (Bulk Fix N+1)
        const quotaService = require('../services/quotaService');
        const quotaMap = await quotaService.bulkGetRemainingQuotas(req.user.pharmacy, tempItems);
        const processedItems = [];
        for (const item of tempItems) {
            const key = `${item.product}-${item.volume}-${item.price}-${item.expiryDate}-${item.originalSalePercentage}`;
            const remainingQuota = quotaMap[key];

            item.quantity = Math.min(item.quantity, remainingQuota);

            if (item.quantity > 0) {
                processedItems.push(item);
            }
        }
        // 4. Re-Structure into Hierarchy (Product -> Volume -> Prices -> Items)
        // Group by Product+Volume
        const productMap = {};

        for (const item of processedItems) {
            const prodKey = `${item.product}-${item.volume}`;
            if (!productMap[prodKey]) {
                productMap[prodKey] = {
                    product: item.product,
                    volume: item.volume,
                    minPrice: item.price,
                    maxSale: item.userSale,
                    prices: {}
                };
            }

            const pGroup = productMap[prodKey];
            pGroup.minPrice = Math.min(pGroup.minPrice, item.price);
            pGroup.maxSale = Math.max(pGroup.maxSale, item.userSale);

            if (!pGroup.prices[item.price]) {
                pGroup.prices[item.price] = {
                    price: item.price,
                    maxSale: item.userSale,
                    items: []
                };
            }
            const priceGroup = pGroup.prices[item.price];
            priceGroup.maxSale = Math.max(priceGroup.maxSale, item.userSale);
            priceGroup.items.push({
                quantity: item.quantity,
                expiryDate: item.expiryDate,
                salePercentage: item.salePercentage, // Agreed
                originalSalePercentage: item.originalSalePercentage, // Hidden/Stored
                userSale: item.userSale
            });
        }
        // Convert Map to Array and Populate
        const finalResult = Object.values(productMap).map(p => ({
            product: p.product,
            volume: p.volume,
            minPrice: p.minPrice,
            maxSale: p.maxSale,
            prices: Object.values(p.prices).sort((a, b) => a.price - b.price)
        }));
        // Populate Product/Volume Details (We have IDs)
        // Note: Population in aggregation is faster usually, but we did logic in JS.
        // We can Populate manually.
        await StockExcess.populate(finalResult, [
            { path: 'product', select: 'name' },
            { path: 'volume', select: 'name' }
        ]);

        // Final Sort by Product Name
        finalResult.sort((a, b) => (a.product?.name || '').localeCompare(b.product?.name || ''));
        res.status(200).json({ success: true, count: finalResult.length, data: finalResult });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Get market insight (available excesses for specific product/volume/price)
// @route   GET /api/excess/market-insight
// @access  Pharmacy Owner, Manager
exports.getMarketInsight = async (req, res) => {
    try {
        const { product, volume, price } = req.query;
        if (!product || !volume || !price) {
            return res.status(400).json({ success: false, message: 'Product, volume, and price are required' });
        }

        const excesses = await StockExcess.aggregate([
            {
                $match: {
                    product: new mongoose.Types.ObjectId(product),
                    volume: new mongoose.Types.ObjectId(volume),
                    selectedPrice: parseFloat(price),
                    status: { $in: ['available', 'partially_fulfilled'] },
                    remainingQuantity: { $gt: 0 },
                    shortage_fulfillment: { $ne: true }
                }
            },
            {
                $group: {
                    _id: {
                        expiryDate: "$expiryDate",
                        salePercentage: "$salePercentage"
                    },
                    totalQuantity: { $sum: "$remainingQuantity" }
                }
            },
            { $sort: { "_id.expiryDate": 1 } }, // Near to far
            {
                $project: {
                    _id: 0,
                    expiryDate: "$_id.expiryDate",
                    salePercentage: "$_id.salePercentage"
                }
            }
        ]);

        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

exports.getPharmacyExcesses = async (req, res) => {
    try {
        const { pharmacyId } = req.params;
        const excesses = await StockExcess.find({
            pharmacy: pharmacyId,
            status: { $in: ['available', 'partially_fulfilled'] },
            remainingQuantity: { $gt: 0 }
        }).populate('product', 'name').populate('volume', 'name').sort({ expiryDate: 1 });
        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

exports.getHubSystemSummary = async (req, res) => {
    try {
        const summary = await hubSummaryService.getSystemSummary(req.user.pharmacy);
        res.status(200).json({ success: true, data: summary });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

