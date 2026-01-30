const mongoose = require('mongoose');
require('dotenv').config({ path: '.env' });
const connectDB = require('../db/mongoose');
const { Product, HasVolume } = require('../models');

const deleteProductsAfterDate = async () => {
    try {
        await connectDB();
        //TODO: choose date"
        // const cutoffDate = new Date("2026-01-29T22:12:50.111+00:00")
        console.log(`🧹 Searching for products created after: ${cutoffDate.toISOString()}`);

        // Find products to delete
        const productsToDelete = await Product.find({
            createdAt: { $gt: cutoffDate }
        });

        if (productsToDelete.length === 0) {
            console.log('✅ No products found matching the criteria.');
            process.exit(0);
        }

        const productIds = productsToDelete.map(p => p._id);
        console.log(`🔍 Found ${productIds.length} products to delete.`);

        // Delete associated HasVolume records
        const volumeDeleteResult = await HasVolume.deleteMany({
            product: { $in: productIds }
        });
        console.log(`🗑️ Deleted ${volumeDeleteResult.deletedCount} associated HasVolume records.`);

        // Delete the products
        const productDeleteResult = await Product.deleteMany({
            _id: { $in: productIds }
        });
        console.log(`🗑️ Deleted ${productDeleteResult.deletedCount} products.`);

        console.log('✨ Cleanup completed successfully!');
        process.exit(0);

    } catch (error) {
        console.error('❌ Error during cleanup:', error.message);
        process.exit(1);
    }
};

deleteProductsAfterDate();
