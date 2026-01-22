const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
    stockShortage: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'StockShortage',
        required: true
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
    buyerPharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
    sellerPharmacies: [
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Pharmacy'
        }
    ],
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
    }
}, {
    timestamps: true
});

// Indexes for efficient querying
transactionSchema.index({ stockShortage: 1 });
transactionSchema.index({ buyerPharmacy: 1, status: 1 });
transactionSchema.index({ sellerPharmacies: 1, status: 1 });
transactionSchema.index({ product: 1, status: 1 });

module.exports = mongoose.model('Transaction', transactionSchema);
