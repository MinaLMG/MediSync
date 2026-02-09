const mongoose = require('mongoose');
const { User, Pharmacy, Product, Volume, StockExcess, StockShortage, Transaction, Settings } = require('../src/models');
const transactionController = require('../src/controllers/transactionController');
const dotenv = require('dotenv');

dotenv.config();

const runVerification = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('✅ Connected to MongoDB');

        // 1. Setup Data
        // Create Mock Pharmacies
        const sellerPh = new Pharmacy({ name: 'Test Seller Ph', phone: '1111111111', password: '123' });
        await sellerPh.save();
        const buyerPh = new Pharmacy({ name: 'Test Buyer Ph', phone: '2222222222', password: '123' });
        await buyerPh.save();

        // Create Mock Users
        const sellerUser = new User({ name: 'Seller', phone: '1111111111', password: '123', pharmacy: sellerPh._id, role: 'pharmacy_owner' });
        await sellerUser.save();
        const buyerUser = new User({ name: 'Buyer', phone: '2222222222', password: '123', pharmacy: buyerPh._id, role: 'pharmacy_owner' });
        await buyerUser.save();

        // Create Product & Volume (Find existing or create)
        let product = await Product.findOne({ name: 'Test Product' });
        if (!product) {
            product = new Product({ name: 'Test Product', status: 'active' });
            await product.save();
        }
        let volume = await Volume.findOne({ name: 'Test Vol' });
        if (!volume) {
            volume = new Volume({ name: 'Test Vol' });
            await volume.save();
        }

        // Create Excess (Seller)
        // Scenario: Sale 36%. System Min Comm 10%.
        // Expectation: Commission = 36% (Max(36, 10)). Agreed Sale = 26% (36 - 10).
        const excess = new StockExcess({
            pharmacy: sellerPh._id,
            product: product._id,
            volume: volume._id,
            originalQuantity: 100,
            remainingQuantity: 100,
            selectedPrice: 100,
            salePercentage: 36, // The Offer
            expiryDate: new Date('2025-12-31'),
            status: 'available'
        });
        await excess.save();
        console.log('✅ Created Excess with Sale 36%');

        // 2. Mock Request & Response
        const req = {
            user: { _id: buyerUser._id, pharmacy: buyerPh._id },
            body: {
                excessId: excess._id,
                quantity: 10
            }
        };

        const res = {
            status: (code) => ({
                json: (data) => {
                    console.log(`\nResponse Status: ${code}`);
                    if (code === 201 || code === 200) {
                         verifyTransaction(data.data);
                    } else {
                        console.error('❌ Transaction Failed:', data);
                    }
                }
            })
        };

        // 3. Execute Controller Method
        console.log('🔄 Executing buyFromMarket...');
        await transactionController.buyFromMarket(req, res);

    } catch (error) {
        console.error('❌ Error:', error);
    } 
};

async function verifyTransaction(transactionData) {
    try {
        // Fetch full transaction
        const transaction = await Transaction.findById(transactionData._id).populate({
            path: 'stockShortage.shortage',
            model: 'StockShortage'
        });

        console.log('✅ Transaction Created:', transaction._id);
        
        // Check Ratios
        const commRatio = transaction.commissionRatio * 100;
        const saleRatio = transaction.saleRatio * 100;
        
        console.log(`Original Sale (Excess): 36%`);
        console.log(`Commission Ratio (Transaction): ${commRatio}% (Expected ~36%)`);
        console.log(`Sale Ratio (Transaction): ${saleRatio}% (Expected ~26%)`); // 36 - 10

        if (Math.abs(commRatio - 36) < 0.1 && Math.abs(saleRatio - 26) < 0.1) {
             console.log('✅ Ratios are CORRECT.');
        } else {
             console.error('❌ Ratios match FAILED.');
        }

        const shortage = transaction.stockShortage.shortage;
        console.log(`Shortage Original Sale: ${shortage.originalSalePercentage}% (Expected 36%)`);
        console.log(`Shortage Agreed Sale: ${shortage.salePercentage}% (Expected ~26%)`);

        if (shortage.originalSalePercentage === 36 && Math.abs(shortage.salePercentage - 26) < 0.1) {
             console.log('✅ Shortage Data is CORRECT.');
        } else {
             console.error('❌ Shortage Data match FAILED.');
        }
        
    } catch (err) {
        console.error('Verification Error:', err);
    } finally {
        // Cleanup?
        // maybe process.exit()
        setTimeout(() => process.exit(0), 1000);
    }
}

runVerification();
