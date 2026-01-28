const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: '.env' });

const {
    Pharmacy,
    User,
    Product,
    Volume,
    HasVolume,
    StockShortage,
    StockExcess,
    Transaction,
    BalanceHistory,
    AppSuggestion,
    Notification,
} = require('../models');

const connectDB = require('./mongoose');

const seedData = async () => {
    try {
        await connectDB();
        console.log('🌱 Connected to database for seeding...');
        const p =  await Transaction.find({})
        console.log(p)
       

    } catch (error) {
        console.error('❌ Seeding failed:', error);
        process.exit(1);
    }
};

seedData();
