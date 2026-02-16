const salesInvoiceService = require('../services/salesInvoiceService');
const mongoose = require('mongoose');

exports.createInvoice = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const invoice = await salesInvoiceService.createSalesInvoice(req.body, req.user.pharmacy, session);
        await session.commitTransaction();
        res.status(201).json({ success: true, data: invoice });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

exports.getInvoices = async (req, res) => {
    try {
        const invoices = await salesInvoiceService.getInvoicesByPharmacy(req.user.pharmacy);
        res.status(200).json({ success: true, data: invoices });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.updateInvoice = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const invoice = await salesInvoiceService.updateSalesInvoice(req.params.id, req.body, session);
        await session.commitTransaction();
        res.status(200).json({ success: true, data: invoice });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

exports.deleteInvoice = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        await salesInvoiceService.deleteSalesInvoice(req.params.id, session);
        await session.commitTransaction();
        res.status(200).json({ success: true, message: 'Sales invoice deleted' });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};
