const express = require('express');
const router = express.Router();
const {
    getMatchableProducts,
    getMatchesForProduct,
    createTransaction,
    updateTransactionStatus,
    getTransactions
} = require('../controllers/transactionController');
const { protect, authorize } = require('../middlewares/authMiddleware');

// All transaction routes are protected and restricted to Admin
router.use(protect);
router.use(authorize('admin'));

router.get('/matchable', getMatchableProducts);
router.get('/matches/:productId', getMatchesForProduct);
router.get('/', getTransactions);
router.post('/', createTransaction);
router.put('/:id/status', updateTransactionStatus);

module.exports = router;
