const { Compensation, Pharmacy, BalanceHistory, User } = require('../models');
const { addNotificationJob } = require('../utils/queueManager');
const { sendToUser } = require('../utils/pusherManager');
const mongoose = require('mongoose');

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
            throw new Error('Please provide all fields: pharmacyId, amount, description');
        }

        if (amount <= 0) {
            throw new Error('Amount must be greater than 0');
        }

        const pharmacy = await Pharmacy.findById(pharmacyId).session(session);
        if (!pharmacy) {
            throw new Error('Pharmacy not found');
        }

        // Create Compensation record
        const compensation = await Compensation.create([{
            pharmacy: pharmacyId,
            admin: req.user._id,
            amount,
            description
        }], { session });

        // Update Pharmacy Balance (Increase by amount)
        const previousBalance = pharmacy.balance;
        pharmacy.balance += amount;
        await pharmacy.save({ session });

        // Create Balance History
        await BalanceHistory.create([{
            pharmacy: pharmacyId,
            type: 'compensation',
            amount,
            previousBalance,
            newBalance: pharmacy.balance,
            relatedEntity: compensation[0]._id,
            relatedEntityType: 'Compensation',
            description: `Compensation added: ${description}`
        }], { session });

        // Notify Pharmacy Owner
        const owner = await User.findOne({ pharmacy: pharmacyId }).session(session);
        if (owner) {
            await addNotificationJob(
                owner._id.toString(),
                'system',
                `You have received a compensation of ${amount} coins. Reason: ${description}`,
                {
                    priority: 'high', // System notifs are high priority
                    relatedEntity: compensation[0]._id,
                    relatedEntityType: 'Compensation'
                }
            );
        }

        await session.commitTransaction();

        res.status(201).json({
            success: true,
            message: 'Compensation added successfully',
            data: compensation[0]
        });

    } catch (error) {
        await session.abortTransaction();
        console.error('Compensation Error:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
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
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Update compensation
// @route   PUT /api/compensation/:id
// @access  Admin only
exports.updateCompensation = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { amount, description } = req.body;
        const compensation = await Compensation.findById(req.params.id).session(session);

        if (!compensation) {
            throw new Error('Compensation not found');
        }

        if (amount <= 0) {
            throw new Error('Amount must be greater than 0');
        }

        const oldAmount = compensation.amount;
        const diff = amount - oldAmount;

        // Update Compensation
        compensation.amount = amount;
        compensation.description = description || compensation.description;
        await compensation.save({ session });

        // Update Pharmacy Balance
        const pharmacy = await Pharmacy.findById(compensation.pharmacy).session(session);
        const previousBalance = pharmacy.balance;
        pharmacy.balance += diff;
        await pharmacy.save({ session });

        // Log Adjustment
        if (diff !== 0) {
            await BalanceHistory.create([{
                pharmacy: pharmacy._id,
                type: 'compensation', // Keep type uniform
                amount: diff,
                previousBalance,
                newBalance: pharmacy.balance,
                relatedEntity: compensation._id,
                relatedEntityType: 'Compensation',
                description: `Compensation updated: ${oldAmount} -> ${amount}. Reason: ${description}`
            }], { session });
        }

        // Trigger Real-time Balance Update
        await sendToUser(compensation.pharmacy, 'balanceUpdatete', {
            balance: pharmacy.balance
        });

        await session.commitTransaction();

        res.status(200).json({ success: true, data: compensation });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
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
            throw new Error('Compensation not found');
        }

        const pharmacy = await Pharmacy.findById(compensation.pharmacy).session(session);
        const previousBalance = pharmacy.balance;
        
        // Revert Balance
        pharmacy.balance -= compensation.amount;
        await pharmacy.save({ session });

        // Log Reversal
        await BalanceHistory.create([{
            pharmacy: pharmacy._id,
            type: 'compensation',
            amount: -compensation.amount,
            previousBalance,
            newBalance: pharmacy.balance,
            relatedEntity: compensation._id, // Keep ID even if deleted? Or null? Let's keep ID for reference.
            relatedEntityType: 'Compensation',
            description: `Compensation reverted/deleted: -${compensation.amount}`
        }], { session });

        // Delete Compensation
        await compensation.deleteOne({ session });

        // Trigger Real-time Balance Update
        await sendToUser(compensation.pharmacy, 'balanceUpdatete', {
            balance: pharmacy.balance
        });

        await session.commitTransaction();

        res.status(200).json({ success: true, message: 'Compensation deleted and balance reverted' });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};
