const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/authMiddleware');
const { 
    createShortage, 
    getActiveShortages, 
    getMyShortages,
    updateShortage,
    deleteShortage 
} = require('../controllers/shortageController');

// All routes are protected
router.use(protect);

// Pharmacy Owner Routes
router.post('/', authorize('pharmacy_owner', 'manager'), createShortage);
router.put('/:id', authorize('pharmacy_owner', 'manager'), updateShortage); // Add Update
router.get('/my', authorize('pharmacy_owner', 'manager'), getMyShortages);

// Admin Routes
router.get('/active', authorize('admin'), getActiveShortages);
router.delete('/:id', authorize('admin', 'pharmacy_owner'), deleteShortage);

module.exports = router;
