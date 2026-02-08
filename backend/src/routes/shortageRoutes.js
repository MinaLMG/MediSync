const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/authMiddleware');
const { 
    createShortage, 
    getActiveShortages, 
    getMyShortages,
    updateShortage,
    deleteShortage,
    getGlobalActiveShortages,
    createOrder,
    getOrders,
    getFulfilledShortages,
    cancelShortage
} = require('../controllers/shortageController');

const { getLimiter, strictLimiter } = require('../middlewares/rateLimiter');

// Pharmacy Owner Routes
router.post('/', protect, authorize('pharmacy_owner', 'manager'), strictLimiter, createShortage);
router.post('/order', protect, authorize('pharmacy_owner', 'manager'), strictLimiter, createOrder);
router.put('/:id', protect, authorize('pharmacy_owner', 'manager'), strictLimiter, updateShortage); // Keep generic update first
router.put('/:id/cancel', protect, authorize('pharmacy_owner', 'manager'), strictLimiter, cancelShortage);
router.get('/my', protect, authorize('pharmacy_owner', 'manager'), getLimiter, getMyShortages);

// Admin Routes
router.get('/orders', protect, authorize('admin'), getLimiter, getOrders);
router.get('/active', protect, authorize('admin'), getLimiter, getActiveShortages);
router.get('/fulfilled', protect, authorize('admin'), getLimiter, getFulfilledShortages);

// Public / Global
router.get('/global-active', protect, getLimiter, getGlobalActiveShortages);

router.delete('/:id', protect, authorize('admin', 'pharmacy_owner', 'manager'), strictLimiter, deleteShortage);

module.exports = router;
