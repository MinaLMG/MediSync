const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: '.env' });

const {
    Pharmacy,
    User,
    Category,
    Manufacturer,
    Product,
    Volume,
    HasVolume
} = require('../models');

const connectDB = require('./mongoose');

const seedData = async () => {
    try {
        await connectDB();
        console.log('🌱 Connected to database for seeding...');

        // Clear existing data
        await Promise.all([
            Pharmacy.deleteMany({}),
            User.deleteMany({}),
            Category.deleteMany({}),
            Manufacturer.deleteMany({}),
            Product.deleteMany({}),
            Volume.deleteMany({}),
            HasVolume.deleteMany({})
        ]);
        console.log('🧹 Cleared existing data');

        // 1. Create Volume (Only 'unit')
        const unitVolume = await Volume.create({ name: 'unit' });
        const unitId = unitVolume._id;
        console.log('📦 Volume "unit" created');

        // 2. Products Data (Simplified)
        const productData = [
            { name: 'Panadol Extra', description: 'Pain reliever and fever reducer' },
            { name: 'Augmentin 1g', description: 'Broad spectrum antibiotic' },
            { name: 'Cataflam 50mg', description: 'Non-steroidal anti-inflammatory drug' },
            { name: 'Omez 20mg', description: 'Proton pump inhibitor' },
            { name: 'Antinal', description: 'Intestinal antiseptic' }
        ];

        const products = [];
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
            products.push(product);

            await HasVolume.create({
                product: product._id,
                volume: unitId,
                value: 1, 
                prices: [50, 45, 55]
            });
        }
        console.log('💊 Products & HasVolumes created');

        // 4. Create Pharmacies
        const pharmacies = [];
        const governorates = ['Cairo', 'Giza', 'Alexandria'];
        
        for (let i = 1; i <= 10; i++) {
            const pharmacy = await Pharmacy.create({
                name: `Pharmacy ${i}`,
                phone: `010000000${i < 10 ? '0' + i : i}`,
                email: `pharmacy${i}@medisync.com`,
                ownerName: `Owner ${i}`,
                nationalId: `290010112345${i < 10 ? '0' + i : i}`,
                pharmacistCard: `1234${i}`,
                commercialRegistry: `5678${i}`,
                taxCard: `9101${i}`,
                pharmacyLicense: `1122${i}`,
                address: `Maadi - Street ${i}`,
                location: {
                    type: 'Point',
                    coordinates: [31.2357 + (Math.random() * 0.1), 30.0444 + (Math.random() * 0.1)]
                },
                status: 'active',
                verified: true,
                rating: 4.5
            });
            pharmacies.push(pharmacy);
        }
        console.log('🏥 10 Pharmacies created');

        // 5. Create Users (1 Admin + 10 Managers)
        // Admin
        await User.create({
            name: 'Super Admin',
            phone: '01000000000',
            email: 'admin@medisync.com',
            hashedPassword: 'password123', // Will be hashed by pre-save hook
            role: 'admin',
            status: 'active'
        });

        // Managers
        for (let i = 0; i < 10; i++) {
            await User.create({
                name: `Manager ${i + 1}`,
                phone: pharmacies[i].phone, // Using pharmacy phone for simplicity
                email: `manager${i + 1}@medisync.com`,
                hashedPassword: 'password123',
                role: 'pharmacy_owner', 
                pharmacy: pharmacies[i]._id,
                status: 'active'
            });
        }
        console.log('👥 Users created (1 Admin + 10 Managers)');

        console.log('✅ Seeding completed successfully!');
        process.exit(0);

    } catch (error) {
        console.error('❌ Seeding failed:', error);
        process.exit(1);
    }
};

seedData();
