const { Payment, Pharmacy, BalanceHistory, User } = require('../models');
const mongoose = require('mongoose');
const { sendToUser } = require('../utils/pusherManager');

// @desc    Create a payment (Admin manually records a deposit/withdrawal)
// @route   POST /api/payment
// @access  Admin
exports.createPayment = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { pharmacyId, amount, type, method, referenceNumber, adminNote } = req.body;
        
        if (!pharmacyId) throw new Error('Pharmacy ID is required');
        if (!amount || amount <= 0) throw new Error('Invalid amount');
        if (!['deposit', 'withdrawal'].includes(type)) throw new Error('Invalid type');

        const pharmacy = await Pharmacy.findById(pharmacyId).session(session);
        if (!pharmacy) throw new Error('Pharmacy not found');

        // Create Payment Record
        const payment = await Payment.create([{
            pharmacy: pharmacyId,
            amount,
            type,
            method,
            referenceNumber,
            adminNote,
            createdBy: req.user._id,
            processedBy: req.user._id,
            processedAt: Date.now()
        }], { session });

        // Update Balance
        const prevBalance = pharmacy.balance;
        let newBalance = prevBalance;
        
        if (type === 'deposit') {
            newBalance += amount;
        } else {
            newBalance -= amount;
        }

        pharmacy.balance = newBalance;
        await pharmacy.save({ session });

        // Create History Record
        await BalanceHistory.create([{
            pharmacy: pharmacy._id,
            type: type === 'deposit' ? 'deposit' : 'withdrawal',
            amount: type === 'deposit' ? amount : -amount,
            previousBalance: prevBalance,
            newBalance: newBalance,
            relatedEntity: payment[0]._id,
            relatedEntityType: 'Payment',
            description: `Manual ${type} recorded by Admin`,
            description_ar: `عملية ${type === 'deposit' ? 'إيداع' : 'سحب'} يدوية مسجلة من قبل المسؤول`,
            details: { 
                method, 
                reference: referenceNumber,
                adminNote 
            }
        }], { session });

        await session.commitTransaction();

        // Notify Users
        const users = await User.find({ pharmacy: pharmacy._id });
        for (const u of users) {
            sendToUser(u._id.toString(), 'balanceUpdate', { balance: newBalance });
        }

        res.status(201).json({ success: true, data: payment[0] });

    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// @desc    Get payments
// @route   GET /api/payment
// @access  Admin, Pharmacy Owner
exports.getPayments = async (req, res) => {
    try {
        let query = {};
        
        // If not admin, restrict to own pharmacy
        if (req.user.role !== 'admin') {
            if (!req.user.pharmacy) {
                return res.status(400).json({ success: false, message: 'No pharmacy linked' });
            }
            query.pharmacy = req.user.pharmacy;
        } else {
            // Admin filters
            if (req.query.pharmacyId) query.pharmacy = req.query.pharmacyId;
        }

        if (req.query.type) query.type = req.query.type;

        const payments = await Payment.find(query)
            .populate('pharmacy', 'name phone')
            .populate('createdBy', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, count: payments.length, data: payments });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Update a payment
// @route   PUT /api/payment/:id
// @access  Admin
exports.updatePayment = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { amount, type, method, referenceNumber, adminNote } = req.body;
        
        const payment = await Payment.findById(req.params.id).session(session);
        if (!payment) throw new Error('Payment not found');

        const pharmacy = await Pharmacy.findById(payment.pharmacy).session(session);
        if (!pharmacy) throw new Error('Pharmacy not found');

        // Reverse the old payment effect on balance
        const oldAmount = payment.type === 'deposit' ? payment.amount : -payment.amount;
        pharmacy.balance -= oldAmount;

        // Update payment fields
        if (amount !== undefined && amount > 0) payment.amount = amount;
        if (type && ['deposit', 'withdrawal'].includes(type)) payment.type = type;
        if (method) payment.method = method;
        if (referenceNumber !== undefined) payment.referenceNumber = referenceNumber;
        if (adminNote !== undefined) payment.adminNote = adminNote;
        payment.processedBy = req.user._id;
        payment.processedAt = Date.now();

        // Apply new payment effect
        const newAmount = payment.type === 'deposit' ? payment.amount : -payment.amount;
        const prevBalance = pharmacy.balance;
        pharmacy.balance += newAmount;
        const newBalance = pharmacy.balance;

        await payment.save({ session });
        await pharmacy.save({ session });

        // Create history record for the update
        await BalanceHistory.create([{
            pharmacy: pharmacy._id,
            type: payment.type === 'deposit' ? 'deposit' : 'withdrawal',
            amount: newAmount,
            previousBalance: prevBalance,
            newBalance: newBalance,
            relatedEntity: payment._id,
            relatedEntityType: 'Payment',
            description: `Payment updated by Admin`,
            description_ar: `تم تحديث عملية الدفع من قبل المسؤول`,
            details: { 
                method: payment.method, 
                reference: payment.referenceNumber,
                adminNote: payment.adminNote 
            }
        }], { session });

        await session.commitTransaction();

        // Notify users
        const users = await User.find({ pharmacy: pharmacy._id });
        for (const u of users) {
            sendToUser(u._id.toString(), 'balanceUpdate', { balance: newBalance });
        }

        res.status(200).json({ success: true, data: payment });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// @desc    Delete a payment (reverses the balance change)
// @route   DELETE /api/payment/:id
// @access  Admin
exports.deletePayment = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const payment = await Payment.findById(req.params.id).session(session);
        if (!payment) throw new Error('Payment not found');

        const pharmacy = await Pharmacy.findById(payment.pharmacy).session(session);
        if (!pharmacy) throw new Error('Pharmacy not found');

        // Reverse the payment effect on balance
        const prevBalance = pharmacy.balance;
        if (payment.type === 'deposit') {
            pharmacy.balance -= payment.amount;
        } else {
            pharmacy.balance += payment.amount;
        }
        const newBalance = pharmacy.balance;

        await pharmacy.save({ session });

        // Create history record for the reversal
        await BalanceHistory.create([{
            pharmacy: pharmacy._id,
            type: payment.type === 'deposit' ? 'withdrawal' : 'deposit', // Opposite
            amount: payment.type === 'deposit' ? -payment.amount : payment.amount,
            previousBalance: prevBalance,
            newBalance: newBalance,
            relatedEntity: payment._id,
            relatedEntityType: 'Payment',
            description: `Payment deleted/reversed by Admin`,
            description_ar: `تم حذف/عكس عملية الدفع من قبل المسؤول`,
            details: { 
                originalType: payment.type,
                originalAmount: payment.amount,
                method: payment.method,
                reference: payment.referenceNumber
            }
        }], { session });

        // Delete the payment
        await Payment.findByIdAndDelete(req.params.id).session(session);

        await session.commitTransaction();

        // Notify users
        const users = await User.find({ pharmacy: pharmacy._id });
        for (const u of users) {
            sendToUser(u._id.toString(), 'balanceUpdate', { balance: newBalance });
        }

        res.status(200).json({ success: true, message: 'Payment deleted and balance reversed' });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

