const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/authMiddleware');
const { 
    createShortage, 
    getActiveShortages, 
    getMyShortages,
    updateShortage,
    deleteShortage,
    getGlobalActiveShortages
} = require('../controllers/shortageController');

const { getLimiter, strictLimiter } = require('../middleware/rateLimiter');

// All routes are protected
router.use(protect);

// Pharmacy Owner Routes
router.post('/', authorize('pharmacy_owner', 'manager'), strictLimiter, createShortage);
router.put('/:id', authorize('pharmacy_owner', 'manager'), strictLimiter, updateShortage); // Add Update
router.get('/my', authorize('pharmacy_owner', 'manager'), getLimiter, getMyShortages);

// Admin Routes
router.get('/active', authorize('admin'), getLimiter, getActiveShortages);
router.get('/global-active', getLimiter, getGlobalActiveShortages);
router.delete('/:id', authorize('admin', 'pharmacy_owner'), strictLimiter, deleteShortage);

module.exports = router;
