const { User, Pharmacy } = require('../models');
const { deleteFiles } = require('../utils/fileHelper');
const { addNotificationJob } = require('../utils/queueManager');

// @desc    Get users waiting for approval
// @route   GET /api/admin/waiting-users
// @access  Admin
exports.getWaitingUsers = async (req, res) => {
    try {
        const users = await User.find({ status: 'waiting' }).populate('pharmacy');
        res.status(200).json({ success: true, count: users.length, data: users });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get active users
// @route   GET /api/admin/active-users
// @access  Admin
exports.getActiveUsers = async (req, res) => {
    try {
        const users = await User.find({ status: 'active' }).populate('pharmacy');
        res.status(200).json({ success: true, count: users.length, data: users });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Approve or Reject a user/pharmacy
// @route   PUT /api/admin/review-user/:id
// @access  Admin
exports.reviewUser = async (req, res) => {
    try {
        const { status } = req.body; // 'active' or 'rejected'
        if (!['active', 'rejected'].includes(status)) {
            return res.status(400).json({ success: false, message: 'Invalid status' });
        }

        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        if (status === 'rejected') {
            if (user.pharmacy) {
                const pharmacy = await Pharmacy.findById(user.pharmacy);
                if (pharmacy) {
                    // Collect all possible file paths to delete
                    const filesToDelete = [
                        pharmacy.pharmacistCard,
                        pharmacy.commercialRegistry,
                        pharmacy.taxCard,
                        pharmacy.pharmacyLicense,
                        pharmacy.signImage
                    ].filter(Boolean);

                    // Delete physical files
                    deleteFiles(filesToDelete);

                    await pharmacy.deleteOne();
                }

                // Push Notification to user
                await addNotificationJob(
                    user._id.toString(),
                    'system',
                    'Your pharmacy registration request was rejected. You can now re-submit your documents.',
                    { priority: 'high' }
                );

                // Reset user to pending status and remove pharmacy link
                user.pharmacy = undefined;
                user.status = 'pending';
            }
        } else {
            // Approving logic (status === 'active')
            user.status = status;
            if (user.pharmacy) {
                const pharmacy = await Pharmacy.findById(user.pharmacy);
                if (pharmacy) {
                    pharmacy.status = status;
                    pharmacy.verified = true;
                    await pharmacy.save();

                    // Push Notification to user
                    await addNotificationJob(
                        user._id.toString(),
                        'system',
                        'Congratulations! Your pharmacy has been approved.',
                        { 
                            priority: 'high',
                            relatedEntity: pharmacy._id,
                            relatedEntityType: 'Pharmacy'
                        }
                    );
                }
            }
        }

        await user.save();
        res.status(200).json({ success: true, data: user });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get all pharmacies with owners
// @route   GET /api/admin/pharmacies
// @access  Admin
exports.getAllPharmacies = async (req, res) => {
    try {
        // Find all pharmacies and find their linked users
        const pharmacies = await Pharmacy.find();
        const data = [];

        for (const ph of pharmacies) {
            const owner = await User.findOne({ pharmacy: ph._id });
            data.push({
                ...ph.toObject(),
                owner: owner ? { _id: owner._id, name: owner.name, email: owner.email, phone: owner.phone } : null
            });
        }

        res.status(200).json({ success: true, count: data.length, data });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
