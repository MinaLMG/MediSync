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
                    { path: 'stockShortage.shortage', populate: { path: 'pharmacy', select: 'name address phone' } },
                    { path: 'stockExcessSources.stockExcess', populate: { path: 'pharmacy', select: 'name address phone' } }
                ]
            });

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

        if (status === 'approved') {
            const transaction = await Transaction.findById(request.transaction);
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
        const requests = await DeliveryRequest.find({ delivery: req.user._id });
        res.status(200).json({ success: true, data: requests });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
