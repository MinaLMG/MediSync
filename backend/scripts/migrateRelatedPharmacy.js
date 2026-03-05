const mongoose = require('mongoose');
require('dotenv').config();
const connectDB = require('../src/db/mongoose');
const { StockExcess, Transaction } = require('../src/models');

const migrateRelatedPharmacy = async () => {
    try {
        console.log('🚀 [Migration] Starting relatedPharmacy backfill...');

        // Connect to DB
        await connectDB();

        // 1. Find transactions that resulted in hub stock creation
        const transactions = await Transaction.find({
            'added_to_hub.excessId': { $exists: true }
        }).populate('stockExcessSources.stockExcess');

        console.log(`🔍 [Migration] Found ${transactions.length} transfer transactions to process.`);

        let updatedCount = 0;
        let skippedCount = 0;

        for (const tx of transactions) {
            if (!tx.added_to_hub || !tx.added_to_hub.excessId) continue;

            // The original pharmacy is the owner of the source excess
            const sourceExcess = tx.stockExcessSources[0] ? tx.stockExcessSources[0].stockExcess : null;
            const excess = await StockExcess.findById(sourceExcess);
            if (excess && excess.pharmacy) {
                const originalPharmacyId = excess.pharmacy;
                const hubExcessId = tx.added_to_hub.excessId;

                // Update the hub excess if it exists and doesn't already have relatedPharmacy
                const hubExcess = await StockExcess.findById(hubExcessId);
                console.log(`🔍 [Migration] Hub excess found: ${hubExcess}`);
                if (hubExcess && !hubExcess.relatedPharmacy) {
                    await StockExcess.findByIdAndUpdate(hubExcessId, {
                        relatedPharmacy: originalPharmacyId
                    });
                    updatedCount++;
                } else {
                    skippedCount++;
                }
            } else {
                skippedCount++;
                console.warn(`⚠️ [Migration] Missing source pharmacy for Transaction ${tx._id}`);
            }
        }

        console.log(`✅ [Migration] Complete. Updated: ${updatedCount}, Skipped/Already Set: ${skippedCount}`);

        process.exit(0);
    } catch (error) {
        console.error('❌ [Migration] Error during relatedPharmacy backfill:', error);
        process.exit(1);
    }
};

migrateRelatedPharmacy();
