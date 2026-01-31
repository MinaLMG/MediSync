const validate = require('../middlewares/validationMiddleware');
const { registerSchema, loginSchema } = require('../validations/authValidations');
const router = express.Router();

router.post('/register', validate(registerSchema), register);
router.post('/login', validate(loginSchema), login);
router.post('/social-login', socialLogin);
router.get('/profile', protect, getProfile);
router.put('/profile-update-request', protect, requestProfileUpdate);
router.put('/change-password', protect,  changePassword);
router.post('/link-pharmacy', protect, upload.fields([
    { name: 'pharmacistCard', maxCount: 1 },
    { name: 'commercialRegistry', maxCount: 1 },
    { name: 'taxCard', maxCount: 1 },
    { name: 'pharmacyLicense', maxCount: 1 }
]), linkPharmacy);

module.exports = router;
