const express = require('express');
const router = express.Router();
const { getSettings, updateSettings } = require('../controllers/settingsController');
const { protect } = require('../middlewares/authMiddleware');

const { getLimiter, strictLimiter } = require('../middlewares/rateLimiter');

// All settings routes are private and admin only
router.get('/', protect, getLimiter, getSettings);
router.put('/', protect, strictLimiter, updateSettings);

module.exports = router;
