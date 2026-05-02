require('dotenv').config();
const mongoose = require('mongoose');
const Product = require('../models/Product');
const ProductSale = require('../models/ProductSale');
const { fetchProductSalesUI } = require('../services/isupplyPuppeteerService');

async function fetchWeeklySales() {
    try {
        console.log('--- STARTING WEEKLY ISUPPLY SALES FETCH ---');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB.');

        // 1. Get all products that have been matched to iSupply
        const matchedProducts = await Product.find({ isupplyData: { $ne: null } }).select('_id name isupplyData');
        console.log(`Found ${matchedProducts.length} matched products in database.`);

        // 2. Build a list with their last fetch dates
        const productsToFetch = [];
        for (const p of matchedProducts) {
            // Get the MOST RECENT sale record
            const lastRecord = await ProductSale.findOne({ product: p._id }).sort({ createdAt: -1 });
            productsToFetch.push({
                product: p,
                lastFetchedAt: lastRecord ? lastRecord.createdAt : new Date('2020-01-01')
            });
        }

        // 3. Sort by date: furthest first
        productsToFetch.sort((a, b) => a.lastFetchedAt - b.lastFetchedAt);

        console.log(`Processing ${productsToFetch.length} products (oldest fetch first)...`);

        for (const item of productsToFetch) {
            const p = item.product;
            const isupplyTitle = p.isupplyData.title;

            if (!isupplyTitle) {
                console.log(`[Skip] Product ${p.name} has no iSupply title in isupplyData.`);
                continue;
            }

            console.log(`\n[${new Date().toLocaleTimeString()}] Fetching for: ${p.name}`);
            console.log(`iSupply Title: ${isupplyTitle} (Last fetch: ${item.lastFetchedAt.toLocaleDateString()})`);

            try {
                const sales = await fetchProductSalesUI(isupplyTitle);

                // ALWAYS create a NEW record for history, even if no sales found (to mark the attempt)
                const newRecord = new ProductSale({
                    product: p._id,
                    sales: sales || []
                });

                await newRecord.save();
                
                if (sales && sales.length > 0) {
                    console.log(`Successfully created new historical record for ${p.name}. Found ${sales.length} offers.`);
                } else {
                    console.log(`No active sales offers found for ${p.name} during this fetch. Created empty history record.`);
                }

                // Add a small delay between products
                await new Promise(r => setTimeout(r, 3000));

            } catch (error) {
                console.error(`Error processing ${p.name}:`, error.message);
            }
        }

    } catch (err) {
        console.error('Weekly Fetch Error:', err);
    } finally {
        await mongoose.disconnect();
        console.log('\n--- WEEKLY SALES FETCH COMPLETE ---');
        process.exit(0);
    }
}

fetchWeeklySales();
