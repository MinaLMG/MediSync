const express = require('express');
const router = express.Router();
const salesInvoiceController = require('../controllers/salesInvoiceController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.post('/', salesInvoiceController.createInvoice);
router.get('/', salesInvoiceController.getInvoices);
router.put('/:id', salesInvoiceController.updateInvoice);
router.delete('/:id', salesInvoiceController.deleteInvoice);

module.exports = router;
