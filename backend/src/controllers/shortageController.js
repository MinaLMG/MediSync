const { StockShortage, StockExcess, Product } = require('../models');

// Create new shortage
exports.createShortage = async (req, res) => {
    try {
        const { product: productId, volume, quantity, notes } = req.body;

        // Check product status
        const product = await Product.findById(productId);
        if (!product || product.status !== 'active') {
            return res.status(400).json({
                success: false,
                message: 'This product is currently inactive and cannot be added as a shortage.'
            });
        }

        // Check if an Excess exists for this product (Constraint)
        const existingExcess = await StockExcess.findOne({
            pharmacy: req.user.pharmacy,
            product: productId,
            status: { $in: ['pending', 'available', 'partially_fulfilled'] }
        });

        if (existingExcess) {
            return res.status(400).json({ 
                success: false, 
                message: 'You cannot add a shortage for this product because you already have an excess for it.' 
            });
        }

        const shortage = await StockShortage.create({
            pharmacy: req.user.pharmacy,
            product,
            volume,
            quantity,
            remainingQuantity: quantity,
            notes,
            status: 'active'
        });

        res.status(201).json({ success: true, data: shortage });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

// Get active shortages (Admin)
exports.getActiveShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ remainingQuantity: { $gt: 0 } })
            .populate('pharmacy', 'name')
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: shortages });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get shortages for a specific pharmacy (Manager)
exports.getMyShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ pharmacy: req.user.pharmacy })
            .populate('product', 'name')
            .populate('volume', 'name')
            .sort({ createdAt: -1 });

        res.status(200).json({ success: true, data: shortages });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Update shortage (Manager/Owner)
exports.updateShortage = async (req, res) => {
    try {
        const { quantity, notes } = req.body;

        const shortage = await StockShortage.findById(req.params.id);

        if (!shortage) {
            return res.status(404).json({ success: false, message: 'Shortage not found' });
        }

        if (shortage.pharmacy.toString() !== req.user.pharmacy.toString()) {
            return res.status(403).json({ success: false, message: 'Not authorized to update this shortage' });
        }

        if (shortage.status !== 'active' && shortage.status !== 'partially_fulfilled') {
             return res.status(400).json({ success: false, message: 'Cannot update non-active shortage' });
        }

        // Immutability Check
        const { product, volume } = req.body;
        if (product && product !== shortage.product.toString()) {
            return res.status(400).json({ success: false, message: 'Product cannot be modified' });
        }
        if (volume && volume !== shortage.volume.toString()) {
            return res.status(400).json({ success: false, message: 'Volume cannot be modified' });
        }

        const fulfilled = shortage.quantity - shortage.remainingQuantity;

        if (quantity !== undefined) {
            // Rule: Quantity can only be DECREASED
            if (quantity > shortage.quantity) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'Quantity can only be decreased to prevent exploitation.' 
                });
            }
            if (quantity < fulfilled) {
                return res.status(400).json({ 
                    success: false, 
                    message: `New quantity (${quantity}) cannot be less than already fulfilled quantity (${fulfilled}).` 
                });
            }
            shortage.quantity = quantity;
            shortage.remainingQuantity = quantity - fulfilled;
        }

        shortage.notes = notes || shortage.notes;

        await exports.syncShortageStatus(shortage);
        await shortage.save();

        res.status(200).json({ success: true, data: shortage });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Delete shortage (Admin/Owner/Manager)
exports.deleteShortage = async (req, res) => {
    try {
        const shortage = await StockShortage.findById(req.params.id);

        if (!shortage) {
            return res.status(404).json({ success: false, message: 'Shortage not found' });
        }

        if (req.user.role !== 'admin' && shortage.pharmacy.toString() !== req.user.pharmacy.toString()) {
             return res.status(403).json({ success: false, message: 'Not authorized to delete this shortage' });
        }

        // Deletion constraint: Only active shortages with zero fulfillment can be deleted
        const fulfilled = shortage.quantity - shortage.remainingQuantity;
        if (fulfilled > 0) {
            return res.status(400).json({ 
                success: false, 
                message: 'Cannot delete shortage that has already been matched/fulfilled.' 
            });
        }

        if (shortage.status !== 'active') {
            return res.status(400).json({
                success: false,
                message: `Cannot delete shortage in ${shortage.status} state.`
            });
        }

        await shortage.deleteOne();

        res.status(200).json({ success: true, message: 'Shortage deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get all unique product names with active shortages system-wide (For News Marquee)
// @route   GET /api/shortage/global-active
// @access  Private (Managers/Admin)
exports.getGlobalActiveShortages = async (req, res) => {
    try {
        const shortages = await StockShortage.find({ remainingQuantity: { $gt: 0 } })
            .select('product')
            .populate('product', 'name');

        // Extract unique names
        const productNames = [...new Set(shortages.map(s => s.product?.name).filter(Boolean))];
        console.log("shortage productnames:",productNames)
        res.status(200).json({ success: true, count: productNames.length, data: productNames });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};


// Helper to sync shortage status based on consistency
exports.syncShortageStatus = async (shortage) => {
    if (shortage.remainingQuantity === 0) {
        shortage.status = 'fulfilled';
    } else if (shortage.remainingQuantity < shortage.quantity) {
        shortage.status = 'partially_fulfilled';
    } else {
        // Only move to active if it's not already cancelled
        if (shortage.status !== 'cancelled') {
            shortage.status = 'active';
        }
    }
};

// End of file
