const mongoose = require('mongoose');

const pharmacySchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    phone: {
        type: String,
        required: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        trim: true,
        lowercase: true
    },
    ownerName: {
        type: String,
        required: true,
        trim: true
    },
    nationalId: {
        type: String,
        required: true,
        trim: true,
        match: [/^\d{14}$/, 'National ID must be exactly 14 digits']
    },
    pharmacistCard: {
        type: String,
        required: true,
        trim: true
    },
    commercialRegistry: {
        type: String,
        required: true,
        trim: true
    },
    taxCard: {
        type: String,
        required: true,
        trim: true
    },
    pharmacyLicense: {
        type: String,
        required: true,
        trim: true
    },
    signImage: {
        type: String,
        trim: true
    },
    address: {
        type: String,
        required: true,
        trim: true,
        maxlength: 200
    },
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: {
            type: [Number], // [longitude, latitude]
            default: [0, 0]
        }
    },
    status: {
        type: String,
        enum: ['pending', 'active', 'suspended', 'rejected'],
        default: 'pending'
    },
    verified: {
        type: Boolean,
        default: false
    },
    rating: {
        type: Number,
        default: 0,
        min: 0,
        max: 5
    },
    totalTransactions: {
        type: Number,
        default: 0
    },
    balance: {
        type: Number,
        default: 0
    },
    isHub: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// Index for geospatial queries
pharmacySchema.index({ location: '2dsphere' });

// Index for searching
pharmacySchema.index({ name: 'text', 'address.city': 'text', 'address.governorate': 'text' });

module.exports = mongoose.model('Pharmacy', pharmacySchema);
