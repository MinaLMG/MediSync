const { User } = require('../models');
const { addNotificationJob } = require('./queueManager');

/**
 * Utility to notify all active admin users via bulk enqueuing.
 * @param {string} type - Notification type (transaction, message, alert, system)
 * @param {string} message - Notification message in English
 * @param {Object} metadata - Optional metadata (relatedEntity, actionUrl, etc.)
 * @param {string} messageAr - Notification message in Arabic
 */
const notifyAdmins = async (type, message, metadata = {}, messageAr = null) => {
    try {
        const admins = await User.find({ role: 'admin', status: 'active' });
        if (!admins || admins.length === 0) {
            console.log('[AdminNotifier] ⚠️ No active admins found to notify.');
            return;
        }

        const promises = admins.map(admin => 
            addNotificationJob(admin._id.toString(), type, message, metadata, messageAr)
        );

        await Promise.all(promises);
        console.log(`[AdminNotifier] 📢 Queued system notification for ${admins.length} admins.`);
    } catch (error) {
        console.error('[AdminNotifier] ❌ Error notifying admins:', error);
    }
};

module.exports = {
    notifyAdmins
};