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
    originalQuantity: {
        type: Number,
        required: true,
        min: 1
    },
    remainingQuantity: {
        type: Number,
        required: true,
        min: 0
    },
    expiryDate: {
        type: Date,
        required: true
    },
    // The specific price selected by the pharmacist or manually entered
    selectedPrice: {
        type: Number,
        required: true,
        min: 0
    },
    salePercentage: {
        type: Number,
        required: false,
        min: 0,
        max: 30
    },
    saleAmount: {
        type: Number,
        required: false,
        min: 0
    },
    // To track if this price was manually entered and not in origin list
    isNewPrice: {
        type: Boolean,
        default: false
    },
    status: {
        type: String,
        enum: ['pending', 'available', 'reserved', 'sold', 'expired', 'rejected'],
        default: 'pending'
    }
}, {
    timestamps: true
});

// Indexes for efficient querying
stockExcessSchema.index({ pharmacy: 1, status: 1 });
stockExcessSchema.index({ status: 1 }); // For admin fetching pending/available
stockExcessSchema.index({ expiryDate: 1 });

module.exports = mongoose.model('StockExcess', stockExcessSchema);
