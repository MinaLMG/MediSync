const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.get('/', notificationController.getMyNotifications);
router.put('/mark-all-seen', notificationController.markAllAsSeen);
router.put('/:id/seen', notificationController.markAsSeen);

// Test endpoint
const { addNotificationJob } = require('../utils/queueManager');
router.post('/test', async (req, res) => {
    await addNotificationJob(req.user._id.toString(), 'system', 'Test notification received! 🚀', { priority: 'high' });
    res.json({ success: true, message: 'Test notification queued' });
});

module.exports = router;
