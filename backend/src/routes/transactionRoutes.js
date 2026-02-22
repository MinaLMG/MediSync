const express = require('express');
const router = express.Router();
const {
    getMatchableProducts,
    getMatchesForProduct,
    createTransaction,
    updateTransactionStatus,
    getTransactions,
    assignTransaction,
    unassignTransaction,
    revertTransaction,
    updateReversalTicket,
    updateTransactionRatios,
    buyFromMarket,
    fulfillOrder,
    updateTransaction
} = require('../controllers/transactionController');
const { protect, authorize } = require('../middlewares/authMiddleware');
const { getLimiter, strictLimiter, sensitiveLimiter } = require('../middlewares/rateLimiter');

// All transaction routes are protected and restricted to Admin
router.use(protect);
// Transaction routes
router.get('/matchable', authorize('admin'), getLimiter, getMatchableProducts);
router.get('/matches/:productId', authorize('admin'), getLimiter, getMatchesForProduct);
router.get('/', authorize('admin', 'delivery'), getLimiter, getTransactions);

router.post('/fulfill', authorize('admin'), strictLimiter, fulfillOrder); // Order specific
router.post('/', authorize('admin'), strictLimiter, createTransaction);
router.put('/:id/status', authorize('admin'), strictLimiter, updateTransactionStatus);
router.put('/:id/ratios', authorize('admin'), strictLimiter, updateTransactionRatios);
router.put('/:id', authorize('admin'), strictLimiter, updateTransaction);

// Sensitive actions (Financial Reversal)
router.post('/:id/revert', authorize('admin'), sensitiveLimiter, revertTransaction);
router.put('/reversal/:ticketId', authorize('admin'), sensitiveLimiter, updateReversalTicket);

router.put('/:id/assign', authorize('delivery'), strictLimiter, assignTransaction);
router.put('/:id/unassign', authorize('admin'), strictLimiter, unassignTransaction);

module.exports = router;
