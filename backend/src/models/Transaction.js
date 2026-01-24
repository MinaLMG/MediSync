const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
    stockShortage: {
        shortage: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'StockShortage',
            required: true
        },
        quantityTaken: {
            type: Number,
            required: true,
            min: 1
        }
    },
    stockExcessSources: [
        {
            stockExcess: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'StockExcess',
                required: true
            },
            quantity: {
                type: Number,
                required: true,
                min: 1
            },
            agreedPrice: {
                type: Number,
                required: true,
                min: 0
            },
            totalAmount: {
                type: Number,
                required: true,
                min: 0
            }
        }
    ],
    totalQuantity: {
        type: Number,
        required: true,
        min: 1
    },
    totalAmount: {
        type: Number,
        required: true,
        min: 0
    },
    status: {
        type: String,
        enum: ['pending', 'accepted', 'rejected', 'completed', 'cancelled'],
        default: 'pending'
    },
    commissionRatio: {
        type: Number
    },
    shortage_fulfillment: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

// Indexes for efficient querying
transactionSchema.index({ 'stockShortage.shortage': 1 });
transactionSchema.index({ status: 1 });

module.exports = mongoose.model('Transaction', transactionSchema);
