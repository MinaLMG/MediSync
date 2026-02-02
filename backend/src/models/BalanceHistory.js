const mongoose = require('mongoose');

const balanceHistorySchema = new mongoose.Schema({
    pharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
    type: {
        type: String,
        enum: ['transaction_revenue', 'transaction_payment', 'expenses', 'manual', 'compensation','deposit','withdrawal'],
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
        enum: ['Transaction', 'ReversalTicket', 'Compensation','Payment']
    },
    description: {
        type: String,
        required: true
    },
    description_ar: {
        type: String
    },
    details: {
        type: mongoose.Schema.Types.Mixed // For storing specific breakdown like commission ratios
    }
}, {
    timestamps: true
});

balanceHistorySchema.index({ pharmacy: 1, createdAt: -1 });

module.exports = mongoose.model('BalanceHistory', balanceHistorySchema);
