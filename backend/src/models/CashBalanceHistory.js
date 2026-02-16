const mongoose = require('mongoose');

const cashBalanceHistorySchema = new mongoose.Schema({
    pharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
    type: {
        type: String,
        enum: ['deposit', 'withdrawal', 'manual', 'correction'],
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    previousBalance: {
        type: Number,
        required: true
    },
    newBalance: {
        type: Number,
        required: true
    },
    relatedEntity: {
        type: mongoose.Schema.Types.ObjectId,
        refPath: 'relatedEntityType'
    },
    relatedEntityType: {
        type: String,
        enum: ['Payment', 'PurchaseInvoice', 'SalesInvoice']
    },
    description: {
        type: String,
        required: true
    },
    description_ar: {
        type: String
    },
    details: {
        type: mongoose.Schema.Types.Mixed
    }
}, {
    timestamps: true
});

cashBalanceHistorySchema.index({ pharmacy: 1, createdAt: -1 });

module.exports = mongoose.model('CashBalanceHistory', cashBalanceHistorySchema);
