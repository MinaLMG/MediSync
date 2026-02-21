const { PurchaseInvoice, Pharmacy, CashBalanceHistory,BalanceHistory, User } = require('../models');
const { sendToUser } = require('../utils/pusherManager');
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
    if (!hub || !hub.isHub) throw { message: 'Pharmacy is not a hub', code: 403 };

    if (hub.cashBalance < totalAmount) {
        throw { message: `Insufficient cash balance. Required: ${totalAmount}, Current: ${hub.cashBalance}`, code: 400 };
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

        // Approve and mark as hub purchase
        await excessService.approveExcess(excess._id, session);
        
        excess.isHubGenerated = false; // NOT a transfer
        excess.isHubPurchase = true;   // Direct purchase from supplier
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
    // 3. Update Hub Cash Balance AND Regular Balance
    const previousCashBalance = hub.cashBalance;
    const previousBalance = hub.balance;
    
    // Deduct from BOTH cash balance AND regular balance
    hub.cashBalance -= totalAmount;
    hub.balance -= totalAmount;
    
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

    // 5. Record History in BalanceHistory (for regular balance)
    await BalanceHistory.create([{
        pharmacy: pharmacyId,
        type: 'purchase_invoice',
        amount: -totalAmount,
        previousBalance: previousBalance,
        newBalance: hub.balance,
        relatedEntity: invoice._id,
        relatedEntityType: 'PurchaseInvoice',
        description: `Purchase Invoice #${invoice._id.toString().slice(-6).toUpperCase()}`,
        description_ar: `فاتورة شراء #${invoice._id.toString().slice(-6).toUpperCase()}`,
        details: { invoiceId: invoice._id }
    }], { session });
    // Trigger Real-time Balance Update
    const users = await User.find({ pharmacy: hub._id });
    for (const u of users) {
        await sendToUser(u._id.toString(), 'balanceUpdate', {
            balance: hub.balance
        });
    }
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
    if (!invoice) throw { message: 'Purchase Invoice not found', code: 404 };
    
    const hub = await Pharmacy.findById(invoice.pharmacy).session(session);
    if (!hub) throw { message: 'Hub not found', code: 404 };

    const oldTotal = invoice.totalAmount;
    let newTotal = 0;
    let hasChanged = false;

    if (date && new Date(date).getTime() !== new Date(invoice.date).getTime()) {
        invoice.date = new Date(date);
        hasChanged = true;
    }

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
                    throw { message: `Cannot delete item "${existingItem.product_name || 'Stock'}" because ${taken} units have already been sold/taken.`, code: 409 };
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
            throw { message: 'Adding new items to an existing invoice is not allowed. Please create a new invoice.', code: 400 }; // Skip items without identifier
        
        const identifier = inputItem.excess.toString();
        const existingItem = existingItemMap.get(identifier);

        if (!existingItem) {
            throw { message: 'Adding new items to an existing invoice is not allowed. Please create a new invoice.', code: 400 };
        }

        const excess = await mongoose.model('StockExcess').findById(existingItem.excess.toString()).session(session);
        if (!excess) throw { message: `Stock record for item ${identifier} not found.`, code: 404 };

        const taken = excess.originalQuantity - excess.remainingQuantity;

        // Validation: Product/Volume cannot change
        if (inputItem.product && inputItem.product.toString() !== existingItem.product.toString()) {
            throw { message: 'Changing product is not allowed in an invoice update.', code: 400 };
        }
        if (inputItem.volume && inputItem.volume.toString() !== existingItem.volume.toString()) {
            throw { message: 'Changing volume is not allowed in an invoice update.', code: 400 };
        }

        // Modification: Expiry, SellingPrice, SalePercentage (Only if not taken)
        if (taken > 0) {
            if (inputItem.sellingPrice !== undefined && inputItem.sellingPrice !== existingItem.sellingPrice) {
                throw { message: `Cannot change selling price of item because stock usage has already started (${taken} units taken).`, code: 400 };
            }
            if (inputItem.salePercentage !== undefined && inputItem.salePercentage !== existingItem.salePercentage) {
                throw { message: `Cannot change sale percentage of item because stock usage has already started.`, code: 400 };
            }
            if (inputItem.expiryDate && inputItem.expiryDate !== existingItem.expiryDate) {
                 throw { message: `Cannot change expiry date because stock usage has already started.`, code: 400 };
            }
        } else {
            if (inputItem.sellingPrice !== undefined && inputItem.sellingPrice !== existingItem.sellingPrice) {
                excess.selectedPrice = inputItem.sellingPrice;
                existingItem.sellingPrice = inputItem.sellingPrice;
                hasChanged = true;
            }
            if (inputItem.salePercentage !== undefined && inputItem.salePercentage !== existingItem.salePercentage) {
                excess.salePercentage = inputItem.salePercentage;
                existingItem.salePercentage = inputItem.salePercentage;
                hasChanged = true;
            }
            if (inputItem.expiryDate && inputItem.expiryDate !== existingItem.expiryDate) {
                excess.expiryDate = inputItem.expiryDate;
                existingItem.expiryDate = inputItem.expiryDate;
                hasChanged = true;
            }
        }

        // Modification: Buying Price (Always allowed)
        if (inputItem.buyingPrice !== undefined && inputItem.buyingPrice !== existingItem.buyingPrice) {
            existingItem.buyingPrice = inputItem.buyingPrice;
            excess.purchasePrice = inputItem.buyingPrice;
            hasChanged = true;
            // Propagate only if it actually changed
            await excessService.propagateBuyingPriceUpdate(excess._id, inputItem.buyingPrice, session);
        }

        // Modification: Quantity
        if (inputItem.quantity !== undefined && inputItem.quantity !== existingItem.quantity) {
            if (inputItem.quantity < taken) {
                throw { message: `New quantity (${inputItem.quantity}) cannot be less than units already taken/sold (${taken}).`, code: 400 };
            }
            const qDiff = inputItem.quantity - existingItem.quantity;
            excess.originalQuantity = inputItem.quantity;
            excess.remainingQuantity += qDiff;
            existingItem.quantity = inputItem.quantity;
            hasChanged = true;
        }

        if (hasChanged) await excessService.syncExcessStatus(excess, session);
        // Finalize item for the invoice
        existingItem.total = existingItem.quantity * existingItem.buyingPrice;
        newTotal += existingItem.total;
        finalItems.push(existingItem);
    }

    // 4. Update Invoice Record
    if (hasChanged || invoice.items.length !== finalItems.length) {
        invoice.items = finalItems;
        invoice.totalAmount = newTotal;
        await invoice.save({ session });
        
        const auditService = require('./auditService');
        await auditService.logAction({
            user: req.user._id,
                action: 'UPDATE',
                entityType: 'PurchaseInvoice',
                entityId: invoice._id,
                changes: req.body
            }, req);
    }

    // 5. Correct Hub Cash Balance AND Regular Balance
    const balanceDiff = newTotal - oldTotal;
    if (balanceDiff !== 0) {
        if (balanceDiff > 0 && hub.cashBalance < balanceDiff) {
            throw { message: `Insufficient cash balance for increase. Need ${balanceDiff}, have ${hub.cashBalance}.`, code: 400 };
        }

        const prevCashBalance = hub.cashBalance;
        const prevBalance = hub.balance;
        
        // Adjust both balances
        hub.cashBalance -= balanceDiff;
        hub.balance -= balanceDiff;
        await hub.save({ session });
        
        

        // Record CashBalanceHistory
        await CashBalanceHistory.create([{
            pharmacy: hub._id,
            type: balanceDiff > 0 ? 'withdrawal' : 'deposit',
            amount: Math.abs(balanceDiff),
            previousBalance: prevCashBalance,
            newBalance: hub.cashBalance,
            relatedEntity: invoice._id,
            relatedEntityType: 'PurchaseInvoice',
            description: `Correction: Purchase Invoice Updated #${invoice._id.toString().slice(-6).toUpperCase()}`,
            description_ar: `تصحيح: تم تحديث فاتورة شراء #${invoice._id.toString().slice(-6).toUpperCase()}`,
            details: { invoiceId: invoice._id, diff: -balanceDiff }
        }], { session });
        
        // Record BalanceHistory
        await BalanceHistory.create([{
            pharmacy: hub._id,
            type: 'purchase_invoice',
            amount: -balanceDiff,
            previousBalance: prevBalance,
            newBalance: hub.balance,
            relatedEntity: invoice._id,
            relatedEntityType: 'PurchaseInvoice',
            description: `Correction: Purchase Invoice Updated #${invoice._id.toString().slice(-6).toUpperCase()}`,
            description_ar: `تصحيح: تم تحديث فاتورة شراء #${invoice._id.toString().slice(-6).toUpperCase()}`,
            details: { invoiceId: invoice._id, diff: -balanceDiff }
        }], { session });
        // Trigger Real-time Balance Update
        const users = await User.find({ pharmacy: hub._id });
        for (const u of users) {
            await sendToUser(u._id.toString(), 'balanceUpdate', {
                balance: hub.balance
            });
        }
    }

    return invoice;
};

/**
 * Deletes a purchase invoice and reverses its effects.
 */
exports.deletePurchaseInvoice = async (invoiceId, session) => {
    const invoice = await PurchaseInvoice.findById(invoiceId).session(session);
    if (!invoice) throw { message: 'Invoice not found', code: 404 };

    const hub = await Pharmacy.findById(invoice.pharmacy).session(session);
    if (!hub) throw { message: 'Hub not found', code: 404 };

    // 1. Handle related items/excesses
    for (const item of invoice.items) {
        const excess = await mongoose.model('StockExcess').findById(item.excess).session(session);
        if (excess) {
            const taken = excess.originalQuantity - excess.remainingQuantity;
            if (taken > 0) {
                throw { message: `Cannot delete invoice. Stock from item ${item.product} has already been sold.`, code: 409 };
            }
            // Cancel or delete the excess
            excess.status = 'cancelled';
            await excess.save({ session });
        }
    }

    // 2. Reverse Cash Balance AND Regular Balance
    const previousCashBalance = hub.cashBalance;
    const previousBalance = hub.balance;
    
    // Restore both balances
    hub.cashBalance += invoice.totalAmount;
    hub.balance += invoice.totalAmount;
    await hub.save({ session });
    
    // Trigger Real-time Balance Update
    

    // 3. Record CashBalanceHistory
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
    
    // 4. Record BalanceHistory
    await BalanceHistory.create([{
        pharmacy: hub._id,
        type: 'purchase_invoice',
        amount: invoice.totalAmount,
        previousBalance: previousBalance,
        newBalance: hub.balance,
        relatedEntity: invoice._id,
        relatedEntityType: 'PurchaseInvoice',
        description: `Reversal: Purchase Invoice Deleted #${invoice._id.toString().slice(-6).toUpperCase()}`,
        description_ar: `عكس: تم حذف فاتورة شراء #${invoice._id.toString().slice(-6).toUpperCase()}`,
        details: { invoiceId: invoice._id }
    }], { session });
    const users = await User.find({ pharmacy: hub._id });
    for (const u of users) {
        await sendToUser(u._id.toString(), 'balanceUpdate', {
            balance: hub.balance
        });
    }
    // 4. Delete Invoice
    await PurchaseInvoice.findByIdAndDelete(invoiceId).session(session);
    return true;
};
