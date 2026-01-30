const Pusher = require('pusher');

let pusher;

/**
 * Initialize Pusher
 */
const initPusher = () => {
    if (!pusher) {
        pusher = new Pusher({
            appId: process.env.PUSHER_APP_ID,
            key: process.env.PUSHER_KEY,
            secret: process.env.PUSHER_SECRET,
            cluster: process.env.PUSHER_CLUSTER,
            useTLS: true,
        });
        console.log('🚀 [PusherManager] Initialized');
    }
    return pusher;
};

/**
 * Send event to a specific user via private channel
 * @param {string} userId - User ID
 * @param {string} event - Event name
 * @param {Object} data - Event data
 */
const sendToUser = async (userId, event, data) => {
    const p = initPusher();
    try {
        console.log(`📡 [PusherManager] 🚀 Triggering '${event}' for user: ${userId} on channel 'private-user-${userId}'`);
        // We use private channels per user: private-user-{userId}
        await p.trigger(`private-user-${userId}`, event, data);
    } catch (error) {
        console.error(`❌ [PusherManager] Error triggering event: ${error.message}`);
    }
};

/**
 * Broadcast event to a specific channel
 * @param {string} channel - Channel name
 * @param {string} event - Event name
 * @param {Object} data - Event data
 */
const broadcast = async (channel, event, data) => {
    const p = initPusher();
    try {
        console.log(`📡 [PusherManager] Broadcasting '${event}' to channel '${channel}'`);
        await p.trigger(channel, event, data);
    } catch (error) {
        console.error(`❌ [PusherManager] Error broadcasting event: ${error.message}`);
    }
};

module.exports = {
    initPusher,
    sendToUser,
    broadcast
};
