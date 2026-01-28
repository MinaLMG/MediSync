const mongoose = require('mongoose');
require('dotenv').config();
const connectDB = require('./src/db/mongoose');
const { Transaction, StockShortage, StockExcess, Product, Pharmacy, Volume } = require('./src/models');
const { updateTransaction } = require('./src/controllers/transactionController');

async function verify() {
    await connectDB();
    console.log('--- Starting Verification ---');

    let testData = {};

    try {
        // 1. Setup Data
        const product = await Product.create({ 
            name: 'Test Medicine ' + Date.now(), 
            status: 'active'
        });
        const volume = await Volume.create({ name: 'Box ' + Date.now() });
        const pharmacyBuyer = await Pharmacy.create({ 
            name: 'Buyer Pharmacy', 
            email: 'buyer@test.com', 
            status: 'active',
            ownerName: 'Buyer Owner',
            phone: '01234567890',
            nationalId: '12345678901234',
            pharmacistCard: 'PC12345',
            commercialRegistry: 'CR12345',
            taxCard: 'TC12345',
            pharmacyLicense: 'PL12345',
            address: '123 Test St, Cairo'
        });
        const pharmacySeller1 = await Pharmacy.create({ 
            name: 'Seller Pharmacy 1', 
            email: 'seller1@test.com', 
            status: 'active',
            ownerName: 'Seller 1 Owner',
            phone: '01234567891',
            nationalId: '12345678901235',
            pharmacistCard: 'PC12346',
            commercialRegistry: 'CR12346',
            taxCard: 'TC12346',
            pharmacyLicense: 'PL12346',
            address: '456 Test St, Cairo'
        });
        const pharmacySeller2 = await Pharmacy.create({ 
            name: 'Seller Pharmacy 2', 
            email: 'seller2@test.com', 
            status: 'active',
            ownerName: 'Seller 2 Owner',
            phone: '01234567892',
            nationalId: '12345678901236',
            pharmacistCard: 'PC12347',
            commercialRegistry: 'CR12347',
            taxCard: 'TC12347',
            pharmacyLicense: 'PL12347',
            address: '789 Test St, Cairo'
        });

        testData = { product, volume, pharmacyBuyer, pharmacySeller1, pharmacySeller2 };

        const shortage = await StockShortage.create({
            pharmacy: pharmacyBuyer._id,
            product: product._id,
            volume: volume._id,
            quantity: 100,
            remainingQuantity: 60, // 40 already taken (manual setup)
            status: 'partially_fulfilled'
        });

        const excess1 = await StockExcess.create({
            pharmacy: pharmacySeller1._id,
            product: product._id,
            volume: volume._id,
            quantity: 50,
            originalQuantity: 50,
            remainingQuantity: 20, // 30 taken (manual setup)
            expiryDate: '12/26',
            selectedPrice: 10,
            status: 'partially_fulfilled'
        });

        const excess2 = await StockExcess.create({
            pharmacy: pharmacySeller2._id,
            product: product._id,
            volume: volume._id,
            quantity: 50,
            originalQuantity: 50,
            remainingQuantity: 50, // 0 taken
            expiryDate: '12/26',
            selectedPrice: 12,
            status: 'available'
        });

        // Create transaction: Buyer takes 30 from excess1
        const transaction = await Transaction.create({
            serial: 'TEST-TX-' + Date.now(),
            stockShortage: {
                shortage: shortage._id,
                quantityTaken: 30
            },
            stockExcessSources: [
                {
                    stockExcess: excess1._id,
                    quantity: 30,
                    agreedPrice: 10,
                    totalAmount: 300
                }
            ],
            totalQuantity: 30,
            totalAmount: 300,
            status: 'pending'
        });

        console.log('Initial setup complete.');
        console.log(`Original Shortage remaining: ${shortage.remainingQuantity}`);
        console.log(`Original Excess1 remaining: ${excess1.remainingQuantity}`);

        // 2. Run Modification
        // Change: Instead of 30 from excess1, take 20 from excess1 and 20 from excess2 (Total 40)
        const req = {
            params: { id: transaction._id },
            body: {
                quantityTaken: 40,
                excessSources: [
                    { stockExcessId: excess1._id, quantity: 20 },
                    { stockExcessId: excess2._id, quantity: 20 }
                ]
            }
        };

        const res = {
            status: (code) => ({
                json: (data) => {
                    console.log(`Response Status: ${code}`);
                    if (!data.success) console.error('Error:', data.message);
                }
            })
        };

        console.log('Executing modification...');
        await updateTransaction(req, res);

        // 3. Verify Results
        const updatedTx = await Transaction.findById(transaction._id);
        const updatedShortage = await StockShortage.findById(shortage._id);
        const updatedExcess1 = await StockExcess.findById(excess1._id);
        const updatedExcess2 = await StockExcess.findById(excess2._id);

        console.log('--- Verification Results ---');
        console.log(`Transaction Total Quantity: ${updatedTx.totalQuantity} (Expected: 40)`);
        console.log(`Transaction Total Amount: ${updatedTx.totalAmount} (Expected: 440)`);
        
        // Calculation:
        // After setup: Shortage.remainingQuantity = 60
        // Revert: +30 => 90
        // Apply: -40 => 50
        console.log(`Shortage Remaining: ${updatedShortage.remainingQuantity} (Expected: 50)`);

        // Excess1:
        // After setup: Excess1.remainingQuantity = 20
        // Revert: +30 => 50
        // Apply: -20 => 30
        console.log(`Excess1 Remaining: ${updatedExcess1.remainingQuantity} (Expected: 30)`);

        // Excess2:
        // After setup: Excess2.remainingQuantity = 50
        // Revert: none
        // Apply: -20 => 30
        console.log(`Excess2 Remaining: ${updatedExcess2.remainingQuantity} (Expected: 30)`);

    } catch (error) {
        console.error('Verification failed:', error);
    } finally {
        // Cleanup
        console.log('Cleaning up...');
        if (testData.product) {
            await Product.deleteOne({ _id: testData.product._id });
            await Volume.deleteOne({ _id: testData.volume._id });
            await Pharmacy.deleteMany({ _id: { $in: [testData.pharmacyBuyer._id, testData.pharmacySeller1._id, testData.pharmacySeller2._id] } });
            await StockShortage.deleteMany({ product: testData.product._id });
            await StockExcess.deleteMany({ product: testData.product._id });
            await Transaction.deleteMany({ serial: { $regex: /^TEST-TX-/ } });
        }
        await mongoose.connection.close();
        console.log('--- Verification Finished ---');
    }
}

verify();
