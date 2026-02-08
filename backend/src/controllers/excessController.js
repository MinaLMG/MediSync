const excessService = require('../services/excessService');
const { StockExcess, HasVolume } = require('../models');

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
            return res.status(400).json({ success: false, message: 'Hub generated excesses cannot be deleted. Please use cancellation.' });
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

exports.getMarketExcesses = async (req, res) => {
    try {
        const mongoose = require('mongoose');
        const { product, volume, excludeShortageFulfillment } = req.query;
        let matchStage = { remainingQuantity: { $gt: 0 }, status: { $in: ['available', 'partially_fulfilled'] } };
        if (excludeShortageFulfillment === 'true') {
            matchStage.shortage_fulfillment = { $ne: true };
        }
        if (product) matchStage.product = new mongoose.Types.ObjectId(product);
        if (volume) matchStage.volume = new mongoose.Types.ObjectId(volume);
        if (req.user.pharmacy) matchStage.pharmacy = { $ne: new mongoose.Types.ObjectId(req.user.pharmacy) };
        const aggregated = await StockExcess.aggregate([
            { $match: matchStage },
            { $group: { _id: { product: "$product", volume: "$volume", price: "$selectedPrice" }, totalQuantity: { $sum: "$remainingQuantity" } } },
            // Look up reservations for this product/volume/price
            {
                $lookup: {
                    from: "reservations",
                    let: { prod: "$_id.product", vol: "$_id.volume", pri: "$_id.price" },
                    pipeline: [
                         { $match: {
                             $expr: {
                                 $and: [
                                     { $eq: ["$product", "$$prod"] },
                                     { $eq: ["$volume", "$$vol"] },
                                     { $eq: ["$price", "$$pri"] },
                                  ]
                             }
                         }},
                         { $group: { _id: null, reservedTotal: { $sum: "$quantity" } } }
                    ],
                    as: "reservationInfo"
                }
            },
            {
                $addFields: {
                    reservedQty: { $ifNull: [{ $arrayElemAt: ["$reservationInfo.reservedTotal", 0] }, 0] }
                }
            },
            {
                $addFields: {
                    availableQuantity: { $subtract: ["$totalQuantity", "$reservedQty"] }
                }
            },
            { $match: { availableQuantity: { $gt: 0 } } }, // Hide if fully reserved
            { $lookup: { from: "products", localField: "_id.product", foreignField: "_id", as: "productDetails" } },
            { $unwind: "$productDetails" },
            { $lookup: { from: "volumes", localField: "_id.volume", foreignField: "_id", as: "volumeDetails" } },
            { $unwind: "$volumeDetails" },
            { $project: { _id: 0, product: { _id: "$_id.product", name: "$productDetails.name" }, volume: { _id: "$_id.volume", name: "$volumeDetails.name" }, price: "$_id.price", totalQuantity: "$availableQuantity" } },
            { $sort: { "product.name": 1, price: 1 } }
        ]);
        res.status(200).json({ success: true, data: aggregated });
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
