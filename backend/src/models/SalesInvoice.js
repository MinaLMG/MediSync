const mongoose = require('mongoose');

const salesInvoiceSchema = new mongoose.Schema({
    pharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
    items: [{
        excess: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'StockExcess',
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
        quantity: {
            type: Number,
            required: true,
            min: 1
        },
        buyingPrice: { // Unit Cost (from Excess.purchasePrice)
            type: Number,
            required: true,
            min: 0
        },
        sellingPrice: { // Unit Sale Price
            type: Number,
            required: true,
            min: 0
        }
    }],
    totalBuyingPrice: { // Renamed from buyingPrice for clarity, but keeping original name might be safer if used elsewhere. 
                        // User request: "total buying and selling prices... calculated"
                        // I will use `buyingPrice` as TOTAL to maintain backward compat if any, 
                        // but since it's a refactor, maybe clear names are better?
                        // "we need to generalize it by extending the sales invoice model"
        type: Number,
        required: true,
        min: 0
    },
    totalSellingPrice: {
        type: Number,
        required: true,
        min: 0
    },
    totalRevenuePrice: {
        type: Number,
        required: true
    },
    date: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('SalesInvoice', salesInvoiceSchema);
