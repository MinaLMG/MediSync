/**
 * STOCK EXCESS STATUS MEANING TABLE
 * ---------------------------------
 * pending: Awaiting admin approval. Full Edit allowed.
 * available: Approved/Active. No stock taken or reserved. Edit Sale & Quantity (Decrease only) allowed.
 * partially_fulfilled: Some stock taken or reserved, but remainingQuantity > 0. Edit Sale & Quantity (Decrease only) allowed.
 * reserved: All stock reserved (remainingQuantity == 0), but some transactions are still pending/accepted. Edit Sale ONLY.
 * fulfilled: All stock matched and transitions finished. Bridge status or terminal. Edit Sale ONLY.
 * sold: Terminal state. All transactions completed. LOCKED.
 * rejected: Denied by admin. LOCKED.
 * expired: Expired by date. LOCKED.
 */
const mongoose= require('mongoose')
const stockExcessSchema = new mongoose.Schema({
    pharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
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
    originalQuantity: {
        type: Number,
        required: true,
        min: 1
    },
    remainingQuantity: {
        type: Number,
        required: true,
        min: 0
    },
    expiryDate: {
        type: String, // Stored as "MM/YY"
        required: true
    },
    rejectionReason: {
        type: String,
        required: false
    },
    // The specific price selected by the pharmacist or manually entered
    selectedPrice: {
        type: Number,
        required: true,
        min: 0
    },
    salePercentage: {
        type: Number,
        required: false,
        min: 0,
        max: 100 // Updated max to 100 as per request
    },
    saleAmount: {
        type: Number,
        required: false,
        min: 0
    },
    shortage_fulfillment: {
        type: Boolean,
        default: false
    },
    // To track if this price was manually entered and not in origin list
    isNewPrice: {
        type: Boolean,
        default: false
    },
    status: {
        type: String,
        enum: ['pending', 'available', 'reserved', 'sold', 'expired', 'rejected', 'fulfilled', 'partially_fulfilled'],
        default: 'pending'
    }
}, {
    timestamps: true
});

// Indexes for efficient querying
stockExcessSchema.index({ pharmacy: 1, status: 1 });
stockExcessSchema.index({ status: 1 }); // For admin fetching pending/available
stockExcessSchema.index({ expiryDate: 1 });

module.exports = mongoose.model('StockExcess', stockExcessSchema);
