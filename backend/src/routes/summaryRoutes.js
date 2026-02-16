const express = require('express');
const router = express.Router();
const summaryController = require('../controllers/summaryController');
const { protect, admin } = require('../middlewares/authMiddleware');

router.get('/pharmacies-list', protect, summaryController.getPharmaciesList);
router.get('/admin', protect, admin, summaryController.getAdminSummary);

module.exports = router;
