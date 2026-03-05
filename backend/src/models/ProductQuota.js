const mongoose = require('mongoose');

const productQuotaSchema = new mongoose.Schema({
    product: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: true
    },
    volume: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Volume',
        required: true
    },
    price: {
        type: Number,
        required: true
    },
    expiryDate: {
        type: String, // MM/YY
        required: true
    },
    salePercentage: {
        type: Number,
        default: 0
    },
    maxQuantity: {
        type: Number,
        required: true,
        min: 1
    }
}, {
    timestamps: true
});

// Compound index for uniqueness
productQuotaSchema.index({
    product: 1,
    volume: 1,
    price: 1,
    expiryDate: 1,
    salePercentage: 1
}, {
    unique: true
});

module.exports = mongoose.model('ProductQuota', productQuotaSchema);
