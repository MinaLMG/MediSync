const { OwnerPayment, Owner, Pharmacy, CashBalanceHistory } = require('../models');
const mongoose = require('mongoose');
const auditService = require('./auditService');

/**
 * Executes a payment between a hub and an owner.
 * MUST be called within a session.
 */
exports.processOwnerPayment = async (data, pharmacyId, session, req = null) => {
    const { ownerId, value, notes } = data;

    const owner = await Owner.findOne({ _id: ownerId, pharmacy: pharmacyId }).session(session);
    if (!owner) throw { message: 'Owner not found', code: 404 };

    const hub = await Pharmacy.findById(pharmacyId).session(session);
    if (!hub || !hub.isHub) throw { message: 'Pharmacy is not a hub', code: 403 };

    // Update balances
    const previousCashBalance = hub.cashBalance;
    hub.cashBalance += value;
    owner.balance -= value;

    await hub.save({ session });
    await owner.save({ session });

    // Record payment
    const payment = new OwnerPayment({
        pharmacy: pharmacyId,
        owner: ownerId,
        value: value,
        notes: notes
    });
    await payment.save({ session });

    // Record Cash Balance History
    await CashBalanceHistory.create([{
        pharmacy: pharmacyId,
        type: value > 0 ? 'deposit' : 'withdrawal',
        amount: Math.abs(value),
        previousBalance: previousCashBalance,
        newBalance: hub.cashBalance,
        relatedEntity: payment._id,
        relatedEntityType: 'Payment',
        description: `Owner payment: ${owner.name} (${value > 0 ? 'To Hub' : 'From Hub'})`,
        description_ar: `دفع للمالك: ${owner.name} (${value > 0 ? 'إلى الفرع' : 'من الفرع'})`,
        details: { ownerId, value }
    }], { session });


    return payment;
};

/**
 * Updates an owner payment and adjusts balances.
 * Records the difference in CashBalanceHistory.
 */
exports.updateOwnerPayment = async (paymentId, data, pharmacyId, session, req = null) => {
    const { value: newValue, notes } = data;
    const payment = await OwnerPayment.findOne({ _id: paymentId, pharmacy: pharmacyId }).session(session);
    if (!payment) throw { message: 'Payment not found', code: 404 };

    const owner = await Owner.findById(payment.owner).session(session);
    const hub = await Pharmacy.findById(pharmacyId).session(session);

    const diff = newValue - payment.value;
    if (diff === 0) return payment;

    // Adjust balances
    const previousCashBalance = hub.cashBalance;
    hub.cashBalance += diff;
    owner.balance -= diff;

    await hub.save({ session });
    await owner.save({ session });

    // Update payment record
    payment.value = newValue;
    if (notes !== undefined) payment.notes = notes;
    await payment.save({ session });

    // Record Cash Balance History for the correction
    await CashBalanceHistory.create([{
        pharmacy: pharmacyId,
        type: 'correction',
        amount: Math.abs(diff),
        previousBalance: previousCashBalance,
        newBalance: hub.cashBalance,
        relatedEntity: payment._id,
        relatedEntityType: 'Payment',
        description: `Payment correction for owner: ${owner.name} (Diff: ${diff})`,
        description_ar: `تعديل دفعة للمالك: ${owner.name} (الفرق: ${diff})`,
        details: { ownerId: owner._id, oldVal: payment.value - diff, newVal: newValue, diff }
    }], { session });


    return payment;
};

/**
 * Deletes an owner payment and reverses balances.
 */
exports.deleteOwnerPayment = async (paymentId, pharmacyId, session, req = null) => {
    const payment = await OwnerPayment.findOne({ _id: paymentId, pharmacy: pharmacyId }).session(session);
    if (!payment) throw { message: 'Payment not found', code: 404 };

    const owner = await Owner.findById(payment.owner).session(session);
    const hub = await Pharmacy.findById(pharmacyId).session(session);

    // Reverse balances
    const previousCashBalance = hub.cashBalance;
    hub.cashBalance -= payment.value;
    owner.balance += payment.value;

    await hub.save({ session });
    await owner.save({ session });

    // Record Cash Balance History for the reversal
    await CashBalanceHistory.create([{
        pharmacy: pharmacyId,
        type: payment.value > 0 ? 'withdrawal' : 'deposit',
        amount: Math.abs(payment.value),
        previousBalance: previousCashBalance,
        newBalance: hub.cashBalance,
        relatedEntity: payment._id,
        relatedEntityType: 'Payment',
        description: `Payment deleted/reversed for owner: ${owner.name}`,
        description_ar: `تم حذف/عكس دفعة للمالك: ${owner.name}`,
        details: { ownerId: owner._id, value: payment.value, action: 'delete' }
    }], { session });


    await payment.deleteOne({ session });
    return { success: true };
};

exports.getPaymentsByPharmacy = async (pharmacyId) => {
    return await OwnerPayment.find({ pharmacy: pharmacyId })
        .populate('owner', 'name')
        .sort({ createdAt: -1 });
};
