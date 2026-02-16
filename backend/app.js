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
app.use('/api/requests-history', require('./src/routes/requestsHistoryRoutes'));
app.use('/api/transaction', require('./src/routes/transactionRoutes'));
app.use('/api/admin', require('./src/routes/adminRoutes'));
app.use('/api/notifications', require('./src/routes/notificationRoutes'));
app.use('/api/suggestions', require('./src/routes/suggestionRoutes'));
app.use('/api/delivery-requests', require('./src/routes/deliveryRequestRoutes'));
app.use('/api/balance-history', require('./src/routes/balanceHistoryRoutes'));
app.use('/api/compensation', require('./src/routes/compensationRoutes'));
app.use('/api/pusher', require('./src/routes/pusherRoutes'));
app.use('/api/payment', require('./src/routes/paymentRoutes'));
app.use('/api/owners', require('./src/routes/ownerRoutes'));
app.use('/api/owner-payments', require('./src/routes/ownerPaymentRoutes'));
app.use('/api/purchase-invoices', require('./src/routes/purchaseInvoiceRoutes'));
app.use('/api/sales-invoices', require('./src/routes/salesInvoiceRoutes'));
app.use('/api/summaries', require('./src/routes/summaryRoutes'));

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

// Start the background notification worker
require('./worker');

app.listen(PORT, () => {
    console.log(`🚀 MediSync server is running on port ${PORT}`);
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
