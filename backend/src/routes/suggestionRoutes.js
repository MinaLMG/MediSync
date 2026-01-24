const express = require('express');
const router = express.Router();
const suggestionController = require('../controllers/suggestionController');
const { protect, admin } = require('../middlewares/authMiddleware');

router.post('/', protect, suggestionController.createSuggestion);
router.put('/:id/seen', protect, admin, suggestionController.markAsSeen);
router.get('/', protect, admin, suggestionController.getAllSuggestions);

module.exports = router;
