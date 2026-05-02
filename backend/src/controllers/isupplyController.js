const Product = require('../models/Product');
const ProductChoice = require('../models/ProductChoice');
const StockExcess = require('../models/StockExcess');

// @desc    Get a random unmatched product and matching iSupply data
// @route   GET /api/admin/isupply/random-unmatched
// @access  Private/Admin
const getRandomUnmatchedProduct = async (req, res) => {
    try {
        // 1. Get products that HAVE a ProductChoice entry (meaning we have cached searches)
        // AND don't have isupplyData yet.
        const availableChoiceProducts = await ProductChoice.aggregate([
            { $lookup: { from: 'products', localField: 'product', foreignField: '_id', as: 'productInfo' } },
            { $unwind: '$productInfo' },
            { $match: { 'productInfo.isupplyData': null } },
            // Prioritize those with StockExcess if possible
            { $lookup: { from: 'stockexcesses', localField: 'product', foreignField: 'product', as: 'excessInfo' } },
            { $addFields: { hasExcess: { $gt: [{ $size: '$excessInfo' }, 0] } } },
            { $sort: { hasExcess: -1 } },
            { $sample: { size: 10 } } // Get a small pool to pick from
        ]);

        if (availableChoiceProducts.length === 0) {
            return res.status(404).json({ message: 'No products with cached choices found. Please run the background script.' });
        }

        // Pick one randomly from the pool
        const randomChoice = availableChoiceProducts[Math.floor(Math.random() * availableChoiceProducts.length)];
        const internalProduct = randomChoice.productInfo;
        const productId = internalProduct._id;
        
        // Extract search term up to first digit for display/reference
        const extractSearchTerm = (name) => {
            const match = name.match(/^([^\d]+)/);
            return match ? match[1].trim() : name.trim();
        };
        const searchTerm = extractSearchTerm(internalProduct.name);

        // 2. Fetch choices from our new ProductChoice table
        const choiceEntry = await ProductChoice.findOne({ product: productId });
        
        const finalMatches = choiceEntry ? choiceEntry.choices : [];

        console.log(`[iSupply Controller] Found product: ${internalProduct.name}. Matches in cache: ${finalMatches.length}`);

        res.json({
            product: internalProduct,
            searchTerm: searchTerm,
            matches: finalMatches
        });

    } catch (error) {
        console.error('Error fetching iSupply data:', error);
        res.status(500).json({ message: 'Failed to fetch isupply products', error: error.message });
    }
};

// @desc    Update a MediSync Product to link to an iSupply ID
// @route   PATCH /api/admin/isupply/match
// @access  Private/Admin
const matchProduct = async (req, res) => {
    try {
        const { product_id, choice, index } = req.body;

        if (!product_id || !choice) {
            return res.status(400).json({ message: 'Please provide both internal product_id and iSupply choice object.' });
        }

        const product = await Product.findByIdAndUpdate(
            product_id,
            { isupplyData: { ...choice, selectedIndex: index } },
            { new: true }
        );

        if (!product) {
            return res.status(404).json({ message: 'Internal Product not found' });
        }

        // Delete the ProductChoice record now that we have matched it
        await ProductChoice.deleteOne({ product: product_id });

        res.json({ message: 'Product successfully matched!', product });
    } catch (error) {
        console.error('Error matching product:', error);
        res.status(500).json({ message: 'Server Error matching products', error: error.message });
    }
};

const rejectChoice = async (req, res) => {
    try {
        const { product_id } = req.body;

        if (!product_id) {
            return res.status(400).json({ message: 'Missing product_id' });
        }

        // Delete the entire record for this product
        await ProductChoice.deleteOne({ product: product_id });

        res.json({ message: 'All choices for this product have been removed.' });
    } catch (error) {
        console.error('Error rejecting choice:', error);
        res.status(500).json({ message: 'Server Error rejecting choice', error: error.message });
    }
};

module.exports = {
    getRandomUnmatchedProduct,
    matchProduct,
    rejectChoice
};
