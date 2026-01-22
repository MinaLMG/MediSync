const mongoose = require('mongoose');

const hasVolumeSchema = new mongoose.Schema({
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
    value: {
        type: Number,
        required: true,
        min: 1
    },
    prices: [{
        type: Number,
        required: true,
        min: 0
    }]
}, {
    timestamps: true
});

// Compound index to ensure unique product-volume combinations
hasVolumeSchema.index({ product: 1, volume: 1 }, { unique: true });

module.exports = mongoose.model('HasVolume', hasVolumeSchema);
