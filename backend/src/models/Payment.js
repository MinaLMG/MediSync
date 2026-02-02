const mongoose = require('mongoose');

const PaymentSchema = new mongoose.Schema({
    pharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    type: {
        type: String,
        enum: ['deposit', 'withdrawal'],
        required: true
    },
    method: {
        type: String,
        enum: ['cash', 'bank_transfer', 'cheque', 'other'],
        default: 'cash'
    },
    referenceNumber: {
        type: String,
        trim: true
    },
    proofImage: {
        type: String
    },
    adminNote: {
        type: String
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    processedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    processedAt: {
        type: Date
    }
}, { timestamps: true });

module.exports = mongoose.model('Payment', PaymentSchema);
