const express = require('express');
const router = express.Router();
const deliveryRequestController = require('../controllers/deliveryRequestController');
const { protect, admin, authorize } = require('../middlewares/authMiddleware');

const { getLimiter, strictLimiter } = require('../middlewares/rateLimiter');

router.post('/', protect, authorize('delivery'), strictLimiter, deliveryRequestController.createRequest);
router.get('/my-requests', protect, authorize('delivery'), getLimiter, deliveryRequestController.getMyRequests);

router.get('/pending', protect, admin, getLimiter, deliveryRequestController.getPendingRequests);
router.put('/:id/review', protect, admin, strictLimiter, deliveryRequestController.reviewRequest);
router.delete('/cleanup', protect, admin, strictLimiter, deliveryRequestController.cleanupRequests);

module.exports = router;
