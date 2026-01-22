const mongoose = require('mongoose');

const stockShortageSchema = new mongoose.Schema({
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
        default: function() {
            // Default to 10 years from now
            const date = new Date();
            date.setFullYear(date.getFullYear() + 10);
            return date;
        }
    },
    maxPrice: {
        type: Number,
        default: 0,
        min: 0
    },
    status: {
        type: String,
        enum: ['active', 'in_progress', 'fulfilled', 'cancelled'],
        default: 'active'
    },
    notes: {
        type: String,
        trim: true
    }
}, {
    timestamps: true
});

// Indexes for efficient querying
stockShortageSchema.index({ pharmacy: 1, status: 1 });
stockShortageSchema.index({ product: 1, volume: 1, status: 1 });

module.exports = mongoose.model('StockShortage', stockShortageSchema);
