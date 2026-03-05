const express = require('express');
const router = express.Router();
const productQuotaController = require('../controllers/productQuotaController');
const { protect, authorize } = require('../middlewares/authMiddleware');

router.use(protect);
router.use(authorize('admin'));

router.post('/', productQuotaController.createQuota);
router.get('/', productQuotaController.getQuotas);
router.put('/:id', productQuotaController.updateQuota);
router.delete('/:id', productQuotaController.deleteQuota);

module.exports = router;