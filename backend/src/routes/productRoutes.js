const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { protect, authorize } = require('../middlewares/authMiddleware');

router.use(protect);

// Basic product listing
router.get('/', productController.getAllProducts);

// Suggestions
router.post('/suggest', authorize('pharmacy_owner', 'pharmacy_staff'), productController.suggestProduct);
router.get('/suggestions', productController.getSuggestions);
router.put('/suggestions/:id', authorize('admin'), productController.updateSuggestionStatus);

// Admin Direct CRUD
router.post('/', authorize('admin'), productController.createProduct);
router.put('/:id', authorize('admin'), productController.updateProduct);

// Price Management
router.post('/volume/:hasVolumeId/price', authorize('admin'), productController.addPriceToVolume);
router.delete('/volume/:hasVolumeId/price', authorize('admin'), productController.removePriceFromVolume);

module.exports = router;
