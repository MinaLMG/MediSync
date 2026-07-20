const admin = require('firebase-admin');
const path = require('path');
const { User } = require('../models');

class FcmManager {
    constructor() {
        this.isInitialized = false;
        this._initializeFirebase();
    }

    _initializeFirebase() {
        try {
            const credentialsEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
            if (credentialsEnv) {
                let serviceAccount;
                const trimmed = credentialsEnv.trim();
                
                // Support both inline JSON string and file path
                if (trimmed.startsWith('{')) {
                    serviceAccount = JSON.parse(trimmed);
                } else {
                    // It is a file path
                    const absolutePath = path.isAbsolute(trimmed) 
                        ? trimmed 
                        : path.resolve(process.cwd(), trimmed);
                    serviceAccount = require(absolutePath);
                }

                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount)
                });

                this.isInitialized = true;
                console.log('📬 [FcmManager] Firebase Admin SDK initialized successfully.');
            } else {
                console.warn('⚠️ [FcmManager] FIREBASE_SERVICE_ACCOUNT not configured. FCM push notifications disabled.');
            }
        } catch (error) {
            console.error('❌ [FcmManager] Failed to initialize Firebase Admin:', error);
        }
    }

    /**
     * Sends a push notification to all FCM tokens registered to the user
     * @param {string} userId - User Mongoose ID
     * @param {string} title - Notification title
     * @param {string} body - Notification body/content
     * @param {string} [titleAr] - Optional notification title in Arabic
     * @param {string} [bodyAr] - Optional notification body/content in Arabic
     * @param {Object} [data] - Optional metadata payload (must contain string values)
     */
    async sendFcmNotification(userId, title, body, titleAr = null, bodyAr = null, data = {}) {
        try {
            const user = await User.findById(userId);
            if (!user) {
                console.warn(`[FcmManager] User ${userId} not found.`);
                return;
            }

            if (!user.fcmTokens || user.fcmTokens.length === 0) {
                // No active FCM tokens for this user
                return;
            }

            const isArabic = user.language === 'ar';
            const selectedTitle = (isArabic && titleAr) ? titleAr : (title || 'MediSync');
            const selectedBody = (isArabic && bodyAr) ? bodyAr : body;

            if (!this.isInitialized) {
                console.log(`[FcmManager MOCK] User: ${user.email} (Lang: ${user.language}) | Title: ${selectedTitle} | Body: ${selectedBody}`);
                return;
            }

            const invalidTokens = [];
            const sanitizedData = {};
            
            // Firebase data payload values must be strings
            if (data) {
                for (const key in data) {
                    if (data[key] !== undefined && data[key] !== null) {
                        sanitizedData[key] = String(data[key]);
                    }
                }
            }

            const sendPromises = user.fcmTokens.map(async (token) => {
                try {
                    const message = {
                        token: token,
                        notification: {
                            title: selectedTitle,
                            body: selectedBody,
                        },
                        data: sanitizedData,
                        android: {
                            priority: 'high',
                            notification: {
                                channelId: 'app_alerts_channel',
                                sound: 'default',
                            }
                        },
                        apns: {
                            payload: {
                                aps: {
                                    sound: 'default',
                                    badge: 1,
                                }
                            }
                        },
                        webpush: {
                            headers: {
                                Urgency: 'high'
                            },
                            notification: {
                                body: selectedBody,
                                icon: '/favicon.png'
                            }
                        }
                    };

                    await admin.messaging().send(message);
                    console.log(`📬 [FcmManager] FCM Alert successfully pushed to ${user.email} for token beginning with ${token.substring(0, 12)}...`);
                } catch (error) {
                    // Check if token is dead/expired
                    if (
                        error.code === 'messaging/registration-token-not-registered' ||
                        error.code === 'messaging/invalid-registration-token'
                    ) {
                        invalidTokens.push(token);
                    } else {
                        console.error(`❌ [FcmManager] FCM transmission issue with token ${token.substring(0, 10)}:`, error.message);
                    }
                }
            });

            await Promise.all(sendPromises);

            // Clean up invalid tokens
            if (invalidTokens.length > 0) {
                await User.findByIdAndUpdate(userId, {
                    $pull: { fcmTokens: { $in: invalidTokens } }
                });
                console.log(`🧹 [FcmManager] Cleaned up ${invalidTokens.length} stale/invalid FCM tokens from User ${user.email}.`);
            }
        } catch (error) {
            console.error('❌ [FcmManager] Error during sendFcmNotification:', error);
        }
    }
}

module.exports = new FcmManager();
