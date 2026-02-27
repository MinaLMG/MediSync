const authService = require('../services/authService');
const { User } = require('../models');
const auditService = require('../services/auditService');
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

        await auditService.logAction({
            user: result._id,
            action: 'CREATE',
            entityType: 'User',
            entityId: result._id,
            changes: { email: result.email, role: result.role }
        }, req);

        res.status(201).json({ success: true, data: result });
    } catch (error) {
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Authenticate user & get token
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;
        const result = await authService.loginUser(email, password, req);

        await auditService.logAction({
            user: result._id,
            action: 'LOGIN',
            entityType: 'User',
            entityId: result._id
        }, req);

        res.json({ success: true, data: result });
    } catch (error) {
        res.status(error.code || 401).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Get current user profile
exports.getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user._id).populate('pharmacy');
        if (user) {
            res.json({ success: true, data: user });
        } else {
            throw { message: 'User not found', code: 404 };
        }
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Google/Social Login
exports.socialLogin = async (req, res) => {
    try {
        const result = await authService.socialLogin(req.body, req);

        await auditService.logAction({
            user: result._id,
            action: 'LOGIN_SOCIAL',
            entityType: 'User',
            entityId: result._id
        }, req);

        res.json({ success: true, data: result });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
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
            try { parsedLocation = JSON.parse(parsedLocation); } catch (e) { }
        }

        const cleanup = () => {
            if (req.files) {
                const files = Object.values(req.files).flat().map(f => f.path);
                if (files.length > 0) deleteFiles(files);
            }
        };

        if (!req.files || !req.files['pharmacistCard'] || !req.files['commercialRegistry'] || !req.files['taxCard'] || !req.files['pharmacyLicense']) {
            cleanup();
            throw { message: 'All 4 documents are required', code: 400 };
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

        await auditService.logAction({
            user: req.user._id,
            action: 'LINK_PHARMACY',
            entityType: 'Pharmacy',
            entityId: result.pharmacy._id
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, message: 'Linked successfully', data: result });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Request a profile update
exports.requestProfileUpdate = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const result = await authService.updateUserDetail(req.user._id, req.body, req, session);

        await auditService.logAction({
            user: req.user._id,
            action: 'UPDATE_REQUEST',
            entityType: 'User',
            entityId: req.user._id,
            changes: req.body
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, message: 'Update request sent', data: result });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Update user preferences (language, etc.)
exports.updatePreferences = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { language } = req.body;
        const user = await User.findById(req.user._id).session(session);

        if (language && user.language !== language) {
            const oldLanguage = user.language;
            user.language = language;
            await user.save({ session });

            await auditService.logAction({
                user: req.user._id,
                action: 'UPDATE_PREFERENCES',
                entityType: 'User',
                entityId: req.user._id,
                changes: { language, oldLanguage }
            }, req);
        }

        // Populate pharmacy before returning to avoid frontend crashes
        await user.populate('pharmacy');

        await session.commitTransaction();
        res.status(200).json({ success: true, data: user });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Change user password
exports.changePassword = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { oldPassword, newPassword } = req.body;
        await authService.changePassword(req.user._id, oldPassword, newPassword, req, session);

        await auditService.logAction({
            user: req.user._id,
            action: 'CHANGE_PASSWORD',
            entityType: 'User',
            entityId: req.user._id
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, message: 'Password changed successfully' });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};
