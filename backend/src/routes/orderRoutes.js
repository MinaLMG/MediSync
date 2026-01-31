const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/authMiddleware');
const { getMyOrders } = require('../controllers/orderController');

const { getLimiter } = require('../middlewares/rateLimiter');

// All routes are protected
router.use(protect);

// Get My Orders History (Manager/Owner)
router.get('/my', authorize('manager', 'pharmacy_owner'), getLimiter, getMyOrders);

module.exports = router;
