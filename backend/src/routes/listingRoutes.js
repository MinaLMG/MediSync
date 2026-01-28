const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/authMiddleware');
const { getMyListings } = require('../controllers/listingController');

const { getLimiter } = require('../middleware/rateLimiter');

// All routes are protected
router.use(protect);

// Get My Listings (Manager/Owner)
router.get('/my', authorize('manager', 'pharmacy_owner'), getLimiter, getMyListings);

module.exports = router;
