const express = require('express');
const router = express.Router();
const ownerPaymentController = require('../controllers/ownerPaymentController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.post('/', ownerPaymentController.createPayment);
router.get('/', ownerPaymentController.getPayments);
router.put('/:id', ownerPaymentController.updatePayment);
router.delete('/:id', ownerPaymentController.deletePayment);

module.exports = router;
