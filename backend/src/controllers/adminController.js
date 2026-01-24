const { User, Pharmacy, StockExcess, ProductSuggestion, AppSuggestion, DeliveryRequest } = require('../models');
const { deleteFiles } = require('../utils/fileHelper');
const { addNotificationJob } = require('../utils/queueManager');

// @desc    Get users waiting for approval
// @route   GET /api/admin/waiting-users
// @access  Admin
const getWaitingUsers = async (req, res) => {
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
const getActiveUsers = async (req, res) => {
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

// @desc    Get counts of pending items for dashboard
// @route   GET /api/admin/pending-counts
// @access  Admin
const getPendingCounts = async (req, res) => {
    try {
        const waitingUsers = await User.countDocuments({ status: 'waiting' });
        const pendingExcesses = await StockExcess.countDocuments({ status: 'pending' });
        const pendingSuggestions = await ProductSuggestion.countDocuments({ status: 'pending' });
        const appSuggestions = await AppSuggestion.countDocuments({ seen: false });
        const deliveryRequests = await DeliveryRequest.countDocuments({ status: 'pending' });

        res.status(200).json({
            success: true,
            data: {
                waitingUsers,
                pendingExcesses,
                pendingSuggestions,
                appSuggestions,
                deliveryRequests
            }
        });
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
            status: 'waiting'
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
    createDeliveryUser
};
