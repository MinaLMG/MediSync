const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    type: {
        type: String,
        enum: ['transaction', 'message', 'system', 'alert'],
        required: true
    },
    priority: {
        type: String,
        enum: ['low', 'normal', 'high'],
        default: 'normal'
    },
    message: {
        type: String,
        required: true,
        trim: true
    },
    message_ar: {
        type: String,
        trim: true
    },
    relatedEntity: {
        type: mongoose.Schema.Types.ObjectId,
        refPath: 'relatedEntityType'
    },
    relatedEntityType: {
        type: String,
        enum: ['Transaction', 'StockShortage', 'StockExcess', 'Review', 'User', 'Pharmacy', 'Product', 'ProductSuggestion', 'Compensation','Payment']
    },
    actionUrl: {
        type: String,
        trim: true
    },
    seen: {
        type: Boolean,
        default: false
    },
    seenAt: {
        type: Date
    }
}, {
    timestamps: true
});

// Indexes for efficient querying
notificationSchema.index({ user: 1, seen: 1, createdAt: -1 });
notificationSchema.index({ user: 1, type: 1, seen: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
