const { SalesInvoice, Pharmacy, CashBalanceHistory, BalanceHistory, StockExcess, User } = require('../models');
const { syncExcessStatus } = require('./excessService');
const { sendToUser } = require('../utils/pusherManager');


/**
 * Creates a sales invoice record for tracking hub revenue.
 * Handles itemized sales, stock deduction, and cash balance update.
 */
exports.createSalesInvoice = async (data, pharmacyId, session) => {
    const { items, date } = data; // items: [{ excessId, quantity, sellingPrice }]
    
    const hub = await Pharmacy.findById(pharmacyId).session(session);
    if (!hub || !hub.isHub) throw { message: 'Pharmacy is not a hub', code: 403 };

    let totalBuyingPrice = 0;
    let totalSellingPrice = 0;
    const processedItems = [];

    // Process each item
    for (const item of items) {
        const excess = await StockExcess.findById(item.excess).session(session);
        if (!excess) throw { message: `Stock Excess not found for item`, code: 404 };
        
        if (excess.remainingQuantity < item.quantity) {
             throw { message: `Insufficient quantity for ${excess.product}. Available: ${excess.remainingQuantity}, Requested: ${item.quantity}`, code: 400 };
        }

        // Deduct Quantity
        excess.remainingQuantity -= item.quantity;
        if (excess.remainingQuantity === 0) {
            excess.status = 'fulfilled'; // Mark as fulfilled if all sold
        }
        await excess.save({ session });

        // Calculate Buying/Cost Price
        let costPrice = excess.purchasePrice;
        if (costPrice === undefined || costPrice === null) {
            throw { message: `Cost price not found for ${excess.product}`, code: 400 };
        }
        
        // Ensure accurate unit cost for this transaction
        const itemBuyingPrice = costPrice; // Unit Cost
        const itemSellingPrice = item.sellingPrice; // Unit Sale Price

        totalBuyingPrice += itemBuyingPrice * item.quantity;
        totalSellingPrice += itemSellingPrice * item.quantity;

        processedItems.push({
            excess: excess._id,
            product: excess.product,
            volume: excess.volume,
            quantity: item.quantity,
            buyingPrice: itemBuyingPrice,
            sellingPrice: itemSellingPrice
        });
    }

    const totalRevenuePrice = totalSellingPrice - totalBuyingPrice;

    const invoice = new SalesInvoice({
        pharmacy: pharmacyId,
        items: processedItems,
        totalBuyingPrice,
        totalSellingPrice,
        totalRevenuePrice,
        date: date || new Date()
    });

    await invoice.save({ session });

    // Update Hub Cash Balance (Sale increases cash by total selling price)
    const previousCashBalance = hub.cashBalance;
    const previousBalance = hub.balance;
    
    hub.cashBalance += totalSellingPrice;
    hub.balance += totalBuyingPrice; // Add back purchase price to cancel inventory cost
    
    await hub.save({ session });
    
   

    // Record History in CashBalanceHistory (total selling price)
    await CashBalanceHistory.create([{
        pharmacy: pharmacyId,
        type: 'deposit',
        amount: totalSellingPrice,
        previousBalance: previousCashBalance,
        newBalance: hub.cashBalance,
        relatedEntity: invoice._id,
        relatedEntityType: 'SalesInvoice',
        description: `Sales Invoice #${invoice._id.toString().slice(-6).toUpperCase()}`,
        description_ar: `فاتورة بيع #${invoice._id.toString().slice(-6).toUpperCase()}`,
        details: { invoiceId: invoice._id }
    }], { session });

    // Record History in BalanceHistory (purchase price recovery)
    await BalanceHistory.create([{
        pharmacy: pharmacyId,
        type: 'sales_invoice',
        amount: totalBuyingPrice,
        previousBalance: previousBalance,
        newBalance: hub.balance,
        relatedEntity: invoice._id,
        relatedEntityType: 'SalesInvoice',
        description: `Sales Invoice Cost Recovery #${invoice._id.toString().slice(-6).toUpperCase()}`,
        description_ar: `استرداد تكلفة فاتورة بيع #${invoice._id.toString().slice(-6).toUpperCase()}`,
        details: { 
            invoiceId: invoice._id,
            totalSellingPrice,
            totalBuyingPrice,
            profit: totalRevenuePrice
        }
    }], { session });

     // Trigger Real-time Balance Update
    const users = await User.find({ pharmacy: pharmacyId });
    for (const u of users) {
        await sendToUser(u._id.toString(), 'balanceUpdate', {
            balance: hub.balance
        });
    }

    return invoice;
};

exports.getInvoicesByPharmacy = async (pharmacyId) => {
    return await SalesInvoice.find({ pharmacy: pharmacyId })
        .populate('items.product', 'name')
        .populate('items.volume', 'name')
        .sort({ date: -1 });
};

/**
 * Updates an existing sales invoice with strict per-item logic.
 * 
 * Logic Rules:
 * 1. Adding new items is NOT allowed (returns error).
 * 2. Deleting existing items IS allowed and restores stock to the corresponding StockExcess.
 * 3. Modification rules:
 *    - Quantity: Can be changed. Increases require stock availability. Decreases restore stock.
 *    - Selling Price: Can be changed.
 *    - Buying Price: Refreshed from the original StockExcess to ensure accuracy.
 * 4. Cash balance is automatically adjusted (deducted for reductions/deletions, added for increases).
 * 
 * @param {string} invoiceId - ID of the invoice to update.
 * @param {Object} data - Update data containing { items, date }. Items should have _id or excess.
 * @param {Object} req - Request object for audit logging.
 * @param {Object} session - Mongoose session for transaction.
 * @returns {Promise<Object>} Updated invoice.
 */
exports.updateSalesInvoice = async (invoiceId, data, req, session) => {
    const { items, date } = data;
    console.log("items",items)
    // 1. Fetch Invoice and Hub
    const invoice = await SalesInvoice.findById(invoiceId).session(session);
    if (!invoice) throw { message: 'Sales Invoice not found', code: 404 };

    const hub = await Pharmacy.findById(invoice.pharmacy).session(session);
    if (!hub) throw { message: 'Hub not found', code: 404 };

    const oldSellingTotal = invoice.totalSellingPrice;
    let hasChanged = false;

    if (date && new Date(date).getTime() !== new Date(invoice.date).getTime()) {
        invoice.date = new Date(date);
        hasChanged = true;
    }
    
    // Map existing items for lookup
    const existingItemMap = new Map();
    invoice.items.forEach(item => {
        existingItemMap.set(item.excess.toString(), item); // Fallback
    });

    const inputItemIds = new Set(items.map(i => ( i.excess).toString()));

    // 2. Identify Deletions & Restore Stock
    for (const existingItem of invoice.items) {
        if (!inputItemIds.has(existingItem.excess.toString())) {
            const excess = await StockExcess.findById(existingItem.excess).session(session);
            if (excess) {
                excess.remainingQuantity += existingItem.quantity;
                //sync the excess status service
                await syncExcessStatus(excess, session);
                hasChanged = true;
            }
        }
    }

    const finalItems = [];
    let totalBuyingPrice = 0;
    let totalSellingPrice = 0;

    // 3. Process Input Items (Modifications & Existence Check)
    for (const inputItem of items) {
        const identifier = (inputItem.excess).toString();
        const existingItem = existingItemMap.get(identifier);

        if (!existingItem) {
            throw { message: 'Adding new items to an existing invoice is not allowed. Please create a new invoice.', code: 400 };
        }

        const excess = await StockExcess.findById(existingItem.excess).session(session);
        if (!excess) throw { message: `Stock record for item ${identifier} not found.`, code: 404 };

        // Modification: Quantity
        if (inputItem.quantity !== undefined && inputItem.quantity !== existingItem.quantity) {
            const qDiff = inputItem.quantity - existingItem.quantity;
            
            // If increase, check availability
            if (qDiff > 0 && excess.remainingQuantity < qDiff) {
                throw { message: `Insufficient stock for item ${excess.product}. Available: ${excess.remainingQuantity}, additional needed: ${qDiff}`, code: 400 };
            }

            // Sync stock
            excess.remainingQuantity -= qDiff;
            await syncExcessStatus(excess, session);
            existingItem.quantity = inputItem.quantity;
        }

        // Modification: Selling Price
        if (inputItem.sellingPrice !== undefined && inputItem.sellingPrice !== existingItem.sellingPrice) {
            existingItem.sellingPrice = inputItem.sellingPrice;
            hasChanged = true;
        }

        // Always sync buyingPrice from excess for accuracy (in case it changed)
        if (excess.purchasePrice !== existingItem.buyingPrice) {
            existingItem.buyingPrice = excess.purchasePrice || existingItem.buyingPrice;
            hasChanged = true;
        }

        // Finalize item
        totalBuyingPrice += existingItem.buyingPrice * existingItem.quantity;
        totalSellingPrice += existingItem.sellingPrice * existingItem.quantity;
        finalItems.push(existingItem);
    }

    // 4. Update Invoice Record
    if (hasChanged || invoice.items.length !== finalItems.length) {
        invoice.items = finalItems;
        invoice.totalBuyingPrice = totalBuyingPrice;
        invoice.totalSellingPrice = totalSellingPrice;
        invoice.totalRevenuePrice = totalSellingPrice - totalBuyingPrice;
        await invoice.save({ session });

        const auditService = require('./auditService');
        await auditService.logAction({
            user: req?.user?._id,
            action: 'UPDATE',
            entityType: 'SalesInvoice',
            entityId: invoice._id,
            changes: data
        }, req);
    }

    // 5. Correct Hub Cash Balance AND Regular Balance
    const oldBuyingPrice = invoice.items.reduce((sum, item) => sum + (item.buyingPrice * item.quantity), 0);
    const balanceDiff = totalSellingPrice - oldSellingTotal;
    const buyingPriceDiff = totalBuyingPrice - oldBuyingPrice;
    
    if (balanceDiff !== 0 || buyingPriceDiff !== 0) {
        const prevCashBalance = hub.cashBalance;
        const prevBalance = hub.balance;
        
        hub.cashBalance += balanceDiff; 
        hub.balance += buyingPriceDiff; // Adjust inventory cost recovery
        await hub.save({ session });
        
        

        // CashBalanceHistory for cash changes
        if (balanceDiff !== 0) {
            await CashBalanceHistory.create([{
                pharmacy: hub._id,
                type: balanceDiff > 0 ? 'deposit' : 'withdrawal',
                amount: Math.abs(balanceDiff),
                previousBalance: prevCashBalance,
                newBalance: hub.cashBalance,
                relatedEntity: invoice._id,
                relatedEntityType: 'SalesInvoice',
                description: `Correction: Sales Invoice Updated #${invoice._id.toString().slice(-6).toUpperCase()}`,
                description_ar: `تصحيح: تم تحديث فاتورة بيع #${invoice._id.toString().slice(-6).toUpperCase()}`,
                details: { invoiceId: invoice._id, diff: balanceDiff }
            }], { session });
        }
        
        // BalanceHistory for buying price changes
        if (buyingPriceDiff !== 0) {
            await BalanceHistory.create([{
                pharmacy: hub._id,
                type: 'sales_invoice',
                amount: buyingPriceDiff,
                previousBalance: prevBalance,
                newBalance: hub.balance,
                relatedEntity: invoice._id,
                relatedEntityType: 'SalesInvoice',
                description: `Correction: Sales Invoice Cost Updated #${invoice._id.toString().slice(-6).toUpperCase()}`,
                description_ar: `تصحيح: تم تحديث تكلفة فاتورة بيع #${invoice._id.toString().slice(-6).toUpperCase()}`,
                details: { invoiceId: invoice._id, buyingPriceDiff }
            }], { session });
        }

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
 * Deletes a sales invoice and reverses its effects:
 * 1. Restores the quantity to the respective StockExcess records.
 * 2. Reverses the cash balance increase from the sale.
 */
exports.deleteSalesInvoice = async (invoiceId, session) => {
    const invoice = await SalesInvoice.findById(invoiceId).session(session);
    if (!invoice) throw { message: 'Invoice not found', code: 404 };

    const hub = await Pharmacy.findById(invoice.pharmacy).session(session);
    if (!hub) throw { message: 'Hub not found', code: 404 };

    // 1. Restore Stock for each item
    for (const item of invoice.items) {
        const excess = await StockExcess.findById(item.excess).session(session);
        if (excess) {
            excess.remainingQuantity += item.quantity;
            //sync the excess status service
            await syncExcessStatus(excess, session);
        }
    }

    // 2. Update Hub Cash Balance AND Regular Balance
    const previousCashBalance = hub.cashBalance;
    const previousBalance = hub.balance;
    
    hub.cashBalance -= invoice.totalSellingPrice;
    hub.balance -= invoice.totalBuyingPrice; // Reverse purchase price recovery
    
    await hub.save({ session });
    
    

    // 3. Record History in CashBalanceHistory
    await CashBalanceHistory.create([{
        pharmacy: hub._id,
        type: 'withdrawal',
        amount: invoice.totalSellingPrice,
        previousBalance: previousCashBalance,
        newBalance: hub.cashBalance,
        relatedEntity: invoice._id,
        relatedEntityType: 'SalesInvoice',
        description: `Reversal: Sales Invoice Deleted #${invoice._id.toString().slice(-6).toUpperCase()}`,
        description_ar: `عكس: تم حذف فاتورة بيع #${invoice._id.toString().slice(-6).toUpperCase()}`,
        details: { invoiceId: invoice._id }
    }], { session });
    
    // 4. Record History in BalanceHistory (purchase price reversal)
    await BalanceHistory.create([{
        pharmacy: hub._id,
        type: 'sales_invoice',
        amount: -invoice.totalBuyingPrice,
        previousBalance: previousBalance,
        newBalance: hub.balance,
        relatedEntity: invoice._id,
        relatedEntityType: 'SalesInvoice',
        description: `Reversal: Sales Invoice Cost Deleted #${invoice._id.toString().slice(-6).toUpperCase()}`,
        description_ar: `عكس: تم حذف تكلفة فاتورة بيع #${invoice._id.toString().slice(-6).toUpperCase()}`,
        details: { invoiceId: invoice._id, buyingPrice: invoice.totalBuyingPrice }
    }], { session });   
    // Trigger Real-time Balance Update
    const users = await User.find({ pharmacy: hub._id });
    for (const u of users) {
        await sendToUser(u._id.toString(), 'balanceUpdate', {
            balance: hub.balance
        });
    }
    // 5. Delete Invoice
    await SalesInvoice.findByIdAndDelete(invoiceId).session(session);
    return true;
};
