const mongoose = require('mongoose');
const XLSX = require('xlsx');
const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: '.env' });

const {
    User,
    Pharmacy,
    Product,
    Volume,
    HasVolume,
    StockExcess
} = require('../models');

const connectDB = require('./mongoose');

const EXCEL_FILE_PATH = path.join(__dirname, 'Market Excesses Export_1774876534355.xlsx');

const restoreFromExcel = async () => {
    try {
        await connectDB();
        console.log('🌱 Connected to database for restoration...');

        // 1. Setup default Volume
        console.log('📦 Setting up default Volume...');
        let unitVolume = await Volume.findOne({ name: 'Unit' });
        if (!unitVolume) {
            unitVolume = await Volume.create({ name: 'Unit' });
        }
        const unitId = unitVolume._id;

        // 2. Setup Hub Pharmacy & User
        console.log('🏢 Setting up Hub Pharmacy...');
        const hubEmail = 'hub@hub.hub';
        let hubUser = await User.findOne({ email: hubEmail });
        let hubPharmacy = await Pharmacy.findOne({ name: 'hub', isHub: true });

        if (!hubPharmacy) {
            hubPharmacy = await Pharmacy.create({
                name: 'hub',
                phone: '01068797242',
                email: hubEmail,
                ownerName: 'Hub Admin',
                nationalId: '29001011234567',
                pharmacistCard: 'HUB_CARD',
                commercialRegistry: 'HUB_REG',
                taxCard: 'HUB_TAX',
                pharmacyLicense: 'HUB_LIC',
                address: 'Hub Address',
                isHub: true,
                status: 'active',
                verified: true
            });
        }

        if (!hubUser) {
            hubUser = await User.create({
                name: 'Hub Admin',
                email: hubEmail,
                phone: '01111111111',
                hashedPassword: 'hub@hub.hub', // Will be hashed by pre-save
                role: 'admin',
                status: 'active',
                pharmacy: hubPharmacy._id
            });
        } else if (!hubUser.pharmacy) {
            hubUser.pharmacy = hubPharmacy._id;
            await hubUser.save();
        }

        // 3. Parse Excel
        console.log(`📖 Reading Excel file from ${EXCEL_FILE_PATH}...`);
        if (!fs.existsSync(EXCEL_FILE_PATH)) {
            throw new Error(`File not found: ${EXCEL_FILE_PATH}`);
        }
        const workbook = XLSX.readFile(EXCEL_FILE_PATH);
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const data = XLSX.utils.sheet_to_json(worksheet);
        console.log(`📊 Found ${data.length} entries to process.`);

        let successCount = 0;
        let pharmacyCount = 0;
        let productCount = 0;

        for (const row of data) {
            const productName = row['Product Name'];
            const pharmacyName = row['Pharmacy'];
            const relatedPharmacyName = row['Related Pharmacy'];
            const quantity = parseInt(row['Quantity']) || 0;
            const price = parseFloat(row['Price']) || 0;
            const expiryRaw = row['Expiry']; // Expected YY/MM or MM/YY
            const salePct = (parseFloat(row['Sale %']) || 0) + 10;

            if (!productName || !pharmacyName) {
                console.warn(`⚠️ Skipping invalid row: ${JSON.stringify(row)}`);
                continue;
            }

            // A. Product & Prices
            let product = await Product.findOne({ name: productName });
            if (!product) {
                product = await Product.create({
                    name: productName,
                    description: '',
                    conversions: [{ from: 'Unit', to: 'Unit', value: 1 }],
                    status: 'active'
                });
                await HasVolume.create({
                    product: product._id,
                    volume: unitId,
                    value: 1,
                    prices: [price]
                });
                productCount++;
            } else {
                // If product exists, ensure the price is in HasVolume
                let hv = await HasVolume.findOne({ product: product._id, volume: unitId });
                if (hv) {
                    if (!hv.prices.includes(price)) {
                        hv.prices.push(price);
                        await hv.save();
                    }
                } else {
                    // This shouldn't happen if data is consistent, but for safety:
                    await HasVolume.create({
                        product: product._id,
                        volume: unitId,
                        value: 1,
                        prices: [price]
                    });
                }
            }

            // B. Pharmacy
            let pharmacy = await Pharmacy.findOne({ name: pharmacyName });
            if (!pharmacy) {
                // Create Pharmacy
                const dummySuffix = Math.floor(Math.random() * 1000000).toString().padStart(8, '0');
                const dummyPhone = `010${dummySuffix}`;
                const dummyEmail = `pharmacy_${pharmacyName}@dummy.com`;

                pharmacy = await Pharmacy.create({
                    name: pharmacyName,
                    phone: dummyPhone,
                    email: dummyEmail,
                    ownerName: pharmacyName + ' Owner',
                    nationalId: '290' + Math.floor(Math.random() * 100000000000).toString().padStart(11, '0'),
                    pharmacistCard: 'DUMMY_CARD',
                    commercialRegistry: 'DUMMY_REG',
                    taxCard: 'DUMMY_TAX',
                    pharmacyLicense: 'DUMMY_LIC',
                    address: 'Dummy Address',
                    status: 'active',
                    verified: true,
                    balance: 0,
                    cashBalance: 0
                });

                // Create User
                await User.create({
                    name: pharmacyName + ' Owner',
                    email: dummyEmail,
                    phone: dummyPhone,
                    hashedPassword: 'password123', // Default password
                    role: 'pharmacy_owner',
                    status: 'active',
                    pharmacy: pharmacy._id
                });

                pharmacyCount++;
            }

            // C. Related Pharmacy
            let relatedPharmacyId = null;
            if (relatedPharmacyName && relatedPharmacyName.trim() !== '') {
                // Try find by pharmacy name
                let relPhar = await Pharmacy.findOne({ name: relatedPharmacyName });
                if (relPhar) {
                    relatedPharmacyId = relPhar._id;
                }
            }

            // D. StockExcess logic (Hub specific flags)
            let isHubGenerated = false;
            let isHubPurchase = false;
            let purchasePrice = undefined;

            if (pharmacyName.toLowerCase() === 'hub') {
                if (relatedPharmacyId) {
                    isHubGenerated = true;
                    purchasePrice = price * (1 - salePct / 100);
                } else {
                    isHubPurchase = true;
                }
            }

            // Format Expiry: Excel has "26/06" (YY/MM), we need "MM/YY"
            let finalExpiry = expiryRaw;
            if (expiryRaw && expiryRaw.includes('/')) {
                const parts = expiryRaw.split('/');
                if (parts.length === 2) {
                    // If first part > 12, it's likely YY/MM. Flip to MM/YY.
                    const p1 = parseInt(parts[0]);
                    if (p1 > 12) {
                        finalExpiry = `${parts[1].padStart(2, '0')}/${parts[0]}`;
                    } else {
                        finalExpiry = `${parts[0].padStart(2, '0')}/${parts[1]}`;
                    }
                }
            }

            await StockExcess.create({
                pharmacy: pharmacy._id,
                product: product._id,
                volume: unitId,
                originalQuantity: quantity,
                remainingQuantity: quantity,
                expiryDate: finalExpiry,
                selectedPrice: price,
                salePercentage: salePct,
                status: 'available',
                relatedPharmacy: relatedPharmacyId,
                isHubGenerated,
                isHubPurchase,
                purchasePrice
            });
            successCount++;
        }

        console.log('\n✨ Restoration Summary:');
        console.log(`✅ Successfully imported ${successCount} stock excesses.`);
        console.log(`🆕 Created ${pharmacyCount} new pharmacies/users.`);
        console.log(`🆕 Created ${productCount} new products.`);
        console.log('🚀 Done.');
        process.exit(0);

    } catch (error) {
        console.error('❌ Restoration failed:', error);
        process.exit(1);
    }
};

restoreFromExcel();
