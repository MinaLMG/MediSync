require('dotenv').config();
const { Worker } = require('bullmq');
const { redisConnection } = require('./src/utils/queueManager');
const { sendToUser } = require('./src/utils/pusherManager');
const connectDB = require('./src/db/mongoose');
const Notification = require('./src/models/Notification');

// Connect to Database
// Only connect if we're not already connected (prevents warnings when required in app.js)
if (require('mongoose').connection.readyState === 0) {
    connectDB();
}

const { PharmacyQuota } = require('./src/models');

console.log('👷 Notification Worker initialized...');

// Daily clean up for expired Pharmacy Quota records
const dailyQuotaCleanup = async () => {
    try {
        console.log('🧹 Running daily PharmacyQuota cleanup...');
        const now = new Date();
        const result = await PharmacyQuota.deleteMany({ recordExpiryDate: { $lte: now } });
        console.log(`✅ Cleanup complete. Deleted ${result.deletedCount} expired records.`);
    } catch (error) {
        console.error('❌ Error during PharmacyQuota cleanup:', error);
    }
};

// Schedule cleanup to run at the start of every day (midnight)
const scheduleDailyCleanup = () => {
    const now = new Date();
    const nextMidnight = new Date(now);
    nextMidnight.setHours(24, 0, 0, 0); // Sets to 00:00:00:000 of the next day

    const timeUntilMidnight = nextMidnight.getTime() - now.getTime();
    console.log(`⏰ Daily PharmacyQuota cleanup scheduled in ${Math.round(timeUntilMidnight / 1000 / 60)} minutes.`);

    setTimeout(() => {
        dailyQuotaCleanup();
        // After the first midnight run, repeat every 24 hours
        setInterval(dailyQuotaCleanup, 24 * 60 * 60 * 1000);
    }, timeUntilMidnight);
};

// 1. Run once immediately on startup to clear any records that expired while worker was down
dailyQuotaCleanup();

// 2. Schedule to run at the start of every day
scheduleDailyCleanup();

const worker = new Worker('notificationQueue', async (job) => {
    console.log('📦 Job received:', job.id, job.name);
    const { userId, type, message, message_ar, relatedEntity, relatedEntityType, actionUrl, priority } = job.data;

    console.log(`Processing notification for user: ${userId}, Type: ${type}`);

    try {
        // 1. Persist notification in DB
        const notification = await Notification.create({
            user: userId,
            type,
            message,
            message_ar,
            relatedEntity,
            relatedEntityType,
            actionUrl,
            priority: priority || 'normal'
        });

        console.log(`✅ Saved notification ${notification._id} to database`);

        // 2. Push to connected user via Pusher (non-critical)
        try {
            sendToUser(userId.toString(), 'notification', notification);
            console.log(`📡 Emitted real-time event to user: ${userId}`);
        } catch (pusherError) {
            // Log but don't fail the job - notification is already in DB
            console.error(`⚠️ Pusher notification failed (non-critical):`, pusherError);
        }

        return notification;
    } catch (error) {
        console.error('Worker error processing notification:', error);
        throw error; // Let BullMQ handle retry
    }
}, {
    connection: redisConnection
});

worker.on('completed', (job) => {
    console.log(`Job completed: ${job.id}`);
});

worker.on('failed', (job, err) => {
    console.log(`Job failed: ${job.id} with error: ${err.message}`);
});
