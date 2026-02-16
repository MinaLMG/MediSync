const { SalesInvoice, Pharmacy, CashBalanceHistory, StockExcess } = require('../models');
const { syncExcessStatus } = require('./excessService');

/**
 * Creates a sales invoice record for tracking hub revenue.
 * Handles itemized sales, stock deduction, and cash balance update.
 */
exports.createSalesInvoice = async (data, pharmacyId, session) => {
    const { items, date } = data; // items: [{ excessId, quantity, sellingPrice }]
    
    const hub = await Pharmacy.findById(pharmacyId).session(session);
    if (!hub || !hub.isHub) throw new Error('Pharmacy is not a hub');

    let totalBuyingPrice = 0;
    let totalSellingPrice = 0;
    const processedItems = [];

    // Process each item
    for (const item of items) {
        const excess = await StockExcess.findById(item.excess).session(session);
        if (!excess) throw new Error(`Stock Excess not found for item`);
        
        if (excess.remainingQuantity < item.quantity) {
             throw new Error(`Insufficient quantity for ${excess.product}. Available: ${excess.remainingQuantity}, Requested: ${item.quantity}`);
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
            throw new Error(`Cost price not found for ${excess.product}`);
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

    // Update Hub Cash Balance (Sale increases cash)
    const previousCashBalance = hub.cashBalance;
    hub.cashBalance += totalSellingPrice;
    await hub.save({ session });

    // Record History in CashBalanceHistory
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
 * @param {Object} session - Mongoose session for transaction.
 * @returns {Promise<Object>} Updated invoice.
 */
exports.updateSalesInvoice = async (invoiceId, data, session) => {
    const { items, date } = data;
    console.log("items",items)
    // 1. Fetch Invoice and Hub
    const invoice = await SalesInvoice.findById(invoiceId).session(session);
    if (!invoice) throw new Error('Sales Invoice not found');

    const hub = await Pharmacy.findById(invoice.pharmacy).session(session);
    if (!hub) throw new Error('Hub not found');

    const oldSellingTotal = invoice.totalSellingPrice;
    
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
            throw new Error('Adding new items to an existing invoice is not allowed. Please create a new invoice.');
        }

        const excess = await StockExcess.findById(existingItem.excess).session(session);
        if (!excess) throw new Error(`Stock record for item ${identifier} not found.`);

        // Modification: Quantity
        if (inputItem.quantity !== undefined && inputItem.quantity !== existingItem.quantity) {
            const qDiff = inputItem.quantity - existingItem.quantity;
            
            // If increase, check availability
            if (qDiff > 0 && excess.remainingQuantity < qDiff) {
                throw new Error(`Insufficient stock for item ${excess.product}. Available: ${excess.remainingQuantity}, additional needed: ${qDiff}`);
            }

            // Sync stock
            excess.remainingQuantity -= qDiff;
            await syncExcessStatus(excess, session);
            existingItem.quantity = inputItem.quantity;
        }

        // Modification: Selling Price
        if (inputItem.sellingPrice !== undefined) {
            existingItem.sellingPrice = inputItem.sellingPrice;
        }

        // Always sync buyingPrice from excess for accuracy (in case it changed)
        existingItem.buyingPrice = excess.purchasePrice || existingItem.buyingPrice;

        // Finalize item
        totalBuyingPrice += existingItem.buyingPrice * existingItem.quantity;
        totalSellingPrice += existingItem.sellingPrice * existingItem.quantity;
        finalItems.push(existingItem);
    }

    // 4. Update Invoice Record
    invoice.items = finalItems;
    invoice.totalBuyingPrice = totalBuyingPrice;
    invoice.totalSellingPrice = totalSellingPrice;
    invoice.totalRevenuePrice = totalSellingPrice - totalBuyingPrice;
    if (date) invoice.date = new Date(date);
    await invoice.save({ session });

    // 5. Correct Hub Cash Balance
    const balanceDiff = totalSellingPrice - oldSellingTotal;
    if (balanceDiff !== 0) {
        // balanceDiff > 0 means more money received (Deposit)
        // balanceDiff < 0 means money refunded to someone? (Withdrawal)
        const prevBalance = hub.cashBalance;
        hub.cashBalance += balanceDiff; 
        await hub.save({ session });

        await CashBalanceHistory.create([{
            pharmacy: hub._id,
            type: balanceDiff > 0 ? 'deposit' : 'withdrawal',
            amount: Math.abs(balanceDiff),
            previousBalance: prevBalance,
            newBalance: hub.cashBalance,
            relatedEntity: invoice._id,
            relatedEntityType: 'SalesInvoice',
            description: `Correction: Sales Invoice Updated #${invoice._id.toString().slice(-6).toUpperCase()}`,
            description_ar: `تصحيح: تم تحديث فاتورة بيع #${invoice._id.toString().slice(-6).toUpperCase()}`,
            details: { invoiceId: invoice._id, diff: balanceDiff }
        }], { session });
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
    if (!invoice) throw new Error('Invoice not found');

    const hub = await Pharmacy.findById(invoice.pharmacy).session(session);
    if (!hub) throw new Error('Hub not found');

    // 1. Restore Stock for each item
    for (const item of invoice.items) {
        const excess = await StockExcess.findById(item.excess).session(session);
        if (excess) {
            excess.remainingQuantity += item.quantity;
            //sync the excess status service
            await syncExcessStatus(excess, session);
        }
    }

    // 2. Update Hub Cash Balance (Reverse selling price - sale increase cash, so deletion reduces it)
    const previousCashBalance = hub.cashBalance;
    hub.cashBalance -= invoice.totalSellingPrice;
    await hub.save({ session });

    // 3. Record History in CashBalanceHistory
    await CashBalanceHistory.create([{
        pharmacy: hub._id,
        type: 'withdrawal', // Deleting a sale is a withdrawal from revenue
        amount: invoice.totalSellingPrice,
        previousBalance: previousCashBalance,
        newBalance: hub.cashBalance,
        relatedEntity: invoice._id,
        relatedEntityType: 'SalesInvoice',
        description: `Reversal: Sales Invoice Deleted #${invoice._id.toString().slice(-6).toUpperCase()}`,
        description_ar: `عكس: تم حذف فاتورة بيع #${invoice._id.toString().slice(-6).toUpperCase()}`,
        details: { invoiceId: invoice._id }
    }], { session });

    // 4. Delete Invoice
    await SalesInvoice.findByIdAndDelete(invoiceId).session(session);
    return true;
};
