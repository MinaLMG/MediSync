const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
    pharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
    serial: {
        type: String,
        unique: true
    },
    status: {
        type: String,
        enum: ['pending', 'partially_fulfilled', 'fulfilled', 'cancelled'],
        default: 'pending'
    },
    totalItems: {
        type: Number,
        default: 0
    },
    fulfilledItems: {
        type: Number,
        default: 0
    },
    totalAmount: { // Sum of (Quantity * Target Price)
        type: Number,
        default: 0
    },
    notes: {
        type: String
    }
}, {
    timestamps: true
});

// Indexes
orderSchema.index({ pharmacy: 1, status: 1 });
orderSchema.index({ serial: 1 });

module.exports = mongoose.model('Order', orderSchema);
