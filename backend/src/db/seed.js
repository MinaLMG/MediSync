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

        // 2. Create Categories & Manufacturers
        const categories = await Category.insertMany([
            { name: 'Antibiotics', nameAr: 'مضاد حيوي', description: 'Fight bacterial infections', icon: 'pill' },
            { name: 'Painkillers', nameAr: 'مسكنات', description: 'Relieve pain', icon: 'analgesic' },
            { name: 'Vitamins', nameAr: 'فيتامينات', description: 'Nutritional supplements', icon: 'vitamin' }
        ]);

        const manufacturers = await Manufacturer.insertMany([
            { name: 'Pharco', nameAr: 'فاركو', country: 'Egypt' },
            { name: 'Eipico', nameAr: 'يبيكو', country: 'Egypt' },
            { name: 'Amoun', nameAr: 'آمون', country: 'Egypt' },
            { name: 'Pfizer', nameAr: 'فايزر', country: 'USA' }
        ]);
        console.log('🏭 Categories & Manufacturers created');

        // 3. Create Products with Simplified Conversions
        // Helper to get random item from array
        const random = arr => arr[Math.floor(Math.random() * arr.length)];

        const productData = [
            {
                name: 'Panadol Extra',
                description: 'Pain reliever and fever reducer',
                activeIngredient: 'Paracetamol + Caffeine',
            },
            {
                name: 'Augmentin 1g',
                description: 'Broad spectrum antibiotic',
                activeIngredient: 'Amoxicillin + Clavulanic acid',
            },
            {
                name: 'Cataflam 50mg',
                description: 'Non-steroidal anti-inflammatory drug',
                activeIngredient: 'Diclofenac Potassium',
            },
             {
                name: 'Omez 20mg',
                description: 'Proton pump inhibitor',
                activeIngredient: 'Omeprazole',
            },
            {
                name: 'Antinal',
                description: 'Intestinal antiseptic',
                activeIngredient: 'Nifuroxazide',
            }
        ];

        const products = [];
        for (const p of productData) {
            const product = await Product.create({
                name: p.name,
                description: p.description,
                activeIngredient: p.activeIngredient,
                manufacturer: random(manufacturers)._id,
                category: random(categories)._id,
                // Simplified conversions: One item, 'unit' (reference id), value 1
                conversions: [
                    { 
                        from: unitId.toString(), 
                        to: unitId.toString(), 
                        value: 1 
                    }
                ]
            });
            products.push(product);

            // Create HasVolume entry: One volume 'unit', val 1
            await HasVolume.create({
                product: product._id,
                volume: unitId,
                value: 1, 
                prices: [50, 45, 55] // Example array of prices
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
                address: {
                    street: `Street ${i}`,
                    city: 'Maadi',
                    governorate: random(governorates),
                    postalCode: '11431'
                },
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
