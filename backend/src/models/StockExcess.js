const mongoose = require('mongoose');

const stockExcessSchema = new mongoose.Schema({
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
    quantity: {
        type: Number,
        required: true,
        min: 1
    },
    expiryDate: {
        type: Date,
        required: true
    },
    sellingPrice: {
        type: Number,
        required: true,
        min: 0
    },
    minPrice: {
        type: Number,
        required: true,
        min: 0
    },
    accepted: {
        type: Boolean,
        default: false
    },
    status: {
        type: String,
        enum: ['available', 'reserved', 'sold', 'expired'],
        default: 'available'
    }
}, {
    timestamps: true
});

// Indexes for efficient querying
stockExcessSchema.index({ pharmacy: 1, status: 1 });
stockExcessSchema.index({ product: 1, volume: 1, status: 1, accepted: 1 });
stockExcessSchema.index({ expiryDate: 1 });

module.exports = mongoose.model('StockExcess', stockExcessSchema);
