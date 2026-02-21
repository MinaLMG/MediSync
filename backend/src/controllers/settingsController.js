const Settings = require('../models/Settings');
const auditService = require('../services/auditService');

// @desc    Get system settings
// @route   GET /api/settings
// @access  Admin
exports.getSettings = async (req, res) => {
    try {
        const settings = await Settings.getSettings();
        res.status(200).json({ success: true, data: settings });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Update system settings
// @route   PUT /api/settings
// @access  Admin
exports.updateSettings = async (req, res) => {
    const mongoose = require('mongoose');
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { minimumCommission, shortageCommission, shortageSellerReward } = req.body;
        
        const settings = await Settings.getSettings(); // This internally uses findOne and creates if doesn't exist.
        // Re-fetch within session if needed, but getSettings() might not support it cleanly.
        // Let's manually find it for the session.
        const settingsDoc = await mongoose.model('Settings').findOne().session(session);

        let hasChanged = false;

        if (minimumCommission !== undefined && minimumCommission !== settingsDoc.minimumCommission) {
            if (minimumCommission <= 0 || minimumCommission >= 20) {
                throw { message: 'Minimum Commission must be between 0 and 20', code: 400 };
            }
            settingsDoc.minimumCommission = minimumCommission;
            hasChanged = true;
        }

        if (shortageCommission !== undefined && shortageCommission !== settingsDoc.shortageCommission) {
            if (shortageCommission < 0) {
                throw { message: 'Shortage Commission cannot be negative', code: 400 };
            }
            settingsDoc.shortageCommission = shortageCommission;
            hasChanged = true;
        }

        if (shortageSellerReward !== undefined && shortageSellerReward !== settingsDoc.shortageSellerReward) {
            if (shortageSellerReward < 0) {
                throw { message: 'Shortage Seller Reward cannot be negative', code: 400 };
            }
            settingsDoc.shortageSellerReward = shortageSellerReward;
            hasChanged = true;
        }

        if (hasChanged) {
            await settingsDoc.save({ session });
            await auditService.logAction({
                user: req.user._id,
                action: 'UPDATE',
                entityType: 'Settings',
                entityId: settingsDoc._id,
                changes: req.body
            }, req);
        }

        await session.commitTransaction();
        res.status(200).json({ success: true, data: settingsDoc });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};
