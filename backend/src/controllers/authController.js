const authService = require('../services/authService');
const { User } = require('../models');
const { deleteFiles } = require('../utils/fileHelper');
const cloudinary = require('cloudinary').v2;
const fs = require('fs');
const mongoose = require('mongoose');

// Configure Cloudinary
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

// @desc    Register a new user
exports.register = async (req, res) => {
    try {
        const result = await authService.registerUser(req.body, req);
        res.status(201).json({ success: true, data: result });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

// @desc    Authenticate user & get token
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;
        const result = await authService.loginUser(email, password, req);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(401).json({ success: false, message: error.message });
    }
};

// @desc    Get current user profile
exports.getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user._id).populate('pharmacy');
        if (user) {
            res.json({ success: true, data: user });
        } else {
            res.status(404).json({ success: false, message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Google/Social Login
exports.socialLogin = async (req, res) => {
    try {
        const result = await authService.socialLogin(req.body, req);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Link pharmacy to a pending user
exports.linkPharmacy = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { 
            name, ownerName, nationalId, phone, email,
            address, location 
        } = req.body;

        let parsedLocation = location;
        if (typeof parsedLocation === 'string') {
            try { parsedLocation = JSON.parse(parsedLocation); } catch (e) {}
        }

        const cleanup = () => {
             if (req.files) {
                 const files = Object.values(req.files).flat().map(f => f.path);
                 if (files.length > 0) deleteFiles(files);
             }
        };

        if (!req.files || !req.files['pharmacistCard'] || !req.files['commercialRegistry'] || !req.files['taxCard'] || !req.files['pharmacyLicense']) {
            cleanup();
            throw new Error('All 4 documents are required');
        }

        const useCloudinary = process.env.USE_CLOUDINARY === 'true';
        const fileKeys = ['pharmacistCard', 'commercialRegistry', 'taxCard', 'pharmacyLicense'];
        const uploadResults = {};

        if (useCloudinary) {
            const uploadToCloudinary = async (filePath) => {
                return await cloudinary.uploader.upload(filePath, {
                    folder: 'pharmacy_docs',
                    resource_type: 'image'
                });
            };

            for (const key of fileKeys) {
                const file = req.files[key][0];
                const result = await uploadToCloudinary(file.path);
                uploadResults[key] = result.secure_url;
                fs.unlinkSync(file.path);
            }
        } else {
            for (const key of fileKeys) {
                uploadResults[key] = req.files[key][0].path;
            }
        }

        const result = await authService.linkPharmacy(req.user._id, {
            name, ownerName, nationalId, 
            phone: phone || req.user.phone,
            email: email || req.user.email,
            pharmacistCard: uploadResults.pharmacistCard,
            commercialRegistry: uploadResults.commercialRegistry,
            taxCard: uploadResults.taxCard,
            pharmacyLicense: uploadResults.pharmacyLicense,
            address,
            location: parsedLocation
        }, session, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, message: 'Linked successfully', data: result });
    } catch (error) {
        await session.abortTransaction();
        res.status(500).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// @desc    Request a profile update
exports.requestProfileUpdate = async (req, res) => {
    try {
        const result = await authService.updateUserDetail(req.user._id, req.body, req);
        res.status(200).json({ success: true, message: 'Update request sent', data: result });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Update user preferences (language, etc.)
exports.updatePreferences = async (req, res) => {
    try {
        const { language } = req.body;
        const user = await User.findById(req.user._id);
        
        if (language) user.language = language;
        
        await user.save();
        res.status(200).json({ success: true, data: user });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Change user password
exports.changePassword = async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;
        await authService.changePassword(req.user._id, oldPassword, newPassword, req);
        res.status(200).json({ success: true, message: 'Password changed successfully' });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
