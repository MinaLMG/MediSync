const AppSuggestion = require('../models/AppSuggestion');
const mongoose = require('mongoose');
const auditService = require('../services/auditService');

exports.createSuggestion = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { content } = req.body;
        
        if (!content) {
            throw { message: 'Content is required', code: 400 };
        }

        const suggestion = await AppSuggestion.create([{
            pharmacy: req.user.pharmacy,
            user: req.user._id,
            content
        }], { session });

        await auditService.logAction({
            user: req.user._id,
            action: 'CREATE',
            entityType: 'AppSuggestion',
            entityId: suggestion[0]._id,
            changes: { content }
        }, req);

        await session.commitTransaction();
        res.status(201).json({ success: true, data: suggestion[0] });
    } catch (err) {
        await session.abortTransaction();
        res.status(err.code || 500).json({ success: false, message: err.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

exports.markAsSeen = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const suggestion = await AppSuggestion.findById(req.params.id).session(session);

        if (!suggestion) {
            throw { message: 'Suggestion not found', code: 404 };
        }

        if (suggestion.seen) {
            await session.abortTransaction();
            return res.status(200).json({ success: true, data: suggestion });
        }

        suggestion.seen = true;
        await suggestion.save({ session });

        await auditService.logAction({
            user: req.user._id,
            action: 'UPDATE',
            entityType: 'AppSuggestion',
            entityId: suggestion._id,
            changes: { seen: true }
        }, req);

        await session.commitTransaction();
        res.status(200).json({ success: true, data: suggestion });
    } catch (err) {
        await session.abortTransaction();
        res.status(err.code || 500).json({ success: false, message: err.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

exports.getAllSuggestions = async (req, res) => {
    try {
        const suggestions = await AppSuggestion.find()
            .populate('pharmacy', 'name')
            .populate('user', 'name')
            .sort({ createdAt: -1 });
            
        res.status(200).json({ success: true, count: suggestions.length, data: suggestions });
    } catch (err) {
        res.status(err.code || 500).json({ success: false, message: err.message || 'An unexpected error occurred' });
    }
};
