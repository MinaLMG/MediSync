const mongoose = require('mongoose');

/**
 * STOCK SHORTAGE STATUS MEANING TABLE
 * -----------------------------------
 * active: Open for matching. No stock taken or reserved. Edit Quantity (Decrease only) allowed.
 * partially_fulfilled: Some stock matched or taken, but remainingQuantity > 0. Edit Quantity (Decrease only) allowed.
 * fulfilled: All stock matched/taken (remainingQuantity == 0). LOCKED.
 * cancelled: Closed by user. LOCKED.
 */

const stockShortageSchema = new mongoose.Schema({
    pharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
    order: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Order'
    },
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
    quantity: {
        type: Number,
        required: true,
        min: 1
    },
    remainingQuantity: {
        type: Number,
        required: true,
        min: 0
    },  
    status: {
        type: String,
        enum: ['active', 'fulfilled', 'partially_fulfilled', 'cancelled'],
        default: 'active'
    },
    type: {
        type: String,
        enum: ['request', 'market_order'],
        default: 'request'
    },
    
    // Order Data (Optional)
    targetPrice: {
        type: Number,
        min: 0
    },
    originalSalePercentage: {
        type: Number,
        min: 0,
        max: 100
    },
    salePercentage: { // Agreed Sale
        type: Number,
        default: 0,
        min: 0,
        max: 100
    },
    expiryDate: {
        type: String,
        required: false
    }
  
}, {
    timestamps: true
});

// Indexes for efficient querying
stockShortageSchema.index({ pharmacy: 1, status: 1 });
stockShortageSchema.index({ product: 1, volume: 1, status: 1 });

module.exports = mongoose.model('StockShortage', stockShortageSchema);
