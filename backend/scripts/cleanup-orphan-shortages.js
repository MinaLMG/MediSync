const mongoose = require('mongoose');
require('dotenv').config();
const connectDB = require('../src/db/mongoose');
const { StockShortage, Order } = require('../src/models');

const cleanupOrphanShortages = async () => {
    try {
        console.log('🚀 Starting orphan shortage cleanup...');
        
        // Connect to DB
        await connectDB();
        
        console.log('🔍 Finding shortages with order associations...');
        const shortagesWithOrders = await StockShortage.find({
            order: { $ne: null }
        });
        
        console.log(`📝 Found ${shortagesWithOrders.length} shortages with order IDs. Checking if orders exist...`);
        
        let removedCount = 0;
        let checkedCount = 0;

        for (const shortage of shortagesWithOrders) {
            checkedCount++;
            
            // Check if order exists
            const orderExists = await Order.exists({ _id: shortage.order });
            
            if (!orderExists) {
                console.log(`🗑️ Removing orphan shortage ${shortage._id} (Order ${shortage.order} not found)`);
                await StockShortage.findByIdAndDelete(shortage._id);
                removedCount++;
            }
            
            if (checkedCount % 10 === 0) {
                console.log(`⏳ Checked ${checkedCount}/${shortagesWithOrders.length} shortages...`);
            }
        }
        
        console.log('\n✨ Cleanup complete!');
        console.log(`📊 Summary:`);
        console.log(`- Shortages checked: ${shortagesWithOrders.length}`);
        console.log(`- Orphan shortages removed: ${removedCount}`);
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error during cleanup:', error);
        process.exit(1);
    }
};

cleanupOrphanShortages();
