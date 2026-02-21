const { DeliveryRequest, Transaction, User } = require('../models');
const transactionService = require('../services/transactionService');

// @desc    Create a delivery request (accept or complete)
// @route   POST /api/delivery/requests
// @access  Delivery
exports.createRequest = async (req, res) => {
    const mongoose = require('mongoose');
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { transactionId, requestType } = req.body;

        if (!['accept', 'complete'].includes(requestType)) {
            throw {message:'invalid reqest type',code:400} 
        }

        // Check if transaction exists
        const transaction = await Transaction.findById(transactionId).session(session);
        if (!transaction) {
            throw {message:'Transaction not found',code:404} 
        }
        // Check for ANY existing pending request for this transaction
        const existingRequest = await DeliveryRequest.findOne({
            transaction: transactionId,
            status: 'pending'
        }).session(session);
        if (existingRequest) {
            throw {message:'This transaction already has a pending delivery request',code:400} 
        }

        // [New Requirement] Only the assigned delivery user can make requests
        if (!transaction.delivery || transaction.delivery.toString() !== req.user._id.toString()) {
            throw {message:'You must be assigned to this transaction before making  request',code:400}
        }

        // Check appropriate transaction status for request type
        if (requestType === 'accept' && transaction.status !== 'pending') {
            throw {message:'Acceptance requests can only be made for pending transactions',code:400} 
        }
        if (requestType === 'complete' && transaction.status !== 'accepted') {
            throw {message:'Completion requests can only be made for accepted transactions',code:400} 
        }

        const deliveryRequest = await DeliveryRequest.create([{
            delivery: req.user._id,
            transaction: transactionId,
            requestType
        }], { session });

        await session.commitTransaction();
        res.status(201).json({ success: true, data: deliveryRequest[0] });
    } catch (error) {
        if (session && session.inTransaction()) await session.abortTransaction();  
        res.status(error.code || 400).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Get all pending delivery requests
// @route   GET /api/delivery/requests/pending
// @access  Admin
exports.getPendingRequests = async (req, res) => {
    try {
        const requests = await DeliveryRequest.find({ status: 'pending' })
            .populate('delivery', 'name phone')
            .populate({
                path: 'transaction',
                populate: [
                    { path: 'stockShortage.shortage', populate: [
                        { path: 'pharmacy', select: 'name address phone' },
                        { path: 'product', select: 'name' }
                    ] },
                    { path: 'stockExcessSources.stockExcess', populate: [
                        { path: 'pharmacy', select: 'name address phone' },
                        { path: 'product', select: 'name' }
                    ] }
                ]
            })
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, count: requests.length, data: requests });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Review (Approve/Reject) a delivery request
// @route   PUT /api/delivery/requests/:id/review
// @access  Admin
exports.reviewRequest = async (req, res) => {
    const mongoose = require('mongoose');
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { status } = req.body; // 'approved' or 'rejected'
        if (!['approved', 'rejected'].includes(status)) {
            throw { message: 'Invalid status', code: 400 };
        }

        const request = await DeliveryRequest.findById(req.params.id).session(session);
        if (!request) {
            throw { message: 'Request not found', code: 404 };
        }
        request.status = status;
        await request.save({ session });

        let transaction = await Transaction.findById(request.transaction).session(session);

        if (status === 'approved') {
            const transactionStatus = request.requestType === 'accept' ? 'accepted' : 'completed';
            
            // SECURITY CHECK: If already assigned, only that person can change status
            if (transaction.delivery && transaction.delivery.toString() !== request.delivery.toString()) {
                throw { message: 'Only the assigned delivery person can process this transaction', code: 403 };
            }

            transaction = await transactionService.updateTransactionStatus(
                request.transaction,
                transactionStatus,
                req,
                session
            );
        }

        await session.commitTransaction();

        // Notify Stakeholders
        if (transaction) {
            await transactionService.notifyParties(transaction);
        }

        // Notify Delivery User specifically about their REQUEST review outcome
        try {
            const { addNotificationJob } = require('../utils/queueManager');
            const isAccept = request.requestType === 'accept';
            const action = isAccept ? 'Acceptance' : 'Completion';
            const actionAr = isAccept ? 'قبول' : 'إتمام';
            const statusAr = status === 'approved' ? 'قبوله' : 'رفضه';
            
            setImmediate(() => addNotificationJob(
                request.delivery.toString(),
                'transaction',
                `Your request for ${action} has been ${status}.`,
                {
                    relatedEntity: request.transaction,
                    relatedEntityType: 'Transaction'
                },
                `طلبك لـ ${actionAr} تم ${statusAr}.`
            ));
        } catch (notifErr) {
            console.error('Notification error in reviewRequest:', notifErr);
        }

        res.status(200).json({ success: true, data: request });
    } catch (error) {
        console.error('[Error] reviewRequest failed:', error);
        if (session && session.inTransaction()) await session.abortTransaction();
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    } finally {
        session.endSession();
    }
};

// @desc    Cleanup old requests (older than 1 month)
// @route   DELETE /api/delivery/requests/cleanup
// @access  Admin
exports.cleanupRequests = async (req, res) => {
    try {
        const oneMonthAgo = new Date();
        oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

        const result = await DeliveryRequest.deleteMany({
            status: { $in: ['approved', 'rejected'] },
            updatedAt: { $lt: oneMonthAgo }
        });

        res.status(200).json({ success: true, message: `Deleted ${result.deletedCount} old requests` });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};

// @desc    Get delivery person's own requests
// @route   GET /api/delivery/requests/my-requests
// @access  Delivery
exports.getMyRequests = async (req, res) => {
    try {
        const requests = await DeliveryRequest.find({ delivery: req.user._id }).sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: requests });
    } catch (error) {
        res.status(error.code || 500).json({ success: false, message: error.message || 'An unexpected error occurred' });
    }
};
