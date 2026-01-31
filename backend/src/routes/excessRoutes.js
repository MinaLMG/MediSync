const validate = require('../middlewares/validationMiddleware');
const { createExcessSchema, updateExcessSchema } = require('../validations/stockValidations');

// Routes
router.post('/', protect, authorize('pharmacy_owner', 'manager'), strictLimiter, validate(createExcessSchema), excessController.createExcess);
router.put('/:id', protect, authorize('admin', 'pharmacy_owner', 'manager'), strictLimiter, validate(updateExcessSchema), excessController.updateExcess);
router.get('/my', protect, authorize('pharmacy_owner', 'manager'), getLimiter, excessController.getMyExcesses);
router.get('/market', protect, authorize('pharmacy_owner', 'manager'), getLimiter, excessController.getMarketExcesses);
router.get('/pending', protect, authorize('admin'), getLimiter, excessController.getPendingExcesses);
router.get('/available', protect, authorize('admin', 'pharmacy_owner'), getLimiter, excessController.getAvailableExcesses);
router.put('/:id/approve', protect, authorize('admin'), strictLimiter, excessController.approveExcess);
router.put('/:id/reject', protect, authorize('admin'), strictLimiter, excessController.rejectExcess);
router.delete('/:id', protect, authorize('admin', 'pharmacy_owner'), strictLimiter, excessController.deleteExcess);

module.exports = router;
