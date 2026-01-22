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

        // 1. Create Volumes
        const volumeNames = ['كرتونة', 'علبة', 'شريط', 'قرص', 'زجاجة', 'كيس', 'امبول', 'فيال'];
        const volumes = await Volume.insertMany(
            volumeNames.map(name => ({ name }))
        );
        const volumeMap = volumes.reduce((acc, v) => ({ ...acc, [v.name]: v._id }), {});
        console.log('📦 Volumes created');

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

        // 3. Create Products with Conversions
        // Helper to get random item from array
        const random = arr => arr[Math.floor(Math.random() * arr.length)];

        const productData = [
            {
                name: 'Panadol Extra',
                description: 'Pain reliever and fever reducer',
                activeIngredient: 'Paracetamol + Caffeine',
                conversions: [
                    { from: 'قرص', to: 'قرص', value: 1 }, // Base unit
                    { from: 'شريط', to: 'قرص', value: 10 },
                    { from: 'علبة', to: 'شريط', value: 2 }, // 2 strips per box = 20 tablets
                    { from: 'كرتونة', to: 'علبة', value: 50 }
                ]
            },
            {
                name: 'Augmentin 1g',
                description: 'Broad spectrum antibiotic',
                activeIngredient: 'Amoxicillin + Clavulanic acid',
                conversions: [
                    { from: 'قرص', to: 'قرص', value: 1 },
                    { from: 'شريط', to: 'قرص', value: 7 },
                    { from: 'علبة', to: 'شريط', value: 2 },
                    { from: 'كرتونة', to: 'علبة', value: 40 }
                ]
            },
            {
                name: 'Cataflam 50mg',
                description: 'Non-steroidal anti-inflammatory drug',
                activeIngredient: 'Diclofenac Potassium',
                conversions: [
                    { from: 'قرص', to: 'قرص', value: 1 },
                    { from: 'شريط', to: 'قرص', value: 10 },
                    { from: 'علبة', to: 'شريط', value: 2 }
                ]
            },
             {
                name: 'Omez 20mg',
                description: 'Proton pump inhibitor',
                activeIngredient: 'Omeprazole',
                 conversions: [
                    { from: 'كبسولة', to: 'كبسولة', value: 1 }, // assuming capsule is base like tablet
                     // mapping 'كبسولة' to 'قرص' conceptually for the seed or just use 'قرص' if volume not strictly typed as capsule
                    { from: 'شريط', to: 'قرص', value: 7 }, // mixed naming, let's stick to existing volumes
                    { from: 'علبة', to: 'شريط', value: 2 }
                ].map(c => c.from === 'كبسولة' || c.to === 'كبسولة' ? {...c, from: c.from==='كبسولة'?'قرص':c.from, to: c.to==='كبسولة'?'قرص':c.to} : c)
            },
            {
                name: 'Antinal',
                description: 'Intestinal antiseptic',
                activeIngredient: 'Nifuroxazide',
                conversions: [
                    { from: 'قرص', to: 'قرص', value: 1 },
                    { from: 'شريط', to: 'قرص', value: 12 },
                    { from: 'علبة', to: 'شريط', value: 2 }
                ]
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
                conversions: p.conversions
            });
            products.push(product);

            // Create HasVolume entries for each conversion unit available for the product
            for (const conv of p.conversions) {
                 if(volumeMap[conv.from]) {
                     // Calculate mock price based on value relative to base (value 1)
                     // Base price approx 5 EGP
                     const basePrice = 5;
                     
                     // We need the cumulative value for pricing references usually, 
                     // but here the conversion logic in the prompt ("higher to lower with value") 
                     // implies the value IS the multiplier.
                     // The prompt: "1-3 conversion the first one is the base volume, with a value 1 then from the higher quantity to the lower quantity with a vaue"
                     // My data: from: 'علبة', to: 'شريط', value: 2. This creates a chain.
                     // To simplify pricing for seed, allow me to estimate.
                     
                     let multiplier = 1;
                     // Simple logic: if value > 1, it's a bigger unit container.
                     // A real recursive calculator is overengineering for a seed.
                     // I'll assign price = value * 5. If it's a carton (value 50 relative to box?), it gets expensive.
                     
                     // Wait, my conversion structure in seed `conversions: [{ from: 'كرتونة', to: 'علبة', value: 50 }]`
                     // This means 1 Carton = 50 Boxes.
                     // If 1 Box = 2 Strips.
                     // If 1 Strip = 10 Tablets.
                     // Price should reflect total scale.
                     
                     // Let's just set arbitrary prices for the seed to look realistic enough.
                     let price = 10;
                     if (conv.from === 'قرص') price = 2;
                     if (conv.from === 'شريط') price = 20;
                     if (conv.from === 'علبة') price = 45;
                     if (conv.from === 'كرتونة') price = 1500;

                     await HasVolume.create({
                         product: product._id,
                         volume: volumeMap[conv.from],
                         value: conv.value, // This stores the direct conversion value as per schema
                         price: price
                     });
                 }
            }
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
                role: 'pharmacy_owner', // Mapping "manager" to owner role based on prompt context (admin + managers) usually implies the top level pharmacy user
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
