const { Product, HasVolume, Category, Manufacturer, Volume, ProductSuggestion } = require('../models');
const mongoose = require('mongoose');

// Get all products with their volumes and prices
exports.getAllProducts = async (req, res) => {
    try {
        const products = await Product.find()
            .populate('category', 'name')
            .populate('manufacturer', 'name');

        const productsWithVolumes = await Promise.all(products.map(async (product) => {
            const hasVolumes = await HasVolume.find({ product: product._id })
                .populate('volume', 'name');
            
            return {
                ...product.toObject(),
                volumes: hasVolumes.map(hv => ({
                    hasVolumeId: hv._id,
                    volumeId: hv.volume._id,
                    volumeName: hv.volume.name,
                    prices: hv.prices,
                    value: hv.value
                }))
            };
        }));

        res.status(200).json({ success: true, data: productsWithVolumes });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Suggest a new product (Manager)
exports.suggestProduct = async (req, res) => {
    try {
        const suggestion = await ProductSuggestion.create({
            ...req.body,
            suggestedBy: req.user._id
        });
        res.status(201).json({ success: true, data: suggestion });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

// Get suggestions (Admin / My Suggestions)
exports.getSuggestions = async (req, res) => {
    try {
        let query = {};
        if (req.user.role !== 'admin') {
            query.suggestedBy = req.user._id;
        }
        const suggestions = await ProductSuggestion.find(query).populate('suggestedBy', 'name email').sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: suggestions });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Approve/Reject Suggestion (Admin)
exports.updateSuggestionStatus = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { status, adminNotes } = req.body;
        const suggestion = await ProductSuggestion.findById(req.params.id).session(session);

        if (!suggestion) throw new Error('Suggestion not found');
        if (suggestion.status !== 'pending') throw new Error('Already processed');

        suggestion.status = status;
        suggestion.adminNotes = adminNotes;

        if (status === 'approved') {
            // 1. Find or Create Category
            let category = await Category.findOne({ name: suggestion.categoryName }).session(session);
            if (!category) {
                category = await Category.create([{ name: suggestion.categoryName }], { session });
                category = category[0];
            }

            // 2. Find or Create Manufacturer
            let manufacturer = await Manufacturer.findOne({ name: suggestion.manufacturerName }).session(session);
            if (!manufacturer) {
                manufacturer = await Manufacturer.create([{ name: suggestion.manufacturerName }], { session });
                manufacturer = manufacturer[0];
            }

            // 3. Find or Create Base Volume ('unit')
            let unitVolume = await Volume.findOne({ name: 'unit' }).session(session);
            if (!unitVolume) {
                unitVolume = await Volume.create([{ name: 'unit' }], { session });
                unitVolume = unitVolume[0];
            }

            // 4. Find or Create Suggested Volume
            let suggestedVolume = await Volume.findOne({ name: suggestion.volumeName }).session(session);
            if (!suggestedVolume) {
                suggestedVolume = await Volume.create([{ name: suggestion.volumeName }], { session });
                suggestedVolume = suggestedVolume[0];
            }

            // 5. Create Product with Conversion
            const product = await Product.create([{
                name: suggestion.name,
                activeIngredient: suggestion.activeIngredient,
                category: category._id,
                manufacturer: manufacturer._id,
                status: 'active',
                conversions: [{
                    from: suggestedVolume._id.toString(),
                    to: unitVolume._id.toString(),
                    value: suggestion.value
                }]
            }], { session });

            // 6. Create HasVolume for the suggested volume
            await HasVolume.create([{
                product: product[0]._id,
                volume: suggestedVolume._id,
                value: suggestion.value,
                prices: [suggestion.price]
            }], { session });
        }

        await suggestion.save({ session });
        await session.commitTransaction();
        res.status(200).json({ success: true, data: suggestion });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// Create Product Direct (Admin)
exports.createProduct = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { name, activeIngredient, categoryId, manufacturerId, volumeId, value, prices } = req.body;

        const product = await Product.create([{
            name,
            activeIngredient,
            category: categoryId,
            manufacturer: manufacturerId
        }], { session });

        await HasVolume.create([{
            product: product[0]._id,
            volume: volumeId,
            value,
            prices: prices || []
        }], { session });

        await session.commitTransaction();
        res.status(201).json({ success: true, data: product[0] });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};

// Update Product Basic Info (Admin)
exports.updateProduct = async (req, res) => {
    try {
        const product = await Product.findByIdAndUpdate(req.params.id, req.body, { new: true });
        res.status(200).json({ success: true, data: product });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

// Add Price to Volume (Admin)
exports.addPriceToVolume = async (req, res) => {
    try {
        const { price } = req.body;
        const hv = await HasVolume.findById(req.params.hasVolumeId);
        if (!hv) throw new Error('Product Volume connection not found');
        
        hv.prices.push(price);
        await hv.save();
        res.status(200).json({ success: true, data: hv });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

// Remove Price from Volume (Admin)
exports.removePriceFromVolume = async (req, res) => {
    try {
        const { priceIndex } = req.body;
        const hv = await HasVolume.findById(req.params.hasVolumeId);
        if (!hv) throw new Error('Product Volume connection not found');
        
        hv.prices.splice(priceIndex, 1);
        await hv.save();
        res.status(200).json({ success: true, data: hv });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

// Add a new Volume to an existing Product (Admin)
exports.addVolumeToProduct = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const { volumeId, value, prices } = req.body;
        const productId = req.params.id;

        const product = await Product.findById(productId).session(session);
        if (!product) throw new Error('Product not found');

        const existingHV = await HasVolume.findOne({ product: productId, volume: volumeId }).session(session);
        if (existingHV) throw new Error('Product already has this volume');

        const unitVolume = await Volume.findOne({ name: 'unit' }).session(session);
        if (!unitVolume) throw new Error('Base unit volume not found');

        const hv = await HasVolume.create([{
            product: productId,
            volume: volumeId,
            value,
            prices: prices || []
        }], { session });

        product.conversions.push({
            from: volumeId,
            to: unitVolume._id.toString(),
            value
        });
        await product.save({ session });

        await session.commitTransaction();
        res.status(201).json({ success: true, data: hv[0] });
    } catch (error) {
        await session.abortTransaction();
        res.status(400).json({ success: false, message: error.message });
    } finally {
        session.endSession();
    }
};
