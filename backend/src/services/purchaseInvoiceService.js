const { PurchaseInvoice, Pharmacy, CashBalanceHistory } = require('../models');
const excessService = require('./excessService');
const mongoose = require('mongoose');

/**
 * Creates a new purchase invoice for a hub.
 * Automatically creates a StockExcess for each item and deducts total from cashBalance.
 */
exports.createPurchaseInvoice = async (data, pharmacyId, req, session) => {
    const { items, totalAmount, date } = data;
    console.log("items",items)
    console.log("totalAmount",totalAmount)
    console.log("date",date)
    const hub = await Pharmacy.findById(pharmacyId).session(session);
    if (!hub || !hub.isHub) throw new Error('Pharmacy is not a hub');

    if (hub.cashBalance < totalAmount) {
        throw new Error(`Insufficient cash balance. Required: ${totalAmount}, Current: ${hub.cashBalance}`);
    }

    // 1. Create Purchase Invoice (to get ID for references)
    const invoice = new PurchaseInvoice({
        pharmacy: pharmacyId,
        totalAmount,
        date: date || new Date(),
        items: [] // Will populate after creating items
    });
    console.log("invoice",invoice)
    const processedItems = [];
    console.log("processedItems",processedItems)
    // 2. Process each item using excessService
    for (const item of items) {
        const { product, volume, quantity, buyingPrice, sellingPrice, salePercentage, expiryDate } = item;

        // Use core excessService to create the excess
        const excess = await excessService.createExcess({
            product,
            volume,
            quantity,
            expiryDate,
            selectedPrice: sellingPrice,
            salePercentage: salePercentage || 0, 
            shortage_fulfillment: false
        }, pharmacyId, req, session);

        // Approve and mark as hub specific
        await excessService.approveExcess(excess._id, session);
        
        excess.isHubGenerated = true; // Mark as hub specific
        excess.isHubPurchase = true;
        excess.purchasePrice = buyingPrice;
        await excess.save({ session });
        
        processedItems.push({
            product,
            volume,
            quantity,
            buyingPrice,
            sellingPrice,
            salePercentage: salePercentage || 0,
            expiryDate,
            excess: excess._id
        });
    }

    invoice.items = processedItems;
    console.log("invoice.items",invoice.items)
    await invoice.save({ session });
    console.log("invoice",invoice)
    // 3. Update Hub Cash Balance
    const previousCashBalance = hub.cashBalance;
    hub.cashBalance -= totalAmount;
    await hub.save({ session });
    console.log("hub",hub)
    // 4. Record History in CashBalanceHistory
    await CashBalanceHistory.create([{
        pharmacy: pharmacyId,
        type: 'withdrawal',
        amount: totalAmount,
        previousBalance: previousCashBalance,
        newBalance: hub.cashBalance,
        relatedEntity: invoice._id,
        relatedEntityType: 'PurchaseInvoice',
        description: `Purchase Invoice #${invoice._id.toString().slice(-6).toUpperCase()}`,
        description_ar: `فاتورة شراء #${invoice._id.toString().slice(-6).toUpperCase()}`,
        details: { invoiceId: invoice._id }
    }], { session });

    return invoice;
};

exports.getInvoicesByPharmacy = async (pharmacyId) => {
    return await PurchaseInvoice.find({ pharmacy: pharmacyId })
        .populate('items.product', 'name')
        .populate('items.volume', 'name')
        .sort({ date: -1 });
};

/**
 * Updates an existing purchase invoice with strict per-item logic.
 * 
 * Logic Rules:
 * 1. Adding new items is NOT allowed (returns error).
 * 2. Deleting existing items IS allowed ONLY if no stock has been sold/taken from the corresponding StockExcess.
 * 3. Modification rules:
 *    - Product, Volume, Excess ID: Cannot be changed.
 *    - Quantity: Can be changed but must be >= amount already taken/sold from the excess.
 *    - Buying Price: Can be changed.
 *    - Selling Price, Sale Percentage, Expiry Date: Can be changed ONLY if no stock has been taken.
 * 4. Cash balance is automatically adjusted (refunded for reductions/deletions, deducted for increases).
 * 
 * @param {string} invoiceId - ID of the invoice to update.
 * @param {Object} data - Update data containing { items, date }. Items should have _id or excess.
 * @param {Object} req - Request object for context.
 * @param {Object} session - Mongoose session for transaction.
 * @returns {Promise<Object>} Updated invoice.
 */
exports.updatePurchaseInvoice = async (invoiceId, data, req, session) => {
    const { items, date } = data;
    console.log("items",items) 
    // 1. Fetch Invoice and Hub
    const invoice = await PurchaseInvoice.findById(invoiceId).session(session);
    if (!invoice) throw new Error('Purchase Invoice not found');
    
    const hub = await Pharmacy.findById(invoice.pharmacy).session(session);
    if (!hub) throw new Error('Hub not found');

    const oldTotal = invoice.totalAmount;
    let newTotal = 0;

    // Map existing items for lookup (either by item _id or excess _id)
    const existingItemMap = new Map();
    invoice.items.forEach(item => {
        existingItemMap.set(item.excess.toString(), item);
    });

    const inputItemIds = new Set(items.map(i => i.excess ? i.excess.toString() : null).filter(id => id !== null));

    // 2. Identify Deletions
    for (const existingItem of invoice.items) {
        if (!inputItemIds.has(existingItem.excess.toString())) {
            const excess = await mongoose.model('StockExcess').findById(existingItem.excess.toString()).session(session);
            if (excess) {
                const taken = excess.originalQuantity - excess.remainingQuantity;
                if (taken > 0) {
                    throw new Error(`Cannot delete item "${existingItem.product_name || 'Stock'}" because ${taken} units have already been sold/taken.`);
                }
                // Safe to remove the excess
                await mongoose.model('StockExcess').findByIdAndDelete(existingItem.excess).session(session);
            }
        }
    }

    const finalItems = [];

    // 3. Process Input Items (Modifications & Existence Check)
    for (const inputItem of items) {
        if (!inputItem.excess) 
            throw new Error('Adding new items to an existing invoice is not allowed. Please create a new invoice.'); // Skip items without identifier
        
        const identifier = inputItem.excess.toString();
        const existingItem = existingItemMap.get(identifier);

        if (!existingItem) {
            throw new Error('Adding new items to an existing invoice is not allowed. Please create a new invoice.');
        }

        const excess = await mongoose.model('StockExcess').findById(existingItem.excess.toString()).session(session);
        if (!excess) throw new Error(`Stock record for item ${identifier} not found.`);

        const taken = excess.originalQuantity - excess.remainingQuantity;

        // Validation: Product/Volume cannot change
        if (inputItem.product && inputItem.product.toString() !== existingItem.product.toString()) {
            throw new Error('Changing product is not allowed in an invoice update.');
        }
        if (inputItem.volume && inputItem.volume.toString() !== existingItem.volume.toString()) {
            throw new Error('Changing volume is not allowed in an invoice update.');
        }

        // Modification: Expiry, SellingPrice, SalePercentage (Only if not taken)
        if (taken > 0) {
            if (inputItem.sellingPrice !== undefined && inputItem.sellingPrice !== existingItem.sellingPrice) {
                throw new Error(`Cannot change selling price of item because stock usage has already started (${taken} units taken).`);
            }
            if (inputItem.salePercentage !== undefined && inputItem.salePercentage !== existingItem.salePercentage) {
                throw new Error(`Cannot change sale percentage of item because stock usage has already started.`);
            }
            if (inputItem.expiryDate && inputItem.expiryDate !== existingItem.expiryDate) {
                 throw new Error(`Cannot change expiry date because stock usage has already started.`);
            }
        } else {
            // Apply updates if allowed
            if (inputItem.sellingPrice !== undefined) {
                excess.selectedPrice = inputItem.sellingPrice;
                existingItem.sellingPrice = inputItem.sellingPrice;
            }
            if (inputItem.salePercentage !== undefined) {
                excess.salePercentage = inputItem.salePercentage;
                existingItem.salePercentage = inputItem.salePercentage;
            }
            if (inputItem.expiryDate) {
                excess.expiryDate = inputItem.expiryDate;
                existingItem.expiryDate = inputItem.expiryDate;
            }
        }

        // Modification: Buying Price (Always allowed)
        if (inputItem.buyingPrice !== undefined && inputItem.buyingPrice !== existingItem.buyingPrice) {
            existingItem.buyingPrice = inputItem.buyingPrice;
            excess.purchasePrice = inputItem.buyingPrice;
            // Propagate only if it actually changed
            await excessService.propagateBuyingPriceUpdate(excess._id, inputItem.buyingPrice, session);
        }

        // Modification: Quantity
        if (inputItem.quantity !== undefined && inputItem.quantity !== existingItem.quantity) {
            if (inputItem.quantity < taken) {
                throw new Error(`New quantity (${inputItem.quantity}) cannot be less than units already taken/sold (${taken}).`);
            }
            const qDiff = inputItem.quantity - existingItem.quantity;
            excess.originalQuantity = inputItem.quantity;
            excess.remainingQuantity += qDiff;
            existingItem.quantity = inputItem.quantity;
        }

        await excessService.syncExcessStatus(excess, session);
        // Finalize item for the invoice
        existingItem.total = existingItem.quantity * existingItem.buyingPrice;
        newTotal += existingItem.total;
        finalItems.push(existingItem);
    }

    // 4. Update Invoice Record
    invoice.items = finalItems;
    invoice.totalAmount = newTotal;
    if (date) invoice.date = new Date(date);
    await invoice.save({ session });

    // 5. Correct Hub Cash Balance
    const balanceDiff = newTotal - oldTotal;
    if (balanceDiff !== 0) {
        if (balanceDiff > 0 && hub.cashBalance < balanceDiff) {
            throw new Error(`Insufficient cash balance for increase. Need ${balanceDiff}, have ${hub.cashBalance}.`);
        }

        const prevBalance = hub.cashBalance;
        hub.cashBalance -= balanceDiff; // Increase withdrawal if positive, deposit if negative
        await hub.save({ session });

        await CashBalanceHistory.create([{
            pharmacy: hub._id,
            type: balanceDiff > 0 ? 'withdrawal' : 'deposit',
            amount: Math.abs(balanceDiff),
            previousBalance: prevBalance,
            newBalance: hub.cashBalance,
            relatedEntity: invoice._id,
            relatedEntityType: 'PurchaseInvoice',
            description: `Correction: Purchase Invoice Updated #${invoice._id.toString().slice(-6).toUpperCase()}`,
            description_ar: `تصحيح: تم تحديث فاتورة شراء #${invoice._id.toString().slice(-6).toUpperCase()}`,
            details: { invoiceId: invoice._id, diff: -balanceDiff }
        }], { session });
    }

    return invoice;
};

/**
 * Deletes a purchase invoice and reverses its effects.
 */
exports.deletePurchaseInvoice = async (invoiceId, session) => {
    const invoice = await PurchaseInvoice.findById(invoiceId).session(session);
    if (!invoice) throw new Error('Invoice not found');

    const hub = await Pharmacy.findById(invoice.pharmacy).session(session);
    if (!hub) throw new Error('Hub not found');

    // 1. Handle related items/excesses
    for (const item of invoice.items) {
        const excess = await mongoose.model('StockExcess').findById(item.excess).session(session);
        if (excess) {
            const taken = excess.originalQuantity - excess.remainingQuantity;
            if (taken > 0) {
                throw new Error(`Cannot delete invoice. Stock from item ${item.product} has already been sold.`);
            }
            // Cancel or delete the excess
            excess.status = 'cancelled';
            await excess.save({ session });
        }
    }

    // 2. Reverse Cash Balance
    const previousCashBalance = hub.cashBalance;
    hub.cashBalance += invoice.totalAmount;
    await hub.save({ session });

    // 3. Record History
    await CashBalanceHistory.create([{
        pharmacy: hub._id,
        type: 'deposit',
        amount: invoice.totalAmount,
        previousBalance: previousCashBalance,
        newBalance: hub.cashBalance,
        relatedEntity: invoice._id,
        relatedEntityType: 'PurchaseInvoice',
        description: `Reversal: Purchase Invoice Deleted #${invoice._id.toString().slice(-6).toUpperCase()}`,
        description_ar: `عكس: تم حذف فاتورة شراء #${invoice._id.toString().slice(-6).toUpperCase()}`,
        details: { invoiceId: invoice._id }
    }], { session });

    // 4. Delete Invoice
    await PurchaseInvoice.findByIdAndDelete(invoiceId).session(session);
    return true;
};
