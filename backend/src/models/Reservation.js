const mongoose = require('mongoose');

const reservationSchema = new mongoose.Schema({
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
    price: {
        type: Number,
        required: true
    },
    quantity: {
        type: Number,
        required: true,
        min: 1
    },
    expiryDate: {
        type: String, // MM/YY
        required: true
    },
    salePercentage: {
        type: Number,
        default: 0
    },
}, {
    timestamps: true
});

// Create a compound index for efficient querying
reservationSchema.index({ product: 1, volume: 1, price: 1, expiryDate: 1, salePercentage: 1 });

module.exports = mongoose.model('Reservation', reservationSchema);
