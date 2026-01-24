const express = require('express');
const router = express.Router();
const { getSettings, updateSettings } = require('../controllers/settingsController');
const { protect } = require('../middlewares/authMiddleware');

// All settings routes are private and admin only
router.get('/', protect, getSettings);
router.put('/', protect, updateSettings);

module.exports = router;
