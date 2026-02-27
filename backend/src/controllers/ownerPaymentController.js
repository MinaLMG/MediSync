const ownerPaymentService = require('../services/ownerPaymentService');
const mongoose = require('mongoose');
const auditService = require('../services/auditService');

exports.createPayment = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const payment = await ownerPaymentService.processOwnerPayment(req.body, req.user.pharmacy, session, req);

        await auditService.logAction({
            user: req.user._id,
            action: 'CREATE',
            entityType: 'OwnerPayment',
            entityId: payment._id,
            changes: { value: payment.value, ownerId: payment.owner }
        }, req);

        await session.commitTransaction();
        res.status(201).json({ success: true, data: payment });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

exports.updatePayment = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const payment = await ownerPaymentService.updateOwnerPayment(
            req.params.id,
            req.body,
            req.user.pharmacy,
            session,
            req
        );

        await auditService.logAction({
            user: req.user._id,
            action: 'UPDATE',
            entityType: 'OwnerPayment',
            entityId: payment._id,
            changes: req.body
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, data: payment });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

exports.deletePayment = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        await ownerPaymentService.deleteOwnerPayment(
            req.params.id,
            req.user.pharmacy,
            session,
            req
        );

        await auditService.logAction({
            user: req.user._id,
            action: 'DELETE',
            entityType: 'OwnerPayment',
            entityId: req.params.id,
            changes: { status: 'deleted' }
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, message: 'Payment deleted successfully' });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

exports.getPayments = async (req, res) => {
    try {
        const payments = await ownerPaymentService.getPaymentsByPharmacy(req.user.pharmacy);
        res.status(200).json({ success: true, data: payments });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};
