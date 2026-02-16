const { Payment, Pharmacy, BalanceHistory, User } = require('../models');
const mongoose = require('mongoose');
const hubSummaryService = require('../services/hubSummaryService');
const { sendToUser } = require('../utils/pusherManager');

// @desc    Create a payment (Admin manually records a deposit/withdrawal)
// @route   POST /api/payment
// @access  Admin
exports.createPayment = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { pharmacyId, hubId, amount, type, method, referenceNumber, adminNote } = req.body;
        
        if (!pharmacyId) throw new Error('Pharmacy ID is required');
        if (!hubId) throw new Error('Hub ID is required');
        if (!amount || amount <= 0) throw new Error('Invalid amount');
        if (!['deposit', 'withdrawal'].includes(type)) throw new Error('Invalid type');

        const pharmacy = await Pharmacy.findById(pharmacyId).session(session);
        if (!pharmacy) throw new Error('Pharmacy not found');

        const hub = await Pharmacy.findById(hubId).session(session);
        if (!hub || !hub.isHub) throw new Error('Selected pharmacy is not a valid Hub');

        // Create Payment Record
        const payment = await Payment.create([{
            pharmacy: pharmacyId,
            hub: hubId,
            amount,
            type,
            method,
            referenceNumber,
            adminNote,
            createdBy: req.user._id,
            processedBy: req.user._id,
            processedAt: Date.now()
        }], { session });

        // 1. Update Regular Pharmacy Balance
        const prevBalance = pharmacy.balance;
        if (type === 'deposit') {
            pharmacy.balance += amount;
        } else {
            pharmacy.balance -= amount;
        }
        await pharmacy.save({ session });

        // 2. Update Hub Cash Balance
        const prevCashBalance = hub.cashBalance;
        if (type === 'deposit') {
            hub.cashBalance += amount;
        } else {
            hub.cashBalance -= amount;
        }
        await hub.save({ session });

        // 3. Create History for Regular Pharmacy
        await BalanceHistory.create([{
            pharmacy: pharmacy._id,
            type: type === 'deposit' ? 'deposit' : 'withdrawal',
            amount: type === 'deposit' ? amount : -amount,
            previousBalance: prevBalance,
            newBalance: pharmacy.balance,
            relatedEntity: payment[0]._id,
            relatedEntityType: 'Payment',
            description: `Manual ${type} recorded by Admin`,
            description_ar: `عملية ${type === 'deposit' ? 'إيداع' : 'سحب'} يدوية مسجلة من قبل المسؤول`,
            details: { 
                method, 
                reference: referenceNumber,
                hub: hub.name
            }
        }], { session });

        // 4. Create Cash History for Hub
        await mongoose.model('CashBalanceHistory').create([{
            pharmacy: hub._id,
            type: type === 'deposit' ? 'deposit' : 'withdrawal',
            amount: amount,
            previousBalance: prevCashBalance,
            newBalance: hub.cashBalance,
            relatedEntity: payment[0]._id,
            relatedEntityType: 'Payment',
            description: `Payment ${type} (via ${pharmacy.name})`,
            description_ar: `عملية دفع ${type === 'deposit' ? 'إيداع' : 'سحب'} (عبر ${pharmacy.name})`,
            details: { 
                paymentId: payment[0]._id,
                pharmacyName: pharmacy.name
            }
        }], { session });

        await session.commitTransaction();

        // Notify Users
        const users = await User.find({ pharmacy: pharmacy._id });
        for (const u of users) {
            sendToUser(u._id.toString(), 'balanceUpdate', { balance: pharmacy.balance });
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
        const { amount, type, method, referenceNumber, adminNote, hubId } = req.body;
        
        const payment = await Payment.findById(req.params.id).session(session);
        if (!payment) throw new Error('Payment not found');

        const pharmacy = await Pharmacy.findById(payment.pharmacy).session(session);
        if (!pharmacy) throw new Error('Pharmacy not found');

        const oldHub = await Pharmacy.findById(payment.hub).session(session);
        if (!oldHub) throw new Error('Original Hub not found');

        // 1. Revert old effects
        const oldPaymentEffect = payment.type === 'deposit' ? payment.amount : -payment.amount;
        pharmacy.balance -= oldPaymentEffect;
        oldHub.cashBalance -= oldPaymentEffect;

        // 2. Update payment fields
        if (amount !== undefined && amount > 0) payment.amount = amount;
        if (type && ['deposit', 'withdrawal'].includes(type)) payment.type = type;
        if (method) payment.method = method;
        if (referenceNumber !== undefined) payment.referenceNumber = referenceNumber;
        if (adminNote !== undefined) payment.adminNote = adminNote;
        
        let targetHub = oldHub;
        if (hubId && hubId.toString() !== payment.hub.toString()) {
            targetHub = await Pharmacy.findById(hubId).session(session);
            if (!targetHub || !targetHub.isHub) throw new Error('Invalid new Hub selected');
            payment.hub = hubId;
        }

        payment.processedBy = req.user._id;
        payment.processedAt = Date.now();

        // 3. Apply new effects
        const newPaymentEffect = payment.type === 'deposit' ? payment.amount : -payment.amount;
        
        const prevBalance = pharmacy.balance;
        pharmacy.balance += newPaymentEffect;
        
        const prevCashBalance = targetHub.cashBalance;
        targetHub.cashBalance += newPaymentEffect;

        await payment.save({ session });
        await pharmacy.save({ session });
        if (oldHub._id.toString() !== targetHub._id.toString()) {
            await oldHub.save({ session });
        }
        await targetHub.save({ session });

        // 4. Create history records
        await BalanceHistory.create([{
            pharmacy: pharmacy._id,
            type: payment.type === 'deposit' ? 'deposit' : 'withdrawal',
            amount: newPaymentEffect,
            previousBalance: prevBalance,
            newBalance: pharmacy.balance,
            relatedEntity: payment._id,
            relatedEntityType: 'Payment',
            description: `Payment updated by Admin`,
            description_ar: `تم تحديث عملية الدفع من قبل المسؤول`,
            details: { method: payment.method, reference: payment.referenceNumber }
        }], { session });

        await mongoose.model('CashBalanceHistory').create([{
            pharmacy: targetHub._id,
            type: payment.type === 'deposit' ? 'deposit' : 'withdrawal',
            amount: payment.amount,
            previousBalance: prevCashBalance,
            newBalance: targetHub.cashBalance,
            relatedEntity: payment._id,
            relatedEntityType: 'Payment',
            description: `Payment updated (via ${pharmacy.name})`,
            description_ar: `تم تحديث عملية الدفع (عبر ${pharmacy.name})`,
            details: { paymentId: payment._id, pharmacyName: pharmacy.name }
        }], { session });

        await session.commitTransaction();

        // Notify users
        const users = await User.find({ pharmacy: pharmacy._id });
        for (const u of users) {
            sendToUser(u._id.toString(), 'balanceUpdate', { balance: pharmacy.balance });
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

        const hub = await Pharmacy.findById(payment.hub).session(session);
        if (!hub) throw new Error('Hub not found');

        // 1. Revert effects
        const prevBalance = pharmacy.balance;
        const prevCashBalance = hub.cashBalance;
        
        const effect = payment.type === 'deposit' ? payment.amount : -payment.amount;
        pharmacy.balance -= effect;
        hub.cashBalance -= effect;

        await pharmacy.save({ session });
        await hub.save({ session });

        // 2. Create history records for reversals
        await BalanceHistory.create([{
            pharmacy: pharmacy._id,
            type: payment.type === 'deposit' ? 'withdrawal' : 'deposit',
            amount: -effect,
            previousBalance: prevBalance,
            newBalance: pharmacy.balance,
            relatedEntity: payment._id,
            relatedEntityType: 'Payment',
            description: `Payment deleted by Admin`,
            description_ar: `تم حذف عملية الدفع من قبل المسؤول`,
            details: { originalType: payment.type, originalAmount: payment.amount }
        }], { session });

        await mongoose.model('CashBalanceHistory').create([{
            pharmacy: hub._id,
            type: payment.type === 'deposit' ? 'withdrawal' : 'deposit',
            amount: payment.amount,
            previousBalance: prevCashBalance,
            newBalance: hub.cashBalance,
            relatedEntity: payment._id,
            relatedEntityType: 'Payment',
            description: `Payment deletion (via ${pharmacy.name})`,
            description_ar: `حذف عملية الدفع (عبر ${pharmacy.name})`,
            details: { paymentId: payment._id, pharmacyName: pharmacy.name }
        }], { session });

        // 3. Delete the payment
        await Payment.findByIdAndDelete(req.params.id).session(session);

        await session.commitTransaction();

        // Notify users
        const users = await User.find({ pharmacy: pharmacy._id });
        for (const u of users) {
            sendToUser(u._id.toString(), 'balanceUpdate', { balance: pharmacy.balance });
        }

        res.status(200).json({ success: true, message: 'Payment deleted and balances reversed' });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

exports.getHubCashSummary = async (req, res) => {
    try {
        const summary = await hubSummaryService.getCashBalanceSummary(req.user.pharmacy);
        res.status(200).json({ success: true, data: summary });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
