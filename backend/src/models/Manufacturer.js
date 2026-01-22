const mongoose = require('mongoose');

const manufacturerSchema = new mongoose.Schema({
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
    country: {
        type: String,
        trim: true
    },
    website: {
        type: String,
        trim: true
    },
    contactInfo: {
        type: String,
        trim: true
    }
}, {
    timestamps: true
});

// Index for searching
manufacturerSchema.index({ name: 'text', nameAr: 'text' });

module.exports = mongoose.model('Manufacturer', manufacturerSchema);
