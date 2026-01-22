const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/authMiddleware');
const excessController = require('../controllers/excessController');

// Routes
router.post('/', protect, authorize('pharmacy_owner'), excessController.createExcess);
router.get('/pending', protect, authorize('admin'), excessController.getPendingExcesses);
router.get('/available', protect, authorize('admin', 'pharmacy_owner'), excessController.getAvailableExcesses);
router.put('/:id/approve', protect, authorize('admin'), excessController.approveExcess);
router.delete('/:id', protect, authorize('admin', 'pharmacy_owner'), excessController.deleteExcess);

module.exports = router;
