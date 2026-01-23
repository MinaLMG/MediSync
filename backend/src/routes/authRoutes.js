const express = require('express');
const router = express.Router();
const { register, login, getProfile, socialLogin, linkPharmacy } = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');
const upload = require('../config/uploadConfig');

router.post('/register', register);
router.post('/login', login);
router.post('/social-login', socialLogin);
router.get('/profile', protect, getProfile);
router.post('/link-pharmacy', protect, upload.fields([
    { name: 'pharmacistCard', maxCount: 1 },
    { name: 'commercialRegistry', maxCount: 1 },
    { name: 'taxCard', maxCount: 1 },
    { name: 'pharmacyLicense', maxCount: 1 }
]), linkPharmacy);

module.exports = router;
