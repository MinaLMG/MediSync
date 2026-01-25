const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/authMiddleware');
const excessController = require('../controllers/excessController');

const { getLimiter, strictLimiter } = require('../middleware/rateLimiter');

// Routes
router.post('/', protect, authorize('pharmacy_owner', 'manager'), strictLimiter, excessController.createExcess);
router.put('/:id', protect, authorize('pharmacy_owner', 'manager'), strictLimiter, excessController.updateExcess);
router.get('/pending', protect, authorize('admin'), getLimiter, excessController.getPendingExcesses);
router.get('/available', protect, authorize('admin', 'pharmacy_owner'), getLimiter, excessController.getAvailableExcesses);
router.put('/:id/approve', protect, authorize('admin'), strictLimiter, excessController.approveExcess);
router.delete('/:id', protect, authorize('admin', 'pharmacy_owner'), strictLimiter, excessController.deleteExcess);

module.exports = router;
