const express = require('express');
const router = express.Router();
const purchaseInvoiceController = require('../controllers/purchaseInvoiceController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.post('/', purchaseInvoiceController.createInvoice);
router.get('/', purchaseInvoiceController.getInvoices);
router.put('/:id', purchaseInvoiceController.updateInvoice);
router.delete('/:id', purchaseInvoiceController.deleteInvoice);

module.exports = router;
