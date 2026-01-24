const express = require('express');
const path = require('path');
const cors = require('cors');
require('dotenv').config();
const connectDB = require('./src/db/mongoose');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static folder for uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Connect to MongoDB
connectDB();

// Health check route
app.get('/health', (req, res) => {
    res.status(200).json({ 
        status: 'OK', 
        message: 'MediSync API is running',
        timestamp: new Date().toISOString()
    });
});

// API Routes
app.use('/api/auth', require('./src/routes/authRoutes'));
app.use('/api/settings', require('./src/routes/settingsRoutes'));
app.use('/api/products', require('./src/routes/productRoutes'));
app.use('/api/excess', require('./src/routes/excessRoutes'));
app.use('/api/shortage', require('./src/routes/shortageRoutes'));
app.use('/api/orders', require('./src/routes/orderRoutes'));
app.use('/api/transaction', require('./src/routes/transactionRoutes'));
app.use('/api/admin', require('./src/routes/adminRoutes'));
app.use('/api/notifications', require('./src/routes/notificationRoutes'));

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found'
    });
});

const PORT = process.env.PORT || 5000;
const server = require('http').createServer(app);

// Initialize Socket.io
const { initSocket } = require('./src/utils/socketManager');
initSocket(server);

// Start the background notification worker
require('./worker');

server.listen(PORT, () => {
    console.log(`🚀 MediSync server is running on port ${PORT}`);
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
