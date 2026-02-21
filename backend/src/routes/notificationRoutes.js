const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { protect } = require('../middlewares/authMiddleware');

const { getLimiter, strictLimiter } = require('../middlewares/rateLimiter');

router.use(protect);

router.get('/', getLimiter, notificationController.getMyNotifications);
router.put('/mark-all-seen', strictLimiter, notificationController.markAllAsSeen);
router.put('/:id/seen', strictLimiter, notificationController.markAsSeen);

// Test endpoint
const { addNotificationJob } = require('../utils/queueManager');
router.post('/test', strictLimiter, (req, res) => {
    setImmediate(() => addNotificationJob(req.user._id.toString(), 'system', 'Test notification received! 🚀', { priority: 'high' }));
    res.json({ success: true, message: 'Test notification queued' });
});

module.exports = router;
