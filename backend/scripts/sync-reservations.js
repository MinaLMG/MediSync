const mongoose = require('mongoose');
require('dotenv').config();
const connectDB = require('../src/db/mongoose');
const { StockShortage, Reservation } = require('../src/models');

const syncReservations = async () => {
    try {
        console.log('🚀 Starting reservation synchronization...');
        
        // Connect to DB
        await connectDB();
        
        console.log('🧹 Clearing existing reservations to ensure fresh sync...');
        await Reservation.deleteMany({});
        
        console.log('🔍 Finding active shortages with order associations...');
        const shortages = await StockShortage.find({
            remainingQuantity: { $gt: 0 },
            order: { $ne: null },
            targetPrice: { $ne: null }
        });
        
        console.log(`📝 Found ${shortages.length} shortages to process.`);
        
        let createdCount = 0;
        for (const shortage of shortages) {
            const old = await Reservation.findOne({
                product: shortage.product,
                volume: shortage.volume,
                price: shortage.targetPrice,
            })
            if (old) {
                old.quantity += shortage.remainingQuantity;
                await old.save();
                continue;
            }
            // Recreate reservation for the remaining quantity
            await Reservation.create({
                product: shortage.product,
                volume: shortage.volume,
                price: shortage.targetPrice,
                quantity: shortage.remainingQuantity,
            });
            createdCount++;
            
            if (createdCount % 10 === 0) {
                console.log(`✅ Processed ${createdCount}/${shortages.length} shortages...`);
            }
        }
        
        console.log('\n✨ Synchronization complete!');
        console.log(`📊 Summary:`);
        console.log(`- Shortages processed: ${shortages.length}`);
        console.log(`- Reservations created: ${createdCount}`);
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error during synchronization:', error);
        process.exit(1);
    }
};

syncReservations();
