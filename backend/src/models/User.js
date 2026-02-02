const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    phone: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        match: [/^01\d{9}$/, 'Please provide a valid Egyptian phone number (11 digits starting with 01)']
    },
    email: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        lowercase: true
    },
    hashedPassword: {
        type: String,
        required: true
    },
    role: {
        type: String,
        enum: ['admin', 'pharmacy_owner', 'pharmacy_staff', 'delivery'],
        default: 'pharmacy_staff'
    },
    pharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy'
    },
    status: {
        type: String,
        enum: ['pending', 'waiting', 'active', 'inactive', 'suspended'],
        default: 'pending'
    },
    language: {
        type: String,
        enum: ['en', 'ar'],
        default: 'en'
    },
    lastLogin: {
        type: Date
    },
    refreshToken: {
        type: String
    },
    passwordResetToken: {
        type: String
    },
    passwordResetExpires: {
        type: Date
    },
    pendingUpdate: {
        type: Object,
        default: null
    }
}, {
    timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function(next) {
    if (!this.isModified('hashedPassword')) return next();
    
    try {
        const salt = await bcrypt.genSalt(10);
        this.hashedPassword = await bcrypt.hash(this.hashedPassword, salt);
        next();
    } catch (error) {
        next(error);
    }
});

// Method to compare passwords
userSchema.methods.comparePassword = async function(candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.hashedPassword);
};

// Don't return sensitive data
userSchema.methods.toJSON = function() {
    const user = this.toObject();
    delete user.hashedPassword;
    delete user.refreshToken;
    delete user.passwordResetToken;
    delete user.passwordResetExpires;
    return user;
};

module.exports = mongoose.model('User', userSchema);
