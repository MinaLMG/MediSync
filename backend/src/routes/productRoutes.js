const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { protect, authorize } = require('../middlewares/authMiddleware');

const { getLimiter, strictLimiter } = require('../middlewares/rateLimiter');

router.use(protect);

// Basic product listing
router.get('/', getLimiter, productController.getAllProducts);
router.get('/lite', getLimiter, productController.getProductsLite);

// Suggestions
router.post('/suggest', authorize('pharmacy_owner', 'pharmacy_staff'), strictLimiter, productController.suggestProduct);
router.get('/suggestions', getLimiter, productController.getSuggestions);
router.put('/suggestions/:id', authorize('admin'), strictLimiter, productController.updateSuggestionStatus);

router.get('/:id', getLimiter, productController.getProductById);

// Admin Direct CRUD
router.post('/', authorize('admin'), strictLimiter, productController.createProduct);
router.put('/:id', authorize('admin'), strictLimiter, productController.updateProduct);

// Price Management
router.post('/volume/:hasVolumeId/price', authorize('admin'), strictLimiter, productController.addPriceToVolume);
router.delete('/volume/:hasVolumeId/price', authorize('admin'), strictLimiter, productController.removePriceFromVolume);
router.patch('/volume/:hasVolumeId/value', authorize('admin'), strictLimiter, productController.updateHasVolumeValue);

router.patch('/:id/toggle-status', protect, authorize('admin'), strictLimiter, productController.toggleProductStatus);

module.exports = router;
