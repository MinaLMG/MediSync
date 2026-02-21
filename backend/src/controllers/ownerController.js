const ownerService = require('../services/ownerService');
const mongoose = require('mongoose');

exports.createOwner = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const owner = await ownerService.createOwner(req.body, req.user.pharmacy, session, req);
        await session.commitTransaction();
        res.status(201).json({ success: true, data: owner });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

exports.updateOwner = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const owner = await ownerService.updateOwner(req.params.id, req.body, req.user.pharmacy, session, req);
        await session.commitTransaction();
        res.status(200).json({ success: true, data: owner });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

exports.getOwners = async (req, res) => {
    try {
        const owners = await ownerService.getOwnersByPharmacy(req.user.pharmacy);
        res.status(200).json({ success: true, data: owners });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};
