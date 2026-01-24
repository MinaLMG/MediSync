const express = require('express');
const router = express.Router();
const deliveryRequestController = require('../controllers/deliveryRequestController');
const { protect, admin, authorize } = require('../middlewares/authMiddleware');

router.post('/', protect, authorize('delivery'), deliveryRequestController.createRequest);
router.get('/my-requests', protect, authorize('delivery'), deliveryRequestController.getMyRequests);

router.get('/pending', protect, admin, deliveryRequestController.getPendingRequests);
router.put('/:id/review', protect, admin, deliveryRequestController.reviewRequest);
router.delete('/cleanup', protect, admin, deliveryRequestController.cleanupRequests);

module.exports = router;
