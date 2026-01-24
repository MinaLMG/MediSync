const mongoose = require('mongoose');

const productSuggestionSchema = new mongoose.Schema({
    suggestedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    activeIngredient: {
        type: String,
        trim: true
    },
    manufacturerName: {
        type: String,
        required: true,
        trim: true
    },
    categoryName: {
        type: String,
        required: true,
        trim: true
    },
    volumeName: {
        type: String,
        required: true,
        trim: true
    },
    value: {
        type: Number,
        required: true,
        min: 1,
        default: 1
    },
    price: {
        type: Number,
        required: true,
        min: 0
    },
    status: {
        type: String,
        enum: ['pending', 'approved', 'rejected'],
        default: 'pending'
    },
    adminNotes: {
        type: String,
        trim: true
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('ProductSuggestion', productSuggestionSchema);
