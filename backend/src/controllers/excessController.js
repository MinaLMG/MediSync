const excessService = require('../services/excessService');
const { StockExcess, HasVolume, Settings, Reservation } = require('../models');
const { default: mongoose } = require('mongoose');

exports.createExcess = async (req, res) => {
    try {
        const excess = await excessService.createExcess(req.body, req.user.pharmacy, req);
        res.status(201).json({ success: true, data: excess });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

exports.updateExcess = async (req, res) => {
    try {
        const excess = await excessService.updateExcess(req.params.id, req.body, req.user, req);
        res.status(200).json({ success: true, data: excess });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.deleteExcess = async (req, res) => {
    try {
        const excess = await StockExcess.findById(req.params.id);
        if (!excess) return res.status(404).json({ success: false, message: 'Not found' });
        if (req.user.role !== 'admin' && excess.pharmacy.toString() !== req.user.pharmacy.toString()) {
             return res.status(403).json({ success: false, message: 'Unauthorized' });
        }
        if ((excess.originalQuantity - excess.remainingQuantity) > 0) {
            return res.status(400).json({ success: false, message: 'Cannot delete fulfilled excess' });
        }
        if (excess.isHubGenerated) {
            return res.status(400).json({ success: false, message: 'Hub-generated excesses cannot be deleted as they represent a termed transfer. If you need to stop this listing, please use the Cancellation option to reduce the remaining quantity to 0.' });
        }
        await excess.deleteOne();
        res.status(200).json({ success: true, message: 'Deleted' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.approveExcess = async (req, res) => {
    const mongoose = require('mongoose');
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const excess = await excessService.approveExcess(req.params.id, session);
        await session.commitTransaction();
        res.status(200).json({ success: true, data: excess });
    } catch (error) {
        await session.abortTransaction();
        res.status(500).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

exports.rejectExcess = async (req, res) => {
    try {
        const { rejectionReason } = req.body;
        if (!rejectionReason) return res.status(400).json({ success: false, message: 'Reason required' });
        const excess = await StockExcess.findByIdAndUpdate(req.params.id, { status: 'rejected', rejectionReason }, { new: true });
        if (!excess) return res.status(404).json({ success: false, message: 'Not found' });
        res.status(200).json({ success: true, data: excess });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getPendingExcesses = async (req, res) => {
    try {
        const excesses = await StockExcess.find({ status: 'pending' }).populate('pharmacy', 'name phone').populate('product', 'name').populate('volume', 'name').sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getMyExcesses = async (req, res) => {
    try {
    const excesses = await StockExcess.find({ 
        pharmacy: req.user.pharmacy,
    }).populate('product', 'name').populate('volume', 'name').sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getAvailableExcesses = async (req, res) => {
    try {
        const excesses = await StockExcess.find({ 
            status: { $in: ['available', 'partially_fulfilled'] } 
        })
            .populate('pharmacy', 'name address phone')
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: excesses });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

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
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.syncExcessStatus = async (excess, session = null) => {
    return excessService.syncExcessStatus(excess, session);
};

exports.addToHub = async (req, res) => {
    try {
        const { excessId, hubId, quantity } = req.body;
        if (!excessId || !hubId || !quantity) {
            return res.status(400).json({ success: false, message: 'Missing required fields' });
        }
        const result = await excessService.addToHub(excessId, hubId, quantity, req);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get market excesses grouped by product -> prices -> items
// @route   GET /api/excess/market
// @access  Pharmacy Owner, Manager
exports.getMarketExcesses = async (req, res) => {
    try {
        const settings = await Settings.getSettings();
        const systemMinComm = settings.minimumCommission || 10;
        // 1. Get raw aggregated excesses (Grouped by Product -> Price -> Expiry/Sale)
        const marketItems = await StockExcess.aggregate([
            {
                $match: {
                    pharmacy: { $ne: req.user.pharmacy },
                    status: { $in: ['available', 'partially_fulfilled'] },
                    remainingQuantity: { $gt: 0 },
                    // Filter out shortage fulfillment (specific requests)
                    shortage_fulfillment: { $ne: true }
                }
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
        const processedItems = [];

        for (const group of marketItems) {
            const key = `${group._id.product}-${group._id.volume}-${group._id.price}-${group._id.expiryDate}-${group._id.salePercentage}`;
           
            const reserved = reservationMap[key] || 0;
            const available = group.totalQuantity - reserved;

            if (available > 0) {
                const originalSale = group._id.salePercentage || 0;
                // Logic: 
                // 1. comm = max(systemMinComm, ceil(originalSale / 3))
                // 2. agreedSale = max(0, originalSale - comm)
                const comm = Math.max(systemMinComm, Math.ceil(originalSale / 3));
                let agreedSale = Math.max(0, originalSale - comm);

                processedItems.push({
                    product: group._id.product,
                    volume: group._id.volume,
                    price: group._id.price,
                    // Item Details
                    quantity: available,
                    expiryDate: group._id.expiryDate,
                    originalSalePercentage: originalSale, // To backend
                    salePercentage: agreedSale, // To frontend (User sees this)
                    userSale: agreedSale // Compatibility
                });
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
            prices: Object.values(p.prices).sort((a,b) => a.price - b.price)
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
        res.status(500).json({ success: false, message: error.message });
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
        res.status(500).json({ success: false, message: error.message });
    }
};
