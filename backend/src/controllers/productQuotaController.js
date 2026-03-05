const { ProductQuota } = require('../models');
const auditService = require('../services/auditService');

// @desc    Get all product quotas
// @route   GET /api/quotas
// @access  Admin
exports.getQuotas = async (req, res) => {
    console.log(req.user);
    try {
        const quotas = await ProductQuota.find()
            .populate('product', 'name')
            .populate('volume', 'name');
        res.status(200).json({ success: true, data: quotas });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Create a new product quota
// @route   POST /api/quotas
// @access  Admin
exports.createQuota = async (req, res) => {
    try {
        const { product, volume, price, expiryDate, salePercentage, maxQuantity } = req.body;
        console.log(req.body);
        if (!product || !volume || !price || !expiryDate || maxQuantity === undefined) {
            return res.status(400).json({ success: false, message: 'Missing required fields: product, volume, price, expiryDate, and maxQuantity are required' });
        }

        const quota = await ProductQuota.create({
            product,
            volume,
            price,
            expiryDate,
            salePercentage: salePercentage || 0,
            maxQuantity
        });

        await auditService.logAction({
            user: req.user._id,
            action: 'CREATE',
            entityType: 'ProductQuota',
            entityId: quota._id,
            changes: quota.toObject()
        }, req);

        res.status(201).json({ success: true, data: quota });
    } catch (error) {
        if (error.code === 11000) {
            return res.status(400).json({ success: false, message: 'Quota already exists for this product' });
        }
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Update a product quota
// @route   PUT /api/quotas/:id
// @access  Admin
exports.updateQuota = async (req, res) => {
    try {
        const { maxQuantity } = req.body;
        const quota = await ProductQuota.findByIdAndUpdate(
            req.params.id,
            { maxQuantity },
            { new: true, runValidators: true }
        );

        if (!quota) {
            return res.status(404).json({ success: false, message: 'Quota not found' });
        }

        await auditService.logAction({
            user: req.user._id,
            action: 'UPDATE',
            entityType: 'ProductQuota',
            entityId: quota._id,
            changes: { maxQuantity }
        }, req);

        res.status(200).json({ success: true, data: quota });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Delete a product quota
// @route   DELETE /api/quotas/:id
// @access  Admin
exports.deleteQuota = async (req, res) => {
    try {
        const quota = await ProductQuota.findByIdAndDelete(req.params.id);

        if (!quota) {
            return res.status(404).json({ success: false, message: 'Quota not found' });
        }

        await auditService.logAction({
            user: req.user._id,
            action: 'DELETE',
            entityType: 'ProductQuota',
            entityId: req.params.id,
            changes: quota.toObject()
        }, req);

        res.status(200).json({ success: true, message: 'Quota deleted' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
