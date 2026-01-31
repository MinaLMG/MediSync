const express = require('express');
const router = express.Router();
const { createCompensation, getCompensations, updateCompensation, deleteCompensation } = require('../controllers/compensationController');
const { protect, admin } = require('../middlewares/authMiddleware');
const { strictLimiter } = require('../middlewares/rateLimiter');

// All routes are protected and admin only
router.use(protect);
router.use(admin);

router.post('/', strictLimiter, createCompensation);
router.get('/:pharmacyId', getCompensations);
router.put('/:id', strictLimiter, updateCompensation);
router.delete('/:id', strictLimiter, deleteCompensation);

module.exports = router;
