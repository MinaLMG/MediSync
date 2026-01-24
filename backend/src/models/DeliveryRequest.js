const mongoose = require('mongoose');

const deliveryRequestSchema = new mongoose.Schema({
    delivery: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    transaction: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Transaction',
        required: true
    },
    requestType: {
        type: String,
        enum: ['accept', 'complete'],
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'approved', 'rejected'],
        default: 'pending'
    }
}, {
    timestamps: true
});

// Ensure a delivery person can't make multiple pending requests for the same transaction
deliveryRequestSchema.index({ delivery: 1, transaction: 1, status: 1 }, { unique: true });

module.exports = mongoose.model('DeliveryRequest', deliveryRequestSchema);
