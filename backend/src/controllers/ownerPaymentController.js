const ownerPaymentService = require('../services/ownerPaymentService');
const mongoose = require('mongoose');

exports.createPayment = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const payment = await ownerPaymentService.processOwnerPayment(req.body, req.user.pharmacy, session);
        await session.commitTransaction();
        res.status(201).json({ success: true, data: payment });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
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
            session
        );
        await session.commitTransaction();
        res.status(200).json({ success: true, data: payment });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
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
            session
        );
        await session.commitTransaction();
        res.status(200).json({ success: true, message: 'Payment deleted successfully' });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

exports.getPayments = async (req, res) => {
    try {
        const payments = await ownerPaymentService.getPaymentsByPharmacy(req.user.pharmacy);
        res.status(200).json({ success: true, data: payments });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
