const { DeliveryRequest, Transaction, User } = require('../models');

// @desc    Create a delivery request (accept or complete)
// @route   POST /api/delivery/requests
// @access  Delivery
exports.createRequest = async (req, res) => {
    try {
        const { transactionId, requestType } = req.body;

        if (!['accept', 'complete'].includes(requestType)) {
            return res.status(400).json({ success: false, message: 'Invalid request type' });
        }

        // Check if transaction exists
        const transaction = await Transaction.findById(transactionId);
        if (!transaction) {
            return res.status(404).json({ success: false, message: 'Transaction not found' });
        }

        // Check for assignment - if already assigned to someone else
        if (transaction.delivery && transaction.delivery.toString() !== req.user._id.toString()) {
            return res.status(403).json({ success: false, message: 'This transaction is assigned to another delivery user' });
        }

        // Check for existing pending request for this delivery user and transaction
        const existingRequest = await DeliveryRequest.findOne({
            delivery: req.user._id,
            transaction: transactionId,
            status: 'pending'
        });

        if (existingRequest) {
            return res.status(400).json({ success: false, message: 'You already have a pending request for this transaction' });
        }

        const deliveryRequest = await DeliveryRequest.create({
            delivery: req.user._id,
            transaction: transactionId,
            requestType
        });

        res.status(201).json({ success: true, data: deliveryRequest });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
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
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Review (Approve/Reject) a delivery request
// @route   PUT /api/delivery/requests/:id/review
// @access  Admin
exports.reviewRequest = async (req, res) => {
    try {
        const { status } = req.body; // 'approved' or 'rejected'
        if (!['approved', 'rejected'].includes(status)) {
            return res.status(400).json({ success: false, message: 'Invalid status' });
        }

        const request = await DeliveryRequest.findById(req.params.id);
        if (!request) {
            return res.status(404).json({ success: false, message: 'Request not found' });
        }
        request.status = status;
        await request.save();

        const transaction = await Transaction.findById(request.transaction);

        if (status === 'approved') {
            if (transaction) {
                if (request.requestType === 'accept') {
                    transaction.status = 'accepted';
                } else if (request.requestType === 'complete') {
                    transaction.status = 'completed';
                }
                await transaction.save();

                // To remove conflicts, remove any other related delivery_requests for this transaction
                await DeliveryRequest.deleteMany({
                    transaction: transaction._id,
                    _id: { $ne: request._id }
                });
            }
        }

        // Notify Delivery User of the review outcome
        try {
            const { addNotificationJob } = require('../utils/queueManager');
            const outcome = status === 'approved' ? 'approved' : 'rejected';
            const action = request.requestType === 'accept' ? 'Acceptance' : 'Completion';
            const txIdMsg = transaction ? ` for Transaction #${transaction._id.toString().slice(-6)}` : '';
            
            await addNotificationJob(
                request.delivery.toString(),
                'transaction',
                `Your request for ${action}${txIdMsg} has been ${outcome}.`,
                {
                    relatedEntity: request.transaction,
                    relatedEntityType: 'Transaction'
                }
            );

            // If approved, notify about the specific new status too
            if (status === 'approved' && transaction) {
                await addNotificationJob(
                    request.delivery.toString(),
                    'transaction',
                    `Transaction #${transaction._id.toString().slice(-6)} is now ${transaction.status}.`,
                    {
                        relatedEntity: transaction._id,
                        relatedEntityType: 'Transaction'
                    }
                );
            }
        } catch (notifErr) {
            console.error('Notification error in reviewRequest:', notifErr);
        }

        res.status(200).json({ success: true, data: request });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
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
        res.status(500).json({ success: false, message: error.message });
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
        res.status(500).json({ success: false, message: error.message });
    }
};
