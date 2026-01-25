const rateLimit = require('express-rate-limit');

// Common message for all limiters
const limitMessage = {
    success: false,
    message: "You have been reloading the application many times, wait for 10 mins then try again"
};

// 1. General Limiter (GET requests - Loose loop)
// Allows frequent reading, e.g., 200 requests per 10 minutes
exports.getLimiter = rateLimit({
    windowMs: 10 * 60 * 1000, // 10 minutes
    max: 200, // Limit each IP to 200 requests per windowMs
    message: limitMessage,
    standardHeaders: true,
    legacyHeaders: false,
});

// 2. Strict Limiter (POST/PUT/DELETE - Moderate loop)
// For regular state-changing actions, e.g., 50 requests per 10 minutes
exports.strictLimiter = rateLimit({
    windowMs: 10 * 60 * 1000, // 10 minutes
    max: 50,
    message: limitMessage,
    standardHeaders: true,
    legacyHeaders: false,
});

// 3. Sensitive Limiter (Auth/Financial - Tight loop)
// For critical actions (login, payments, changing passwords), e.g., 10 requests per 10 minutes
exports.sensitiveLimiter = rateLimit({
    windowMs: 10 * 60 * 1000, // 10 minutes
    max: 10,
    message: limitMessage,
    standardHeaders: true,
    legacyHeaders: false,
});
