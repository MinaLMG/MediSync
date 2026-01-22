const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    nameAr: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        trim: true
    },
    parentCategory: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category',
        default: null
    },
    icon: {
        type: String,
        trim: true
    }
}, {
    timestamps: true
});

// Index for searching
categorySchema.index({ name: 'text', nameAr: 'text' });

module.exports = mongoose.model('Category', categorySchema);
