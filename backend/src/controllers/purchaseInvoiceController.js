const purchaseInvoiceService = require('../services/purchaseInvoiceService');
const mongoose = require('mongoose');

exports.createInvoice = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const invoice = await purchaseInvoiceService.createPurchaseInvoice(req.body, req.user.pharmacy, req, session);
        await session.commitTransaction();
        res.status(201).json({ success: true, data: invoice });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

exports.getInvoices = async (req, res) => {
    try {
        const invoices = await purchaseInvoiceService.getInvoicesByPharmacy(req.user.pharmacy);
        res.status(200).json({ success: true, data: invoices });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

exports.updateInvoice = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const invoice = await purchaseInvoiceService.updatePurchaseInvoice(req.params.id, req.body, req, session);
        await session.commitTransaction();
        res.status(200).json({ success: true, data: invoice });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

exports.deleteInvoice = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        await purchaseInvoiceService.deletePurchaseInvoice(req.params.id, session);
        await session.commitTransaction();
        res.status(200).json({ success: true, message: 'Purchase invoice deleted' });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};
