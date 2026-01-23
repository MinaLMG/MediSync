const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/authMiddleware');
const { 
    createShortage, 
    getActiveShortages, 
    getMyShortages,
    deleteShortage 
} = require('../controllers/shortageController');

// All routes are protected
router.use(protect);

// Pharmacy Owner Routes
router.post('/', authorize( 'pharmacy_owner'), createShortage);
router.get('/my', authorize( 'pharmacy_owner'), getMyShortages);

// Admin Routes
router.get('/active', authorize('admin'), getActiveShortages);
router.delete('/:id', authorize('admin', 'pharmacy_owner'), deleteShortage);

module.exports = router;
