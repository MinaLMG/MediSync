const { User, Pharmacy, StockExcess, ProductSuggestion, AppSuggestion, DeliveryRequest, Transaction, StockShortage } = require('../models');
const mongoose = require('mongoose');
const { deleteFiles } = require('../utils/fileHelper');
const { addNotificationJob } = require('../utils/queueManager');
const auditService = require('../services/auditService');

// @desc    Get users waiting for approval
// @route   GET /api/admin/waiting-users
// @access  Admin
const getWaitingUsers = async (req, res) => {
    try {
        const users = await User.find({ status: 'waiting' }).populate('pharmacy').sort({ createdAt: -1 });
        res.status(200).json({ success: true, count: users.length, data: users });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Get active users
// @route   GET /api/admin/active-users
// @access  Admin
const getActiveUsers = async (req, res) => {
    try {
        const users = await User.find({ status: 'active' }).populate('pharmacy').sort({ createdAt: -1 });
        res.status(200).json({ success: true, count: users.length, data: users });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Approve or Reject a user/pharmacy
// @route   PUT /api/admin/review-user/:id
// @access  Admin
const reviewUser = async (req, res) => {
    const mongoose = require('mongoose');
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { status } = req.body;
        if (!['active', 'rejected'].includes(status)) {
            throw { message: 'Invalid status', code: 400 };
        }

        const user = await User.findById(req.params.id).session(session);
        if (!user) {
            throw { message: 'User not found', code: 404 };
        }

        if (user.status === status && status !== 'rejected') {
            await session.commitTransaction();
            return res.status(200).json({ success: true, data: user });
        }

        const oldStatus = user.status;

        if (status === 'rejected') {
            if (user.pharmacy) {
                const pharmacy = await Pharmacy.findById(user.pharmacy).session(session);
                if (pharmacy) {
                    const filesToDelete = [
                        pharmacy.pharmacistCard,
                        pharmacy.commercialRegistry,
                        pharmacy.taxCard,
                        pharmacy.pharmacyLicense,
                        pharmacy.signImage
                    ].filter(Boolean);

                    deleteFiles(filesToDelete);
                    await pharmacy.deleteOne({ session });

                    setImmediate(() => addNotificationJob(
                        user._id.toString(),
                        'system',
                        `Your pharmacy "${pharmacy?.name || 'registration'}" registration request was rejected. You can now re-submit your documents.`,
                        { priority: 'high' },
                        `صيدلية "${pharmacy?.name || 'registration'}" طلب التسجيل تم رفضه. يمكنك الآن إعادة تقديم المستندات.`
                    ));
                }

                user.pharmacy = undefined;
                user.status = 'pending';
            }
        } else {
            user.status = status;
            if (user.pharmacy) {
                const pharmacy = await Pharmacy.findById(user.pharmacy).session(session);
                if (pharmacy) {
                    pharmacy.status = status;
                    pharmacy.verified = true;
                    await pharmacy.save({ session });

                    setImmediate(() => addNotificationJob(
                        user._id.toString(),
                        'system',
                        `Congratulations! Your pharmacy "${pharmacy.name}" has been approved.`,
                        {
                            priority: 'high',
                            relatedEntity: pharmacy._id,
                            relatedEntityType: 'Pharmacy'
                        }, `الصيدلية "${pharmacy.name}" تم الموافقة عليها.`
                    ));
                }
            }
        }
        await user.save({ session });

        await auditService.logAction({
            user: req.user._id,
            action: status === 'active' ? 'APPROVE' : 'REJECT',
            entityType: 'User',
            entityId: user._id,
            changes: { oldStatus, status }
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, data: user });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Get all pharmacies with owners
// @route   GET /api/admin/pharmacies
// @access  Admin
const getAllPharmacies = async (req, res) => {
    try {
        const pharmacies = await Pharmacy.find().sort({ createdAt: -1 });
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
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
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
        const activeTransactions = await Transaction.countDocuments({ status: { $in: ['pending', 'accepted'] } });

        res.status(200).json({
            success: true,
            data: {
                waitingUsers,
                pendingExcesses,
                pendingSuggestions,
                appSuggestions,
                deliveryRequests,
                pendingAccountUpdates,
                pendingOrders,
                activeTransactions
            }
        });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Suspend or Reactivate a user
// @route   PUT /api/admin/suspend-user/:id
// @access  Admin
const suspendUser = async (req, res) => {
    const mongoose = require('mongoose');
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const user = await User.findById(req.params.id).session(session);
        if (!user) {
            throw { message: 'User not found', code: 404 };
        }

        const oldStatus = user.status;
        const newStatus = oldStatus === 'suspended' ? 'active' : 'suspended';

        user.status = newStatus;
        await user.save({ session });

        await auditService.logAction({
            user: req.user._id,
            action: 'UPDATE',
            entityType: 'User',
            entityId: user._id,
            changes: { status: newStatus, oldStatus }
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, data: user });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Reset a user's password to "00000000"
// @route   PUT /api/admin/reset-password/:id
// @access  Admin
const resetUserPassword = async (req, res) => {
    const mongoose = require('mongoose');
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const user = await User.findById(req.params.id).session(session);
        if (!user) {
            throw { message: 'User not found', code: 404 };
        }

        user.hashedPassword = '00000000';
        await user.save({ session });

        await auditService.logAction({
            user: req.user._id,
            action: 'UPDATE',
            entityType: 'User',
            entityId: user._id,
            changes: { passwordReset: true }
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, message: 'Password reset to 00000000 successfully' });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Get users with pending updates
// @route   GET /api/admin/pending-updates
// @access  Admin
const getUsersWithPendingUpdates = async (req, res) => {
    try {
        const users = await User.find({ pendingUpdate: { $ne: null } }).populate('pharmacy').sort({ updatedAt: -1 });
        res.status(200).json({ success: true, count: users.length, data: users });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Review (Approve/Reject) account update
// @route   PUT /api/admin/review-update/:id
// @access  Admin
const reviewUpdateData = async (req, res) => {
    const mongoose = require('mongoose');
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { action } = req.body; // 'approve' or 'reject'
        const user = await User.findById(req.params.id).populate('pharmacy').session(session);

        if (!user || !user.pendingUpdate) {
            throw { message: 'Pending update not found', code: 404 };
        }

        let changes = { action };

        if (action === 'approve') {
            const updates = user.pendingUpdate;

            // Apply updates to user
            if (updates.name) {
                changes.userName = { old: user.name, new: updates.name };
                user.name = updates.name;
            }
            if (updates.email) {
                changes.userEmail = { old: user.email, new: updates.email.toLowerCase() };
                user.email = updates.email.toLowerCase();
            }
            if (updates.phone) {
                changes.userPhone = { old: user.phone, new: updates.phone };
                user.phone = updates.phone;
            }

            // Apply updates to pharmacy if applicable
            if (updates.pharmacy && user.pharmacy) {
                const pharmacy = await Pharmacy.findById(user.pharmacy).session(session);
                if (pharmacy) {
                    if (updates.pharmacy.name) {
                        changes.pharmacyName = { old: pharmacy.name, new: updates.pharmacy.name };
                        pharmacy.name = updates.pharmacy.name;
                    }
                    if (updates.pharmacy.phone) {
                        changes.pharmacyPhone = { old: pharmacy.phone, new: updates.pharmacy.phone };
                        pharmacy.phone = updates.pharmacy.phone;
                    }
                    if (updates.pharmacy.address) {
                        changes.pharmacyAddress = { old: pharmacy.address, new: updates.pharmacy.address };
                        pharmacy.address = updates.pharmacy.address;
                    }
                    await pharmacy.save({ session });
                }
            }

            setImmediate(() => addNotificationJob(
                user._id.toString(),
                'system',
                'Your profile update request has been approved and applied.',
                { priority: 'high' },
                `تم الموافقة على طلب تحديث ملفك الشخصي`
            ));
        } else {
            setImmediate(() => addNotificationJob(
                user._id.toString(),
                'system',
                'Your profile update request was rejected.',
                { priority: 'high' },
                `تم رفض طلب تحديث ملفك الشخصي`
            ));
        }

        // Always clear the pendingUpdate
        user.pendingUpdate = null;
        await user.save({ session });

        await auditService.logAction({
            user: req.user._id,
            action: 'UPDATE',
            entityType: 'User',
            entityId: user._id,
            changes
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, data: user });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Create a delivery user manually
// @route   POST /api/admin/create-delivery
// @access  Admin
const createDeliveryUser = async (req, res) => {
    const mongoose = require('mongoose');
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { name, email, phone, password } = req.body;

        if (!name || !email || !phone || !password) {
            throw { message: 'All fields are required', code: 400 };
        }

        const userExists = await User.findOne({
            $or: [{ email: email.toLowerCase() }, { phone }]
        }).session(session);

        if (userExists) {
            throw { message: 'User already exists with this email or phone', code: 409 };
        }

        const user = await User.create([{
            name,
            email: email.toLowerCase(),
            phone,
            hashedPassword: password,
            role: 'delivery',
            status: 'active'
        }], { session });

        await auditService.logAction({
            user: req.user._id,
            action: 'CREATE',
            entityType: 'User',
            entityId: user[0]._id,
            changes: { name, email, role: 'delivery' }
        }, req);

        await session.commitTransaction();
        res.status(201).json({ success: true, data: user[0] });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Get single pharmacy detail (for admin simulation)
// @route   GET /api/admin/pharmacies/:id
// @access  Admin
const getPharmacyDetail = async (req, res) => {
    try {
        const ph = await Pharmacy.findById(req.params.id);
        if (!ph) {
            return res.status(404).json({ success: false, message: 'Pharmacy not found' });
        }
        const owner = await User.findOne({ pharmacy: ph._id });
        res.status(200).json({
            success: true,
            data: {
                ...ph.toObject(),
                owner: owner ? { _id: owner._id, name: owner.name, email: owner.email, phone: owner.phone } : null
            }
        });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Get all hub pharmacies
// @route   GET /api/admin/hubs
// @access  Admin
const getHubs = async (req, res) => {
    try {
        const hubs = await Pharmacy.find({ isHub: true }).sort({ name: 1 });
        res.status(200).json({ success: true, count: hubs.length, data: hubs });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Get pharmacies summary with financial stats
// @route   GET /api/admin/pharmacies-summary
// @access  Admin
const getPharmaciesSummary = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;

        // Build date filter for transactions
        const dateFilter = {};
        if (startDate) dateFilter.$gte = new Date(startDate);
        if (endDate) {
            const end = new Date(endDate);
            end.setHours(23, 59, 59, 999);
            dateFilter.$lte = end;
        }
        const hasDateFilter = Object.keys(dateFilter).length > 0;

        // Fetch all active pharmacies
        const pharmacies = await Pharmacy.find({ status: 'active' }).sort({ name: 1 }).lean();

        // Pre-compute: current excess value per pharmacy
        const excessAgg = await StockExcess.aggregate([
            { $match: { status: { $in: ['available', 'partially_fulfilled'] }, remainingQuantity: { $gt: 0 } } },
            {
                $group: {
                    _id: '$pharmacy',
                    excessValue: { $sum: { $multiply: ['$remainingQuantity', '$selectedPrice'] } }
                }
            }
        ]);
        const excessMap = {};
        excessAgg.forEach(e => { excessMap[e._id.toString()] = e.excessValue; });

        // Pre-compute: transactions as buyer per pharmacy (via shortage's pharmacy)
        const txMatchBuyer = hasDateFilter
            ? { status: 'completed', 'stockShortage.balanceEffect': { $exists: true }, createdAt: dateFilter }
            : { status: 'completed', 'stockShortage.balanceEffect': { $exists: true } };

        // Aggregate buyer transactions — join shortage to get pharmacy
        const buyerAgg = await Transaction.aggregate([
            { $match: txMatchBuyer },
            {
                $lookup: {
                    from: 'stockshortages',
                    localField: 'stockShortage.shortage',
                    foreignField: '_id',
                    as: 'shortageDoc'
                }
            },
            { $unwind: '$shortageDoc' },
            {
                $group: {
                    _id: '$shortageDoc.pharmacy',
                    totalBuyerValue: { $sum: '$totalAmount' },
                    lastTransaction: { $max: '$createdAt' }
                }
            }
        ]);
        const buyerMap = {};
        buyerAgg.forEach(b => {
            buyerMap[b._id.toString()] = {
                totalBuyerValue: b.totalBuyerValue,
                lastTransaction: b.lastTransaction
            };
        });

        // Aggregate seller transactions — via stockExcessSources
        const txMatchSeller = hasDateFilter
            ? { status: 'completed', createdAt: dateFilter }
            : { status: 'completed' };

        const sellerAgg = await Transaction.aggregate([
            { $match: txMatchSeller },
            { $unwind: '$stockExcessSources' },
            {
                $lookup: {
                    from: 'stockexcesses',
                    localField: 'stockExcessSources.stockExcess',
                    foreignField: '_id',
                    as: 'excessDoc'
                }
            },
            { $unwind: '$excessDoc' },
            {
                $group: {
                    _id: '$excessDoc.pharmacy',
                    totalSellerValue: { $sum: '$stockExcessSources.totalAmount' },
                    lastTransaction: { $max: '$createdAt' }
                }
            }
        ]);
        const sellerMap = {};
        sellerAgg.forEach(s => {
            sellerMap[s._id.toString()] = {
                totalSellerValue: s.totalSellerValue,
                lastTransaction: s.lastTransaction
            };
        });

        // Build summary
        const summary = pharmacies.map(ph => {
            const phId = ph._id.toString();
            const buyer = buyerMap[phId] || {};
            const seller = sellerMap[phId] || {};

            // Last transaction: max of buyer and seller dates
            let lastTx = null;
            if (buyer.lastTransaction && seller.lastTransaction) {
                lastTx = buyer.lastTransaction > seller.lastTransaction
                    ? buyer.lastTransaction
                    : seller.lastTransaction;
            } else {
                lastTx = buyer.lastTransaction || seller.lastTransaction || null;
            }

            const phBuyerValue = buyer.totalBuyerValue || 0;
            const phSellerValue = seller.totalSellerValue || 0;

            return {
                _id: ph._id,
                name: ph.name,
                isHub: ph.isHub || false,
                balance: ph.balance || 0,
                totalBuyerValue: phBuyerValue,
                totalSellerValue: phSellerValue,
                totalTransactionsValue: phBuyerValue + phSellerValue,
                currentExcessValue: excessMap[phId] || 0,
                lastTransactionDate: lastTx
            };
        });
        console.log('summary', summary)
        res.status(200).json({ success: true, data: summary });
    } catch (error) {
        console.error('[Error] getPharmaciesSummary failed:', error);
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

module.exports = {
    getWaitingUsers,
    getActiveUsers,
    reviewUser,
    getAllPharmacies,
    getPharmacyDetail,
    getPendingCounts,
    createDeliveryUser,
    suspendUser,
    resetUserPassword,
    getUsersWithPendingUpdates,
    reviewUpdateData,
    getHubs,
    getPharmaciesSummary
};
