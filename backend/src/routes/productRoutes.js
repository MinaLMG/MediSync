const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { protect, authorize } = require('../middlewares/authMiddleware');

const { getLimiter, strictLimiter } = require('../middleware/rateLimiter');

const validate = require('../middlewares/validationMiddleware');
const { createProductSchema, suggestProductSchema } = require('../validations/productValidations');

router.use(protect);

// Basic product listing
router.get('/', getLimiter, productController.getAllProducts);
router.get('/lite', getLimiter, productController.getProductsLite);
router.get('/:id', getLimiter, productController.getProductById);

// Suggestions
router.post('/suggest', authorize('pharmacy_owner', 'pharmacy_staff'), strictLimiter, validate(suggestProductSchema), productController.suggestProduct);
router.get('/suggestions', getLimiter, productController.getSuggestions);
router.put('/suggestions/:id', authorize('admin'), strictLimiter, productController.updateSuggestionStatus);

// Admin Direct CRUD
router.post('/', authorize('admin'), strictLimiter, validate(createProductSchema), productController.createProduct);
router.put('/:id', authorize('admin'), strictLimiter, validate(createProductSchema), productController.updateProduct);

// Price Management
router.post('/volume/:hasVolumeId/price', authorize('admin'), strictLimiter, productController.addPriceToVolume);
router.delete('/volume/:hasVolumeId/price', authorize('admin'), strictLimiter, productController.removePriceFromVolume);

router.patch('/:id/toggle-status', protect, authorize('admin'), strictLimiter, productController.toggleProductStatus);

module.exports = router;
