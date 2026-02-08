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
        },
        balanceEffect: {
            type: Number // Positive or negative effect on buyer's balance
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
            },
            balanceEffect: {
                type: Number // Effect on seller's balance
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
    serial: {
        type: String,
        unique: true
    },
    commissionRatio: {
        type: Number
    },
    buyerCommissionRatio: {
        type: Number
    },
    sellerBonusRatio: {
        type: Number
    },
    shortage_fulfillment: {
        type: Boolean,
        default: true
    },
    delivery: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    reversalTicket: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'ReversalTicket'
    },
    added_to_hub: {
        excessId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'StockExcess'
        }
    }
}, {
    timestamps: true
});

// Indexes for efficient querying
transactionSchema.index({ 'stockShortage.shortage': 1 });
transactionSchema.index({ status: 1 });

module.exports = mongoose.model('Transaction', transactionSchema);
