const mongoose = require('mongoose');
require('dotenv').config();
const connectDB = require('../src/db/mongoose');
const { StockExcess, Settings } = require('../src/models');

const migrateExcessSales = async () => {
    try {
        console.log('🚀 Starting StockExcess sale percentage migration...');
        
        // Connect to DB
        await connectDB();
        
        // Get system minimum commission
        const settings = await Settings.getSettings();
        const minComm = settings.minimumCommission || 10;
        console.log(`ℹ️ System minimum commission is ${minComm}%`);
        
        // Find excesses with null salePercentage
        // Note: Using $or to catch both explicit nulls and missing fields
        const query = {
            $or: [
                { salePercentage: null },
                { salePercentage: { $exists: false } }
            ]
        };
        
        const count = await StockExcess.countDocuments(query);
        console.log(`🔍 Found ${count} records with null or missing salePercentage.`);
        
        if (count === 0) {
            console.log('✅ No records need migration. Exiting.');
            process.exit(0);
        }

        // Update records
        const result = await StockExcess.updateMany(
            query,
            { $set: { salePercentage: minComm } }
        );
        
        console.log(`\n✨ Migration complete!`);
        console.log(`📊 Summary:`);
        console.log(`- Records matched: ${result.matchedCount}`);
        console.log(`- Records updated: ${result.modifiedCount}`);
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error during migration:', error);
        process.exit(1);
    }
};

migrateExcessSales();
