const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: '.env' });

const {
    Product,
    HasVolume,
} = require('../models');

const connectDB = require('./mongoose');

const seedData = async () => {
    try {
        await connectDB();
        console.log('🌱 Connected to database for seeding...');
        // const unitId =  "6978bcc2f4b109cecfd29d4a"//staging db
        // const unitId =  "697927bdbb599cc986040bdc"//dev db

        // 2. Products Data (Simplified)
                const inputPath = path.join(__dirname, '../db/products_full_simple.json');
        
                console.log(`📖 Reading ${inputPath}...`);
                const fileContent = fs.readFileSync(inputPath, 'utf8');
        const productData =JSON.parse(fileContent);

        for (const p of productData) {
            const product = await Product.create({
                name: p.name,
                description: p.description,
                conversions: [
                    { 
                        from: unitId.toString(), 
                        to: unitId.toString(), 
                        value: 1 
                    }
                ]
            });

            await HasVolume.create({
                product: product._id,
                volume: unitId,
                value: 1, 
                prices: [p.price]
            });
        }
        console.log('💊 Products & HasVolumes created');

   

        console.log('✅ Seeding completed successfully!');
        process.exit(0);

    } catch (error) {
        console.error('❌ Seeding failed:', error);
        process.exit(1);
    }
};

seedData();
