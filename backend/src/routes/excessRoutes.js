const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/authMiddleware');
const excessController = require('../controllers/excessController');

const { getLimiter, strictLimiter } = require('../middlewares/rateLimiter');
// Routes
router.post('/', protect, authorize('pharmacy_owner'), strictLimiter, excessController.createExcess);
router.put('/:id', protect, authorize('admin', 'pharmacy_owner'), strictLimiter, excessController.updateExcess);
router.get('/my', protect, authorize('pharmacy_owner'), getLimiter, excessController.getMyExcesses);
router.get('/market', protect, authorize('admin', 'pharmacy_owner'), getLimiter, excessController.getMarketExcesses);
router.get('/pending', protect, authorize('admin'), getLimiter, excessController.getPendingExcesses);
router.get('/fulfilled', protect, authorize('admin'), getLimiter, excessController.getFulfilledExcesses);
router.get('/available', protect, authorize('admin', 'pharmacy_owner'), getLimiter, excessController.getAvailableExcesses);
router.get('/pharmacy/:pharmacyId', protect, authorize('admin', 'pharmacy_owner'), getLimiter, excessController.getPharmacyExcesses);
router.get('/market-insight', protect, getLimiter, excessController.getMarketInsight);
router.put('/:id/approve', protect, authorize('admin'), strictLimiter, excessController.approveExcess);
router.put('/:id/reject', protect, authorize('admin'), strictLimiter, excessController.rejectExcess);
router.post('/add-to-hub', protect, authorize('admin'), strictLimiter, excessController.addToHub);
router.get('/hub-system', protect, excessController.getHubSystemSummary);
router.delete('/:id', protect, authorize('admin', 'pharmacy_owner'), strictLimiter, excessController.deleteExcess);

module.exports = router;
