const { User, Pharmacy, StockExcess, ProductSuggestion, AppSuggestion, DeliveryRequest } = require('../models');
const { deleteFiles } = require('../utils/fileHelper');
const { addNotificationJob } = require('../utils/queueManager');

// @desc    Get users waiting for approval
// @route   GET /api/admin/waiting-users
// @access  Admin
const getWaitingUsers = async (req, res) => {
    try {
        const users = await User.find({ status: 'waiting' }).populate('pharmacy').sort({ name: 1 });
        res.status(200).json({ success: true, count: users.length, data: users });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get active users
// @route   GET /api/admin/active-users
// @access  Admin
const getActiveUsers = async (req, res) => {
    try {
        const users = await User.find({ status: 'active' }).populate('pharmacy').sort({ name: 1 });
        res.status(200).json({ success: true, count: users.length, data: users });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Approve or Reject a user/pharmacy
// @route   PUT /api/admin/review-user/:id
// @access  Admin
const reviewUser = async (req, res) => {
    try {
        const { status } = req.body; 
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
                    const filesToDelete = [
                        pharmacy.pharmacistCard,
                        pharmacy.commercialRegistry,
                        pharmacy.taxCard,
                        pharmacy.pharmacyLicense,
                        pharmacy.signImage
                    ].filter(Boolean);

                    deleteFiles(filesToDelete);
                    await pharmacy.deleteOne();
                }

                await addNotificationJob(
                    user._id.toString(),
                    'system',
                    `Your pharmacy "${pharmacy?.name || 'registration'}" registration request was rejected. You can now re-submit your documents.`,
                    { priority: 'high' }
                );

                user.pharmacy = undefined;
                user.status = 'pending';
            }
        } else {
            user.status = status;
            if (user.pharmacy) {
                const pharmacy = await Pharmacy.findById(user.pharmacy);
                if (pharmacy) {
                    pharmacy.status = status;
                    pharmacy.verified = true;
                    await pharmacy.save();

                    await addNotificationJob(
                        user._id.toString(),
                        'system',
                        `Congratulations! Your pharmacy "${pharmacy.name}" has been approved.`,
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
const getAllPharmacies = async (req, res) => {
    try {
        const pharmacies = await Pharmacy.find().sort({ name: 1 });
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

// @desc    Get counts of pending items for dashboard
// @route   GET /api/admin/pending-counts
// @access  Admin
const getPendingCounts = async (req, res) => {
    try {
        const { Order } = require('../models');
        const waitingUsers = await User.countDocuments({ status: 'waiting' });
        const pendingExcesses = await StockExcess.countDocuments({ status: 'pending' });
        const pendingSuggestions = await ProductSuggestion.countDocuments({ status: 'pending' });
        const appSuggestions = await AppSuggestion.countDocuments({ seen: false });
        const deliveryRequests = await DeliveryRequest.countDocuments({ status: 'pending' });
        const pendingAccountUpdates = await User.countDocuments({ pendingUpdate: { $ne: null } });
        const pendingOrders = await Order.countDocuments({ status: { $in: ['pending', 'partially_fulfilled'] } });

        res.status(200).json({
            success: true,
            data: {
                waitingUsers,
                pendingExcesses,
                pendingSuggestions,
                appSuggestions,
                deliveryRequests,
                pendingAccountUpdates,
                pendingOrders
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Suspend or Reactivate a user
// @route   PUT /api/admin/suspend-user/:id
// @access  Admin
const suspendUser = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }
        // Toggle between active and suspended
        user.status = user.status === 'suspended' ? 'active' : 'suspended';
        await user.save();
        res.status(200).json({ success: true, data: user });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Reset a user's password to "00000000"
// @route   PUT /api/admin/reset-password/:id
// @access  Admin
const resetUserPassword = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        user.hashedPassword = '00000000';
        await user.save();

        res.status(200).json({ success: true, message: 'Password reset to 00000000 successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get users with pending updates
// @route   GET /api/admin/pending-updates
// @access  Admin
const getUsersWithPendingUpdates = async (req, res) => {
    try {
        const users = await User.find({ pendingUpdate: { $ne: null } }).populate('pharmacy').sort({ name: 1 });
        res.status(200).json({ success: true, count: users.length, data: users });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Review (Approve/Reject) account update
// @route   PUT /api/admin/review-update/:id
// @access  Admin
const reviewUpdateData = async (req, res) => {
    try {
        const { action } = req.body; // 'approve' or 'reject'
        const user = await User.findById(req.params.id).populate('pharmacy');

        if (!user || !user.pendingUpdate) {
            return res.status(404).json({ success: false, message: 'Pending update not found' });
        }

        if (action === 'approve') {
            const updates = user.pendingUpdate;
            
            // Apply updates to user
            if (updates.name) user.name = updates.name;
            if (updates.email) user.email = updates.email.toLowerCase();
            if (updates.phone) user.phone = updates.phone;

            // Apply updates to pharmacy if applicable
            if (updates.pharmacy && user.pharmacy) {
                const pharmacy = await Pharmacy.findById(user.pharmacy);
                if (pharmacy) {
                    if (updates.pharmacy.name) pharmacy.name = updates.pharmacy.name;
                    if (updates.pharmacy.phone) pharmacy.phone = updates.pharmacy.phone;
                    if (updates.pharmacy.address) pharmacy.address = updates.pharmacy.address;
                    await pharmacy.save();
                }
            }
            
            await addNotificationJob(
                user._id.toString(),
                'system',
                'Your profile update request has been approved and applied.'
            );
        } else {
            await addNotificationJob(
                user._id.toString(),
                'system',
                'Your profile update request was rejected.'
            );
        }

        // Always clear the pendingUpdate
        user.pendingUpdate = null;
        await user.save();

        res.status(200).json({ success: true, data: user });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Create a delivery user manually
// @route   POST /api/admin/create-delivery
// @access  Admin
const createDeliveryUser = async (req, res) => {
    try {
        const { name, email, phone, password } = req.body;

        const userExists = await User.findOne({ 
            $or: [{ email: email.toLowerCase() }, { phone }] 
        });

        if (userExists) {
            return res.status(400).json({ 
                success: false, 
                message: 'User already exists with this email or phone' 
            });
        }

        const user = await User.create({
            name,
            email: email.toLowerCase(),
            phone,
            hashedPassword: password,
            role: 'delivery',
            status: 'active' // Manual admin creation defaults to active
        });

        res.status(201).json({ success: true, data: user });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

module.exports = {
    getWaitingUsers,
    getActiveUsers,
    reviewUser,
    getAllPharmacies,
    getPendingCounts,
    createDeliveryUser,
    suspendUser,
    resetUserPassword,
    getUsersWithPendingUpdates,
    reviewUpdateData
};
