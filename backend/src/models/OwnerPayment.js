const mongoose = require('mongoose');

const ownerPaymentSchema = new mongoose.Schema({
    pharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
    owner: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Owner',
        required: true
    },
    value: {
        type: Number,
        required: true // Positive if paid to the hub, negative if paid from the hub
    },
    timestamp: {
        type: Date,
        default: Date.now
    },
    notes: {
        type: String,
        trim: true
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('OwnerPayment', ownerPaymentSchema);
