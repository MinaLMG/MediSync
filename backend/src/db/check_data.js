const mongoose = require('mongoose');
require('dotenv').config({ path: '.env' });
const { Product, HasVolume } = require('../models');
const connectDB = require('./mongoose');

const count = async () => {
    try {
        await connectDB();
        const productCount = await Product.countDocuments();
        const hasVolumeCount = await HasVolume.countDocuments();
        const productsWithVolumes = await HasVolume.distinct('product');
        
        console.log('Total Products:', productCount);
        console.log('Total HasVolume entries:', hasVolumeCount);
        console.log('Products with at least one volume:', productsWithVolumes.length);

        // Get 5 products with volumes
        const samples = await Product.find({ _id: { $in: productsWithVolumes.slice(0, 5) } }).select('name');
        console.log('Sample products with volumes:', samples);

        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
};

count();
