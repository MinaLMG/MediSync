const rateLimit = require('express-rate-limit');

// Common message for all limiters
const limitMessage = {
    success: false,
    message: "You have been reloading the application many times, wait for 10 mins then try again"
};

// 1. General Limiter (GET requests - Loose loop)
exports.getLimiter = rateLimit({
    windowMs: 10 * 60 * 1000, 
    max: process.env.NODE_ENV === 'test' ? 10000 : 200, 
    message: limitMessage,
    standardHeaders: true,
    legacyHeaders: false,
});

// 2. Strict Limiter (POST/PUT/DELETE - Moderate loop)
exports.strictLimiter = rateLimit({
    windowMs: 10 * 60 * 1000,
    max: process.env.NODE_ENV === 'test' ? 10000 : 50,
    message: limitMessage,
    standardHeaders: true,
    legacyHeaders: false,
});

// 3. Sensitive Limiter (Auth/Financial - Tight loop)
exports.sensitiveLimiter = rateLimit({
    windowMs: 10 * 60 * 1000,
    max: process.env.NODE_ENV === 'test' ? 10000 : 10,
    message: limitMessage,
    standardHeaders: true,
    legacyHeaders: false,
});
