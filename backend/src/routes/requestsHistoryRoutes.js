const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/authMiddleware');
const { getMyRequestsHistory } = require('../controllers/requestsHistoryController');

const { getLimiter } = require('../middleware/rateLimiter');

// All routes are protected
router.use(protect);

// Get My Requests History (Manager/Owner)
router.get('/my', authorize('manager', 'pharmacy_owner'), getLimiter, getMyRequestsHistory);

module.exports = router;
