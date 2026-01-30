const express = require('express');
const router = express.Router();
const { 
    getWaitingUsers, 
    getActiveUsers, 
    reviewUser, 
    getAllPharmacies,
    getPendingCounts,
    createDeliveryUser,
    suspendUser,
    resetUserPassword,
    getUsersWithPendingUpdates,
    reviewUpdateData,
    getPharmacyDetail
} = require('../controllers/adminController');
const { getPharmacyOrders } = require('../controllers/orderController');
const { getPharmacyBalanceHistory } = require('../controllers/balanceHistoryController');
const { protect, admin } = require('../middlewares/authMiddleware');
const { getLimiter, strictLimiter, sensitiveLimiter } = require('../middleware/rateLimiter');

router.use(protect);
router.use(admin);

router.get('/waiting-users', getLimiter, getWaitingUsers);
router.get('/active-users', getLimiter, getActiveUsers);
router.put('/review-user/:id', strictLimiter, reviewUser);
router.get('/pharmacies', getLimiter, getAllPharmacies);
router.get('/pending-counts', getLimiter, getPendingCounts);
router.post('/create-delivery', strictLimiter, createDeliveryUser);
router.put('/suspend-user/:id', strictLimiter, suspendUser);
router.put('/reset-password/:id', sensitiveLimiter, resetUserPassword);
router.get('/pending-updates', getLimiter, getUsersWithPendingUpdates);
router.put('/review-update/:id', strictLimiter, reviewUpdateData);
router.get('/pharmacies/:id', getLimiter, getPharmacyDetail);
router.get('/pharmacies/:pharmacyId/orders', getLimiter, getPharmacyOrders);
router.get('/pharmacies/:pharmacyId/balance-history', getLimiter, getPharmacyBalanceHistory);

module.exports = router;
