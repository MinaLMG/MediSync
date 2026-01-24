const Notification = require('../models/Notification');

// @desc    Get user notifications
// @route   GET /api/notifications
// @access  Private
exports.getMyNotifications = async (req, res) => {
    try {
        console.log(`🔍 [NotificationController] Fetching notifications for user: ${req.user._id}`);
        const notifications = await Notification.find({ user: req.user._id })
            .sort({ createdAt: -1 })
            .limit(50);

        console.log(`✅ [NotificationController] Found ${notifications.length} notifications`);
        res.status(200).json({
            success: true,
            count: notifications.length,
            data: notifications
        });
    } catch (error) {
        console.error(`❌ [NotificationController] Error: ${error.message}`);
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Mark notification as seen
// @route   PUT /api/notifications/:id/seen
// @access  Private
exports.markAsSeen = async (req, res) => {
    try {
        const notification = await Notification.findOneAndUpdate(
            { _id: req.params.id, user: req.user._id },
            { seen: true, seenAt: Date.now() },
            { new: true }
        );

        if (!notification) {
            return res.status(404).json({ success: false, message: 'Notification not found' });
        }

        res.status(200).json({ success: true, data: notification });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Mark all as seen
// @route   PUT /api/notifications/mark-all-seen
// @access  Private
exports.markAllAsSeen = async (req, res) => {
    try {
        await Notification.updateMany(
            { user: req.user._id, seen: false },
            { seen: true, seenAt: Date.now() }
        );

        res.status(200).json({ success: true, message: 'All notifications marked as seen' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
