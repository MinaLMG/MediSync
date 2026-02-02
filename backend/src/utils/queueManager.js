const { Queue } = require('bullmq');
const Redis = require('ioredis');

// Redis connection configuration
const redisConnection = new Redis("rediss://default:" + process.env.REDIS_TOKEN + "@exciting-ewe-18750.upstash.io:6379", {
    maxRetriesPerRequest: null,
    retryStrategy(times) {
        const delay = Math.min(times * 50, 2000);
        return delay;
    }
});

redisConnection.on('error', (err) => {
    console.error('[QueueManager] ❌ Redis Connection Error:', err.message);
    // Prevent usage if connection failed to avoid further errors? 
    // ioredis handles reconnection automatically.
});

// Create the notification queue
const notificationQueue = new Queue('notificationQueue', {
    connection: redisConnection
});

/**
 * Adds a notification job to the queue
 * @param {string} userId - ID of the user to receive the notification
 * @param {string} type - Notification type (transaction, message, alert, system)
 * @param {string} message - The notification message
 * @param {Object} metadata - Additional info (relatedEntityId, actionUrl, etc.)
 */
const addNotificationJob = async (userId, type, message, metadata = {}, messageAr = null) => {
    try {
        await notificationQueue.add('sendNotification', {
            userId,
            type,
            message,
            message_ar: messageAr,
            ...metadata
        }, {
            attempts: 3,
            backoff: {
                type: 'exponential',
                delay: 1000,
            }
        });
        console.log(`[QueueManager] 📤 Job added to queue 'sendNotification' | User: ${userId} | Type: ${type}`);
    } catch (error) {
        console.error('[QueueManager] ❌ Error adding job:', error);
    }
};

module.exports = {
    addNotificationJob,
    redisConnection
};
