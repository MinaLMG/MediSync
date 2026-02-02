const { Product, HasVolume, Category, Manufacturer, Volume, ProductSuggestion, User } = require('../models');
const { addNotificationJob } = require('../utils/queueManager');
const mongoose = require('mongoose');

// Get all products with their volumes and prices (Optimized with Pagination and Search)
exports.getAllProducts = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;
        const search = req.query.search || '';

        let matchQuery = {};
        if (req.user.role !== 'admin') matchQuery.status = 'active';

        if (search) {
            const escapedSearch = search.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*');
            matchQuery.name = { $regex: escapedSearch, $options: 'i' };
        }

        const productsCount = await Product.countDocuments(matchQuery);

        const products = await Product.aggregate([
            { $match: matchQuery },
            { $sort: { name: 1 } },
            { $skip: skip },
            { $limit: limit },
            {
                $lookup: {
                    from: 'hasvolumes',
                    localField: '_id',
                    foreignField: 'product',
                    as: 'volumes'
                }
            },
            {
                $lookup: {
                    from: 'volumes',
                    localField: 'volumes.volume',
                    foreignField: '_id',
                    as: 'volumeDetails'
                }
            }
        ]);

        // Post-process to merge volume names (simpler than complex aggregation)
        const formattedProducts = products.map(p => ({
            ...p,
            volumes: p.volumes.map(v => {
                const volDetail = p.volumeDetails.find(vd => vd._id.toString() === v.volume.toString());
                return {
                    hasVolumeId: v._id.toString(),
                    volumeId: v.volume.toString(),
                    value: v.value,
                    prices: v.prices,
                    volumeName: volDetail ? volDetail.name : 'Unknown Volume'
                };
            })
        }));

        // Clean up temporary fields
        formattedProducts.forEach(p => delete p.volumeDetails);

        res.status(200).json({ 
            success: true, 
            data: formattedProducts,
            pagination: {
                total: productsCount,
                page,
                limit,
                pages: Math.ceil(productsCount / limit)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get product by ID with volumes
// @route   GET /api/products/:id
// @access  Protected
exports.getProductById = async (req, res) => {
    try {
        const product = await Product.aggregate([
            { $match: { _id: new mongoose.Types.ObjectId(req.params.id) } },
            {
                $lookup: {
                    from: 'hasvolumes',
                    localField: '_id',
                    foreignField: 'product',
                    as: 'hasVolumes'
                }
            },
            {
                $lookup: {
                    from: 'volumes',
                    localField: 'hasVolumes.volume',
                    foreignField: '_id',
                    as: 'volumeDetails'
                }
            },
            {
                $project: {
                    name: 1,
                    status: 1,
                    conversions: 1,
                    volumes: {
                        $map: {
                            input: '$hasVolumes',
                            as: 'hv',
                            in: {
                                hasVolumeId: { $toString: '$$hv._id' },
                                volumeId: { $toString: '$$hv.volume' },
                                value: '$$hv.value',
                                prices: '$$hv.prices',
                                volumeName: {
                                    $arrayElemAt: [
                                        {
                                            $filter: {
                                                input: '$volumeDetails',
                                                as: 'v',
                                                cond: { $eq: [{ $toString: '$$v._id' }, { $toString: '$$hv.volume' }] }
                                            }
                                        },
                                        0
                                    ]
                                }
                            }
                        }
                    }
                }
            },
            {
                $addFields: {
                    volumes: {
                        $map: {
                            input: '$volumes',
                            as: 'v',
                            in: {
                                $mergeObjects: [
                                    '$$v',
                                    { volumeName: { $ifNull: ['$$v.volumeName.name', 'Unknown Volume'] } }
                                ]
                            }
                        }
                    }
                }
            }
        ]);

        if (!product || product.length === 0) {
            return res.status(404).json({ success: false, message: 'Product not found' });
        }

        res.status(200).json({ success: true, data: product[0] });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get products lite (id, name) for dropdowns
exports.getProductsLite = async (req, res) => {
    try {
        const search = req.query.search || '';
        let matchQuery = {};
        if (req.user.role !== 'admin') {
            matchQuery.status = 'active';
        }
        if (search) {
            // Escape special regex characters except *
            const escapedSearch = search.replace(/[.+^${}()|[\]\\]/g, '\\$&');
            // Convert * to .*
            const regexSearch = escapedSearch.replace(/\*/g, '.*');
            matchQuery.name = { $regex: regexSearch, $options: 'i' };
        }

        const products = await Product.find(matchQuery)
            .select('name')
            .sort({ name: 1 })
            .limit(100);

        res.status(200).json({ success: true, data: products });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Suggest a new product (Manager)
exports.suggestProduct = async (req, res) => {
    try {
        const suggestion = await ProductSuggestion.create({
            ...req.body,
            volumeName: 'unit',
            value: 1,
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
            // Find or Create Base Volume ('unit')
            let unitVolume = await Volume.findOne({ name: 'unit' }).session(session);
            if (!unitVolume) {
                unitVolume = await Volume.create([{ name: 'unit' }], { session });
                unitVolume = unitVolume[0];
            }

            // Create Product linked only to 'unit'
            const product = await Product.create([{
                name: suggestion.name,
                status: 'active',
                conversions: [{
                    from: unitVolume._id.toString(),
                    to: unitVolume._id.toString(),
                    value: 1
                }]
            }], { session });

            // Create HasVolume for the 'unit' volume
            await HasVolume.create([{
                product: product[0]._id,
                volume: unitVolume._id,
                value: 1,
                prices: [suggestion.price]
            }], { session });
        }

        await suggestion.save({ session });
        await session.commitTransaction();

        try {
            await addNotificationJob(
                suggestion.suggestedBy.toString(),
                'system',
                `Your product suggestion for "${suggestion.name}" has been ${status}.`,
                {
                    adminNotes: adminNotes,
                    relatedEntity: status === 'approved' ? (product && product[0] ? product[0]._id : suggestion._id) : suggestion._id,
                    relatedEntityType: status === 'approved' ? 'Product' : 'ProductSuggestion'
                },
                `اقتراح المنتج الخاص بك بـ "${suggestion.name}" قد تم ${status === 'approved' ? 'الموافقة عليه' : 'رفضه'}.`
            );
        } catch (notifErr) {
            console.error('Notification error in updateSuggestionStatus:', notifErr);
        }

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
        const { name, prices } = req.body;

        // Find unit volume
        let unitVolume = await Volume.findOne({ name: 'unit' }).session(session);
        if (!unitVolume) {
            unitVolume = await Volume.create([{ name: 'unit' }], { session });
            unitVolume = unitVolume[0];
        }

        const product = await Product.create([{
            name,
            conversions: [{
                from: unitVolume._id.toString(),
                to: unitVolume._id.toString(),
                value: 1
            }]
        }], { session });

        await HasVolume.create([{
            product: product[0]._id,
            volume: unitVolume._id,
            value: 1,
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

// Toggle Product Status (Admin)
exports.toggleProductStatus = async (req, res) => {
    try {
        const product = await Product.findById(req.params.id);
        if (!product) throw new Error('Product not found');

        product.status = product.status === 'active' ? 'inactive' : 'active';
        await product.save();

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
