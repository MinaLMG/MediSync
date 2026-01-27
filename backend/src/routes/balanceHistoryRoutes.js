const express = require('express');
const router = express.Router();
const { getMyBalanceHistory, getPharmacyBalanceHistory } = require('../controllers/balanceHistoryController');
const { protect, admin } = require('../middlewares/authMiddleware');

router.use(protect);

router.get('/my', getMyBalanceHistory);
router.get('/:pharmacyId', admin, getPharmacyBalanceHistory);

module.exports = router;
