const { Compensation, Pharmacy, BalanceHistory, User } = require('../models');
const { addNotificationJob } = require('../utils/queueManager');
const { sendToUser } = require('../utils/pusherManager');
const auditService = require('../services/auditService');
const mongoose = require('mongoose');
const { round2 } = require('../utils/mathUtils');

// @desc    Add compensation to pharmacy
// @route   POST /api/compensation
// @access  Admin only
exports.createCompensation = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { pharmacyId, amount, description } = req.body;

        // Validation
        if (!pharmacyId || !amount || !description) {
            throw { message: 'Please provide all fields: pharmacyId, amount, description', code: 400 };
        }

        if (amount <= 0) {
            throw { message: 'Amount must be greater than 0', code: 400 };
        }

        const pharmacy = await Pharmacy.findById(pharmacyId).session(session);
        if (!pharmacy) {
            throw { message: 'Pharmacy not found', code: 404 };
        }

        // Create Compensation record
        const compensation = await Compensation.create([{
            pharmacy: pharmacyId,
            admin: req.user._id,
            amount,
            description
        }], { session });

        // Update target pharmacy balance
        const prevBalance = pharmacy.balance;
        pharmacy.balance = round2(pharmacy.balance + amount);
        await pharmacy.save({ session });

        // Trigger Real-time Balance Update for target pharmacy
        const users = await User.find({ pharmacy: pharmacyId });
        for (const u of users) {
            await sendToUser(u._id.toString(), 'balanceUpdate', {
                balance: pharmacy.balance
            });
        }

        // Create target pharmacy history records
        await BalanceHistory.create([{
            pharmacy: pharmacyId,
            type: 'compensation',
            amount: amount,
            previousBalance: prevBalance,
            newBalance: pharmacy.balance,
            relatedEntity: compensation[0]._id,
            relatedEntityType: 'Compensation',
            description: `Compensation added: ${description}`,
            description_ar: `تم إضافة تعويض: ${description}`
        }], { session });

        // Notify Pharmacy Owner
        const owner = await User.findOne({ pharmacy: pharmacyId }).session(session);
        if (owner) {
            setImmediate(() => addNotificationJob(
                owner._id.toString(),
                'system',
                `You have received a compensation of ${amount} coins. Reason: ${description}`,
                {
                    priority: 'high', // System notifs are high priority
                    relatedEntity: compensation[0]._id,
                    relatedEntityType: 'Compensation'
                },
                `لقد تلقيت تعويضاً بقيمة ${amount} قطعة. السبب: ${description}`
            ));
        }

        await auditService.logAction({
            user: req.user._id,
            action: 'CREATE',
            entityType: 'Compensation',
            entityId: compensation[0]._id,
            changes: { amount, description, pharmacyId }
        }, req);

        await session.commitTransaction();

        res.status(201).json({
            success: true,
            message: 'Compensation added successfully',
            data: compensation[0]
        });

    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Get compensations for a pharmacy
// @route   GET /api/compensation/:pharmacyId
// @access  Admin only
exports.getCompensations = async (req, res) => {
    try {
        const compensations = await Compensation.find({ pharmacy: req.params.pharmacyId })
            .populate('admin', 'name email')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: compensations.length,
            data: compensations
        });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

exports.updateCompensation = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { amount, description } = req.body;
        const compensation = await Compensation.findById(req.params.id).session(session);

        if (!compensation) {
            throw { message: 'Compensation not found', code: 404 };
        }

        if (amount !== undefined && amount <= 0) {
            throw { message: 'Amount must be greater than 0', code: 400 };
        }

        const oldAmount = compensation.amount;
        const pharmacy = await Pharmacy.findById(compensation.pharmacy).session(session);
        if (!pharmacy) {
            throw { message: 'Target pharmacy not found', code: 404 };
        }

        // 1. Revert target pharmacy of oldAmount
        pharmacy.balance = round2(pharmacy.balance - oldAmount);

        // 2. Set fields
        if (amount !== undefined) compensation.amount = amount;
        if (description) compensation.description = description;

        await compensation.save({ session });

        // 3. Apply new effects
        const newAmount = compensation.amount;

        const prevBalance = pharmacy.balance;
        pharmacy.balance = round2(pharmacy.balance + newAmount);
        await pharmacy.save({ session });

        // 4. Create history records
        // Target pharmacy
        await BalanceHistory.create([{
            pharmacy: pharmacy._id,
            type: 'compensation',
            amount: newAmount - oldAmount,
            previousBalance: prevBalance,
            newBalance: pharmacy.balance,
            relatedEntity: compensation._id,
            relatedEntityType: 'Compensation',
            description: `Compensation updated: ${oldAmount} -> ${newAmount}. Reason: ${description}`,
            description_ar: `تم تحديث التعويض: ${oldAmount} -> ${newAmount}. السبب: ${description}`
        }], { session });

        // Notify Pharmacy Owner
        const owner = await User.findOne({ pharmacy: compensation.pharmacy }).session(session);
        if (owner) {
            setImmediate(() => addNotificationJob(
                owner._id.toString(),
                'system',
                `Compensation updated: ${oldAmount} -> ${newAmount}. Reason: ${description}`,
                {
                    priority: 'high',
                    relatedEntity: compensation._id,
                    relatedEntityType: 'Compensation'
                },
                `تم تحديث التعويض: ${oldAmount} -> ${newAmount}. السبب: ${description}`
            ));
        }

        // Trigger Real-time Balance Update for target pharmacy
        const users = await User.find({ pharmacy: pharmacy._id });
        for (const u of users) {
            await sendToUser(u._id.toString(), 'balanceUpdate', {
                balance: pharmacy.balance
            });
        }

        await auditService.logAction({
            user: req.user._id,
            action: 'UPDATE',
            entityType: 'Compensation',
            entityId: compensation._id,
            changes: { amount, oldAmount, description }
        }, req);

        await session.commitTransaction();

        res.status(200).json({ success: true, data: compensation });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Delete compensation
// @route   DELETE /api/compensation/:id
// @access  Admin only
exports.deleteCompensation = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const compensation = await Compensation.findById(req.params.id).session(session);

        if (!compensation) {
            throw { message: 'Compensation not found', code: 404 };
        }

        const pharmacy = await Pharmacy.findById(compensation.pharmacy).session(session);

        const prevBalance = pharmacy.balance;
        // Revert Balance from target pharmacy
        pharmacy.balance = round2(pharmacy.balance - compensation.amount);
        await pharmacy.save({ session });

        // Log target pharmacy History
        await BalanceHistory.create([{
            pharmacy: pharmacy._id,
            type: 'compensation',
            amount: -compensation.amount,
            previousBalance: prevBalance,
            newBalance: pharmacy.balance,
            relatedEntity: compensation._id,
            relatedEntityType: 'Compensation',
            description: `Compensation reverted/deleted: -${compensation.amount}`,
            description_ar: `تم عكس/حذف التعويض: -${compensation.amount}`
        }], { session });

        // Delete Compensation
        await compensation.deleteOne({ session });

        // Trigger Real-time Balance Update for all pharmacy users
        const users = await User.find({ pharmacy: pharmacy._id });
        for (const u of users) {
            await sendToUser(u._id.toString(), 'balanceUpdate', {
                balance: pharmacy.balance
            });
        }

        await auditService.logAction({
            user: req.user._id,
            action: 'DELETE',
            entityType: 'Compensation',
            entityId: compensation._id,
            changes: { amount: compensation.amount, description: compensation.description }
        }, req);

        await session.commitTransaction();

        res.status(200).json({ success: true, message: 'Compensation deleted and balances reverted' });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};
