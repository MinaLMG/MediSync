const mongoose = require('mongoose');
require('dotenv').config();
const connectDB = require('../src/db/mongoose');
const { Transaction } = require('../src/models');

/**
 * Cleanup Script: Resets balanceEffect to 0 for all existing cancelled/rejected transactions.
 * This ensures data consistency with the new two-phase settlement logic.
 */
const cleanupTransactionBalances = async () => {
    try {
        console.log('🚀 Starting transaction balance cleanup...');
        
        // Connect to DB
        await connectDB();
        
        console.log('🔍 Finding cancelled or rejected transactions...');
        
        // Update all identified transactions in a single operation
        const result = await Transaction.updateMany(
            { status: { $in: ['cancelled', 'rejected'] } },
            { 
                $set: { 
                    "stockShortage.balanceEffect": 0,
                    "stockExcessSources.$[].balanceEffect": 0 
                } 
            }
        );
        
        console.log(`\n✨ Cleanup complete!`);
        console.log(`📊 Summary:`);
        console.log(`- Transactions matched: ${result.matchedCount}`);
        console.log(`- Transactions modified: ${result.modifiedCount}`);
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error during cleanup:', error);
        process.exit(1);
    }
};

cleanupTransactionBalances();
