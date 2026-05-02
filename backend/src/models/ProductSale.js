const mongoose = require('mongoose');

const ProductSaleSchema = new mongoose.Schema({
    product: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: true
    },
    sales: [{
        discount: Number,
        consumerPrice: Number,
        pharmacyPrice: Number,
        seller: String,
        isupply_product_id: Number,
        fetchedAt: {
            type: Date,
            default: Date.now
        }
    }],
    fetchedAt: {
        type: Date,
        default: Date.now
    }
}, { timestamps: true });

module.exports = mongoose.model('ProductSale', ProductSaleSchema);
