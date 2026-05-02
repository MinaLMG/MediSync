const mongoose = require('mongoose');

const productChoiceSchema = new mongoose.Schema({
    product: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: true,
        unique: true
    },
    choices: [
        {
            id: Number,
            title: String,
            price: Number
        }
    ]
}, {
    timestamps: true
});

module.exports = mongoose.model('ProductChoice', productChoiceSchema);
