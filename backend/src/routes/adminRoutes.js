const express = require('express');
const router = express.Router();
const { 
    getWaitingUsers, 
    getActiveUsers, 
    reviewUser, 
    getAllPharmacies 
} = require('../controllers/adminController');
const { protect, admin } = require('../middlewares/authMiddleware');

router.use(protect);
router.use(admin);

router.get('/waiting-users', getWaitingUsers);
router.get('/active-users', getActiveUsers);
router.put('/review-user/:id', reviewUser);
router.get('/pharmacies', getAllPharmacies);

module.exports = router;
