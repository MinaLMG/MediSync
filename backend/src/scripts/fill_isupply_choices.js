require('dotenv').config();
const mongoose = require('mongoose');
const Product = require('../models/Product');
const StockExcess = require('../models/StockExcess');
const ProductChoice = require('../models/ProductChoice');
const { searchIProductsDirect } = require('../services/isupplyPuppeteerService');

async function fillChoices() {
    try {
        console.log('--- STARTING ISUPPLY CHOICES POPULATION ---');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB.');

        // 1. Get products prioritizing those with StockExcess and no matches
        // AND no existing entry in ProductChoice
        const priorityProducts = await StockExcess.aggregate([
            { $lookup: { from: 'products', localField: 'product', foreignField: '_id', as: 'productInfo' } },
            { $unwind: '$productInfo' },
            { $match: { 'productInfo.isupplyData': null } },
            // Check if already in ProductChoice
            { $lookup: { from: 'productchoices', localField: 'product', foreignField: 'product', as: 'choiceEntries' } },
            { $match: { 'choiceEntries.0': { $exists: false } } },
            { $group: { _id: '$product', name: { $first: '$productInfo.name' } } }
        ]);

        console.log(`Found ${priorityProducts.length} priority products with StockExcess and no choices.`);

        // 2. Get other products without isupplyData AND no choices already
        // First get all items already in ProductChoice to exclude them
        const productsWithChoices = await ProductChoice.find().distinct('product');

        const otherProducts = await Product.find({
            isupplyData: null,
            _id: { $nin: [...priorityProducts.map(p => p._id), ...productsWithChoices] }
        })
            .select('name');

        const allProducts = [...priorityProducts, ...otherProducts];
        console.log(`Total targeting ${allProducts.length} products.`);

        for (const p of allProducts) {
            // Safety check
            const existing = await ProductChoice.findOne({ product: p._id });
            if (existing) continue;

            const extractSearchTerm = (name) => {
                const match = name.match(/^([^\d]+)/);
                return match ? match[1].trim() : name.trim();
            };

            const searchTerm = extractSearchTerm(p.name);
            console.log(`\nSearching for: ${p.name} (Term: ${searchTerm})`);

            try {
                const choices = await searchIProductsDirect(searchTerm);
                console.log(`Found ${choices.length} choices.`);

                if (choices.length > 0) {
                    await ProductChoice.findOneAndUpdate(
                        { product: p._id },
                        { choices },
                        { upsert: true, new: true }
                    );
                    console.log('Updated ProductChoice table.');
                }

                // Delay between items to be safe
                await new Promise(r => setTimeout(r, 2000));
            } catch (err) {
                console.error(`Error searching for ${p.name}:`, err.message);
                if (err.message.includes('Login failed')) {
                    console.error('FATAL: Login failed. Exiting script.');
                    break;
                }
            }
        }

    } catch (err) {
        console.error('Script Error:', err);
    } finally {
        await mongoose.disconnect();
        console.log('\n--- POPULATION COMPLETE ---');
        process.exit(0);
    }
}

fillChoices();
