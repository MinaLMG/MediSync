require('dotenv').config();
const { Worker } = require('bullmq');
const { redisConnection } = require('./src/utils/queueManager');
const { sendToUser } = require('./src/utils/socketManager');
const connectDB = require('./src/db/mongoose');
const Notification = require('./src/models/Notification');

// Connect to Database
// Only connect if we're not already connected (prevents warnings when required in app.js)
if (require('mongoose').connection.readyState === 0) {
    connectDB();
}

console.log('👷 Notification Worker initialized...');

const worker = new Worker('notificationQueue', async (job) => {
    console.log('📦 Job received:', job.id, job.name);
    const { userId, type, message, relatedEntity, relatedEntityType, actionUrl, priority } = job.data;
    
    console.log(`Processing notification for user: ${userId}, Type: ${type}`);

    try {
        // 1. Persist notification in DB
        const notification = await Notification.create({
            user: userId,
            type,
            message,
            relatedEntity,
            relatedEntityType,
            actionUrl,
            priority: priority || 'normal'
        });

        console.log(`✅ Saved notification ${notification._id} to database`);

        // 2. Push to connected user via Socket.io
        sendToUser(userId.toString(), 'notification', notification);
        console.log(`📡 Emitted real-time event to user: ${userId}`);
        
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
