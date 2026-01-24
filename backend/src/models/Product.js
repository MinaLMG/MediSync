const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        trim: true
    },
    description: {
        type: String,
        trim: true
    },
    conversions: [
        {
            from: {
                type: String,
                required: true,
                trim: true
            },
            to: {
                type: String,
                required: true,
                trim: true
            },
            value: {
                type: Number,
                required: true,
                min: 1
            }
        }
    ],
    status: {
        type: String,
        enum: ['active', 'discontinued'],
        default: 'active'
    }
}, {
    timestamps: true
});

// Index for searching
productSchema.index({ name: 'text', description: 'text' });

module.exports = mongoose.model('Product', productSchema);
