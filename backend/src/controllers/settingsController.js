const Settings = require('../models/Settings');

// @desc    Get system settings
// @route   GET /api/settings
// @access  Admin
exports.getSettings = async (req, res) => {
    try {
        const settings = await Settings.getSettings();
        res.status(200).json({ success: true, data: settings });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Update system settings
// @route   PUT /api/settings
// @access  Admin
exports.updateSettings = async (req, res) => {
    try {
        const { minimumCommission, shortageCommission, shortageSellerReward } = req.body;
        
        const settings = await Settings.getSettings();

        if (minimumCommission !== undefined) {
            if (minimumCommission <= 0 || minimumCommission >= 20) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'Minimum Commission must be between 0 and 20' 
                });
            }
            settings.minimumCommission = minimumCommission;
        }

        if (shortageCommission !== undefined) {
            if (shortageCommission < 0) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'Shortage Commission cannot be negative' 
                });
            }
            settings.shortageCommission = shortageCommission;
        }

        if (shortageSellerReward !== undefined) {
            if (shortageSellerReward < 0) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'Shortage Seller Reward cannot be negative' 
                });
            }
            settings.shortageSellerReward = shortageSellerReward;
        }

        await settings.save();
        res.status(200).json({ success: true, data: settings });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
