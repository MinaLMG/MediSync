const mongoose = require('mongoose');

const pharmacyQuotaSchema = new mongoose.Schema({
    pharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
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
        type: String, // MM/YY (Deal attribute)
        required: true
    },
    salePercentage: {
        type: Number,
        default: 0
    },
    quantityTaken: {
        type: Number,
        required: true,
        default: 0
    },
    recordExpiryDate: { // When the monthly quota resets
        type: Date,
        required: true
    }
}, {
    timestamps: true
});

// Compound index for unique constraints per deal/pharmacy/window
// Since expired records are deleted, this ensures one active record per deal
pharmacyQuotaSchema.index({
    pharmacy: 1,
    product: 1,
    volume: 1,
    price: 1,
    expiryDate: 1,
    salePercentage: 1,
    recordExpiryDate: 1
}, { unique: true });

module.exports = mongoose.model('PharmacyQuota', pharmacyQuotaSchema);
