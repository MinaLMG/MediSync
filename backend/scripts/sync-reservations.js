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
            // Shortages don't inherently have expiryDate or salePercentage.
            // But if a reservation is created from a Shortage, what Expiry/Sale do we use?
            // "for the reservation, we will need to add expiry and sale fields, make sure you propagate this modification
            // update the sync-reservations to consider expiry and sale"
            
            // Wait. A SHORTAGE is a request. It doesn't have an expiry date or sale percentage (usually).
            // A Reservation is usually "I want this specific Excess".
            // If `sync-reservations` creates reservations based on SHORTAGES, it means it's auto-reserving?
            // "shortage.remainingQuantity" -> "Reservation".
            // If the shortage matches an Excess, we reserve it.
            // But here it iterates `shortages` and creates `Reservation`.
            // Does `StockShortage` have `expiryDate`? No.
            // Does `StockShortage` have `salePercentage`? No.
            
            // The prompt says: "update the sync-reservations to consider expiry and sale".
            // This implies the matching logic (Shortage vs Excess) needs to account for them.
            // BUT `sync-reservations.js` seems to be a cleanup/sync script?
            // Let's look at lines 27-31: It finds `old` reservation based on product/volume/price.
            // It seems it treats Shortage.targetPrice as the reservation price.
            
            // If the user wants to reserve a specific batch (Expiry/Sale), the Shortage needs to specify it?
            // OR `sync-reservations` is syncing from *Orders*? 
            // Line 19: `order: { $ne: null }`.
            // It seems to be syncing Shortages linked to Orders into Reservations.
            
            // Problem: Orders/Shortages might NOT have expiry/sale info if they are generic requests.
            // IF the user selects a specific batch in the UI (as requested), the Order/Shortage MUST capture that info.
            // "When I click it, I see all available prices... then expiry... then choose quantity".
            // This implies the OrderItem or Shortage MUST store the selected Expiry/Sale.
            
            // I need to update `StockShortage` model to optionally store `expiryDate` and `salePercentage`?
            // Or `Order` model?
            // If `sync-reservations` reads from `StockShortage`, then `StockShortage` needs these fields.
            
            // Let's assume for now I need to add `expiryDate` and `salePercentage` to `StockShortage` too?
            // Or just default them if missing (which breaks the specific reservation).
            
            // I will check `StockShortage` model first. If it lacks these, I need to add them.
            // For now, I'll update the script to READ them from shortage (assuming they will exist) 
            // and use them in `Reservation`.
            
            // Shortages are requests and do not have specific expiry/sale.
            // We use generic values for the reservation.
            // Use stored expiry/sale if available (Market Order), else defaults (Request)
            const expiryDate = shortage.expiryDate || "ANY";
            const salePercentage = shortage.originalSalePercentage || shortage.salePercentage || 0;

            const old = await Reservation.findOne({
                product: shortage.product,
                volume: shortage.volume,
                price: shortage.targetPrice,
                expiryDate: expiryDate,
                salePercentage: salePercentage
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
                expiryDate: expiryDate,
                salePercentage: salePercentage
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
