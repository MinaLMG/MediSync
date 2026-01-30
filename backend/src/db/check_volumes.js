const mongoose = require('mongoose');
require('dotenv').config({ path: '.env' });
const { Volume } = require('../models');
const connectDB = require('./mongoose');

const check = async () => {
    try {
        await connectDB();
        const volumes = await Volume.find({});
        console.log('Total Volumes:', volumes.length);
        console.log('Volumes:', volumes);
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
};

check();
