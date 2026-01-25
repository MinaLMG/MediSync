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
    updateReversalTicket
} = require('../controllers/transactionController');
const { protect, authorize } = require('../middlewares/authMiddleware');

// All transaction routes are protected and restricted to Admin
router.use(protect);
// Transaction routes
router.get('/matchable', authorize('admin'), getMatchableProducts);
router.get('/matches/:productId', authorize('admin'), getMatchesForProduct);
router.get('/', authorize('admin', 'delivery'), getTransactions);
router.post('/', authorize('admin'), createTransaction);
router.put('/:id/status', authorize('admin'), updateTransactionStatus);
router.post('/:id/revert', authorize('admin'), revertTransaction);
router.put('/reversal/:ticketId', authorize('admin'), updateReversalTicket);
router.put('/:id/assign', authorize('delivery'), assignTransaction);
router.put('/:id/unassign', authorize('admin'), unassignTransaction);

module.exports = router;
