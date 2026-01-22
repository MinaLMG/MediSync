const { Product, HasVolume } = require('../models');

// Get all products with their volumes and prices
exports.getAllProducts = async (req, res) => {
    try {
        // Fetch all products
        const products = await Product.find()
            .populate('category', 'name')
            .populate('manufacturer', 'name');

        // Enhance products with their HasVolume data
        const productsWithVolumes = await Promise.all(products.map(async (product) => {
            const volumes = await HasVolume.find({ product: product._id })
                .populate('volume', 'name');
            
            return {
                ...product.toObject(),
                volumes: volumes.map(hv => ({
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
