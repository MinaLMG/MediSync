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
    getOrders
} = require('../controllers/shortageController');

const { getLimiter, strictLimiter } = require('../middleware/rateLimiter');

// Pharmacy Owner Routes
router.post('/', protect, authorize('pharmacy_owner', 'manager'), strictLimiter, createShortage);
router.post('/order', protect, authorize('pharmacy_owner', 'manager'), strictLimiter, createOrder);
router.put('/:id', protect, authorize('pharmacy_owner', 'manager'), strictLimiter, updateShortage);
router.get('/my', protect, authorize('pharmacy_owner', 'manager'), getLimiter, getMyShortages);

// Admin Routes
router.get('/orders', protect, authorize('admin'), getLimiter, getOrders);
router.get('/active', protect, authorize('admin'), getLimiter, getActiveShortages);
router.get('/global-active', protect, getLimiter, getGlobalActiveShortages);
router.delete('/:id', protect, authorize('admin', 'pharmacy_owner'), strictLimiter, deleteShortage);

module.exports = router;
