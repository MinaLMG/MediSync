const mongoose = require('mongoose');
const { Order, StockShortage, StockExcess, Reservation, Transaction, Product, Volume, Pharmacy } = require('../src/models');
const shortageService = require('../src/services/shortageService');
const transactionService = require('../src/services/transactionService');

async function testReservationConsistency() {
    await mongoose.connect('mongodb://127.0.0.1:27017/medisync'); // Adjust if needed
    console.log('Connected to DB');

    const session = await mongoose.startSession();
    
    try {
        // Setup mock data
        const product = await Product.findOne({ status: 'active' });
        const volume = await Volume.findOne();
        const pharmacy = await Pharmacy.findOne({ isHub: false });
        const hub = await Pharmacy.findOne({ isHub: true });

        if (!product || !volume || !pharmacy || !hub) {
            console.error('Required seed data missing');
            return;
        }

        console.log('--- Step 1: Create Order (Reservation Increment) ---');
        const orderData = {
            items: [{
                product: product._id,
                volume: volume._id,
                quantity: 10,
                targetPrice: 100,
                expiryDate: '12/26',
                originalSalePercentage: 20
            }],
            notes: 'Test Order'
        };

        const order = await shortageService.createOrder(orderData, pharmacy._id);
        let res = await Reservation.findOne({ product: product._id, volume: volume._id, price: 100, expiryDate: '12/26', salePercentage: 20 });
        console.log('Reservation Quantity after Order:', res?.quantity);

        console.log('--- Step 2: Create Transaction (Reservation Decrement) ---');
        // Need an excess to transaction with
        const excess = await StockExcess.create({
            pharmacy: hub._id,
            product: product._id,
            volume: volume._id,
            originalQuantity: 50,
            remainingQuantity: 50,
            expiryDate: '12/26',
            selectedPrice: 100,
            salePercentage: 20,
            status: 'available'
        });

        session.startTransaction();
        const transaction = await transactionService.createTransaction({
            shortageId: order.items[0],
            quantityTaken: 5,
            excessSources: [{ stockExcessId: excess._id, quantity: 5 }]
        }, session);
        await session.commitTransaction();

        // Wait a bit for setImmediate Cleanup
        await new Promise(r => setTimeout(r, 500));
        res = await Reservation.findOne({ product: product._id, volume: volume._id, price: 100, expiryDate: '12/26', salePercentage: 20 });
        console.log('Reservation Quantity after Transaction:', res?.quantity);

        console.log('--- Step 3: Cancel Transaction (Reservation Restoration - THE FIX) ---');
        session.startTransaction();
        await transactionService.updateTransactionStatus(transaction._id, 'cancelled', session);
        await session.commitTransaction();

        res = await Reservation.findOne({ product: product._id, volume: volume._id, price: 100, expiryDate: '12/26', salePercentage: 20 });
        console.log('Reservation Quantity after Cancellation:', res?.quantity);

        // Cleanup
        await StockShortage.deleteMany({ order: order._id });
        await Order.findByIdAndDelete(order._id);
        await StockExcess.findByIdAndDelete(excess._id);
        await Transaction.findByIdAndDelete(transaction._id);
        await Reservation.deleteOne({ _id: res._id });

        console.log('Test completed successfully');

    } catch (err) {
        console.error('Test failed:', err);
    } finally {
        session.endSession();
        await mongoose.disconnect();
    }
}

testReservationConsistency();
