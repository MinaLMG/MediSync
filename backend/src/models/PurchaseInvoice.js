const mongoose = require('mongoose');

const purchaseInvoiceSchema = new mongoose.Schema({
    pharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
    totalAmount: {
        type: Number,
        required: true,
        min: 0
    },
    items: [
        {
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
            buyingPrice: {
                type: Number,
                required: true,
                min: 0
            },
            sellingPrice: {
                type: Number,
                required: true,
                min: 0
            },
            salePercentage: {
                type: Number,
                required: true, // Assuming it's required if we create an excess
                min: 0,
                max: 100
            },
            expiryDate: {
                type: String, // Or Date, frontend sends MM/YY string or full date? AddExcess sends MM/YY usually but createExcess parses it. Let's start with String to be safe or investigatecreateExcess.
                // excessService.createExcess handles string parsing if needed. 
                // But generally better to store as Date if possible, but frontend sends formatted string.
                // Let's use String for now to match frontend input format MM/YY or generic string.
                required: true
            },
            excess: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'StockExcess'
            }
        }
    ],
    date: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('PurchaseInvoice', purchaseInvoiceSchema);
