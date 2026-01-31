const express = require('express');
const router = express.Router();
const suggestionController = require('../controllers/suggestionController');
const { protect, admin } = require('../middlewares/authMiddleware');

const { getLimiter, strictLimiter } = require('../middlewares/rateLimiter');

router.post('/', protect, strictLimiter, suggestionController.createSuggestion);
router.put('/:id/seen', protect, admin, strictLimiter, suggestionController.markAsSeen);
router.get('/', protect, admin, getLimiter, suggestionController.getAllSuggestions);

module.exports = router;
