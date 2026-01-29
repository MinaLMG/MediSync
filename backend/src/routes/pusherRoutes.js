const express = require('express');
const router = express.Router();
const { authenticate } = require('../controllers/pusherController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/auth', protect, authenticate);

module.exports = router;
