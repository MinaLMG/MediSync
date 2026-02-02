const express = require('express');
const { protect, authorize } = require('../middlewares/authMiddleware');
const {
    createPayment,
    getPayments,
    updatePayment,
    deletePayment
} = require('../controllers/paymentController');

const router = express.Router();

router.get('/', protect, authorize('admin', 'pharmacy_owner', 'pharmacy_manager'), getPayments);
router.post('/', protect, authorize('admin'), createPayment);
router.put('/:id', protect, authorize('admin'), updatePayment);
router.delete('/:id', protect, authorize('admin'), deletePayment);

module.exports = router;
