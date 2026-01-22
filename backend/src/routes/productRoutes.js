const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const productController = require('../controllers/productController');

router.get('/', protect, productController.getAllProducts);

module.exports = router;
