const mongoose = require('mongoose');
const { Transaction, StockShortage, StockExcess, Pharmacy, Settings, BalanceHistory, User, Reservation } = require('../models');
const { sendToUser } = require('../utils/pusherManager');
const serialService = require('./serialService');

/**
 * Creates a new transaction.
 * MUST be called within a session.
 */
exports.createTransaction = async (data, session, req = null) => {
    const { shortageId, quantityTaken, excessSources, buyerCommissionRatio, sellerBonusRatio, commissionRatio } = data;

    // 1. Check shortage
    const shortage = await StockShortage.findById(shortageId).session(session);
    if (!shortage || !['active', 'partially_fulfilled'].includes(shortage.status)) {
        throw new Error('Shortage not found or not active');
    }

    // 1.1 Check Product Status
    const productObj = await mongoose.model('Product').findById(shortage.product).session(session);
    if (!productObj || productObj.status !== 'active') {
        throw new Error('This product is currently inactive and cannot be transacted.');
    }

    const remainingNeeded = shortage.remainingQuantity;
    if (quantityTaken > remainingNeeded) {
        throw new Error(`Requested quantity (${quantityTaken}) exceeds remaining needed (${remainingNeeded})`);
    }

    let totalAmount = 0;
    let totalQuantity = 0;
    const refinedSources = [];
    let shortage_fulfillment =false

    // 2. Check and update excesses
    for (const source of excessSources) {
        const excess = await StockExcess.findById(source.stockExcessId).session(session);
        if (!excess || !['available', 'partially_fulfilled'].includes(excess.status) || excess.remainingQuantity < source.quantity) {
            throw new Error(`Excess ${source.stockExcessId} is no longer available in requested quantity`);
        }
if (excess.shortage_fulfillment) {
    shortage_fulfillment = true;
}
        // Deduct from excess
        excess.remainingQuantity -= source.quantity;
        await excess.save({ session });
        
        const amount = source.quantity * excess.selectedPrice;
        totalAmount += amount;
        totalQuantity += source.quantity;

        refinedSources.push({
            stockExcess: excess._id,
            quantity: source.quantity,
            agreedPrice: excess.selectedPrice,
            totalAmount: amount
        });
    }

    if (totalQuantity !== quantityTaken) {
        throw new Error('Total quantity from sources does not match quantity taken from shortage');
    }

    // 3. Update shortage
    shortage.remainingQuantity -= quantityTaken;
    const { syncShortageStatus } = require('./shortageService');
    await syncShortageStatus(shortage, session);
    await shortage.save({ session });

    // 4. Generate Serial atomically
    const serial = await serialService.generateDateSerial('transaction');

    // 5. Create transaction
    const settings = await Settings.getSettings();
    
    // CASE 1 (Fulfillment): Ratios can be paused (overridden) at creation
    const finalBuyerCommission = buyerCommissionRatio !== undefined 
        ? buyerCommissionRatio / 100 
        : settings.shortageCommission / 100;

    const finalSellerBonus = sellerBonusRatio !== undefined 
        ? sellerBonusRatio / 100 
        : settings.shortageSellerReward / 100;

    // CASE 2 (Regular): System commission is FIXED and never paused
    const baselineSystemCommission = settings.minimumCommission / 100;

    const transaction = new Transaction({
        serial,
        stockShortage: {
            shortage: shortageId,
            quantityTaken
        },
        stockExcessSources: refinedSources,
        totalQuantity,
        totalAmount,
        status: 'pending',
        shortage_fulfillment: shortage_fulfillment,
        commissionRatio: baselineSystemCommission,
        buyerCommissionRatio: finalBuyerCommission,
        sellerBonusRatio: finalSellerBonus
    });

    await transaction.save({ session });

    // 6. Sync excess statuses
    const { syncExcessStatus } = require('./excessService');
    for (const source of refinedSources) {
        const excess = await StockExcess.findById(source.stockExcess).session(session);
        await syncExcessStatus(excess, session);
        await excess.save({ session });
    }

    // 7. Cleanup reservations (async, non-blocking for transaction)
    setImmediate(async () => {
        try {
            const shortagePopulated = await StockShortage.findById(shortageId).populate('order');
            if (shortagePopulated && shortagePopulated.order) {
                // Determine which sale percentage to use for lookup
                const saleToLookup = shortagePopulated.originalSalePercentage || shortagePopulated.salePercentage || 0;
               
                await Reservation.findOneAndUpdate(
                    {
                        product: shortagePopulated.product._id || shortagePopulated.product,
                        volume: shortagePopulated.volume._id || shortagePopulated.volume,
                        price: shortagePopulated.targetPrice,
                        expiryDate: shortagePopulated.expiryDate || "ANY",
                        salePercentage: saleToLookup
                    },
                    { $inc: { quantity: -quantityTaken} }
                );
            }
        } catch (reservationErr) {
            throw new Error(`Critical: Reservation update failed: ${reservationErr.message}`);
        }
    });

    return transaction;
};

/**
 * Updates transaction status (Accepted, Rejected, Completed, Cancelled).
 * MUST be called within a session.
 */
exports.updateTransactionStatus = async (transactionId, status, session, req = null, options = {}) => {
    const transaction = await Transaction.findById(transactionId).session(session);

    if (!transaction) {
        throw new Error('Transaction not found');
    }

    if (transaction.status === 'completed' || transaction.status === 'cancelled') {
        throw new Error('Cannot change status of a finished transaction');
    }

    const oldStatus = transaction.status;
    transaction.status = status;

    if (status === 'cancelled' || status === 'rejected') {
        const { syncExcessStatus } = require('./excessService');
        const { syncShortageStatus } = require('./shortageService');

        // 1. Restore excess quantities
        for (const source of transaction.stockExcessSources) {
            const excess = await StockExcess.findById(source.stockExcess).session(session);
            if (excess) {
                excess.remainingQuantity += source.quantity;
                await syncExcessStatus(excess, session);
                await excess.save({ session });
            }
        }

        // 2. Reduce shortage fulfillment
        const shortage = await StockShortage.findById(transaction.stockShortage.shortage).session(session);
        if (shortage) {
            shortage.remainingQuantity += transaction.stockShortage.quantityTaken;
            await syncShortageStatus(shortage, session);
            await shortage.save({ session });

            // 3. Restore Reservations if part of an order
            if (shortage.order && shortage.targetPrice) {
                const saleToLookup = shortage.originalSalePercentage || shortage.salePercentage || 0;
                await Reservation.findOneAndUpdate(
                    {
                        product: shortage.product,
                        volume: shortage.volume,
                        price: shortage.targetPrice,
                        expiryDate: shortage.expiryDate || "ANY",
                        salePercentage: saleToLookup
                    },
                    {
                        $inc: { quantity: transaction.stockShortage.quantityTaken }
                    },
                    { upsert: true, session }
                );
            }
        }
    } else if (status === 'completed') {
            await exports.settleTransaction(transaction, session);
    }

    await transaction.save({ session });
    return transaction;
};

/**
 * Executes the financial settlement for a completed transaction.
 * Updates balances, creates ledger entries, and notifies users.
 * MUST be called within a session.
 */
exports.settleTransaction = async (transaction, session) => {

    
    const settings = await Settings.getSettings();
    const systemMinCommRatio = settings.minimumCommission / 100;

    const shortage = await StockShortage.findById(transaction.stockShortage.shortage).session(session);
    const buyerPh = await Pharmacy.findById(shortage.pharmacy).session(session);

    let totalBuyerEffect = 0;
    let buyerDetailsList = [];

    // 1. Process Seller Effects (and accumulate Buyer effects)
    for (let i = 0; i < transaction.stockExcessSources.length; i++) {
        const source = transaction.stockExcessSources[i];
        const excess = await StockExcess.findById(source.stockExcess).session(session);
        const sellerPh = await Pharmacy.findById(excess.pharmacy).session(session);

        if (sellerPh) {
            let sellerEffect = 0;
            let sellerDetails = {};
            let sourceBuyerEffect = 0;
            let sourceBuyerDetails = {};

            if (excess.shortage_fulfillment) {
                // CASE 1: Shortage Fulfillment
                let bonusRatio = transaction.sellerBonusRatio !== undefined
                    ? transaction.sellerBonusRatio
                    : (settings.shortageSellerReward / 100);
                
                let commRatio = transaction.buyerCommissionRatio !== undefined
                    ? transaction.buyerCommissionRatio
                    : (settings.shortageCommission / 100);

                // Override for Hub
                if (sellerPh.isHub) bonusRatio = 0;
                if (buyerPh.isHub) commRatio = 0;

                sellerEffect = (1 + bonusRatio) * source.totalAmount;
                sellerDetails = {
                    type: 'shortage_fulfillment',
                    baseAmount: source.totalAmount,
                    bonusRatio: bonusRatio
                };

                sourceBuyerEffect = -(1 + commRatio) * source.totalAmount;
                sourceBuyerDetails = {
                    type: 'shortage_fulfillment',
                    baseAmount: source.totalAmount,
                    commissionRatio: commRatio,
                    excessId: excess._id
                };
            } else {
                // CASE 2: REGULAR TRANSACTION (Market Order or Direct Match)
                
                // 1. Validation: original sale percentage must match if it exists
                if (shortage.originalSalePercentage && shortage.originalSalePercentage !== excess.salePercentage) {
                    throw new Error(`Data Mismatch: Original sale percentage for excess ${excess._id} is ${excess.salePercentage}%, but shortage expected ${shortage.originalSalePercentage}%. Please re-list or adjust stock.`);
                }

                // 2. Calculate Commission Ratio (Seller Pays)
                // Commission = max(system default commission, excess sale value)
                let sellerCommissionRatio = Math.max(
                    settings.minimumCommission / 100,
                    (excess.salePercentage || 0) / 100
                );

                // 3. Calculate Sale Ratio (Buyer Receives)
                // The sale the buyer explicitly selected and agreed on (from shortage)
                let buyerSaleRatio = (shortage.salePercentage || 0) / 100;

                // Hub Rule: If either party is a hub, commission must be set to 0%
                if (sellerPh.isHub) {
                    sellerCommissionRatio = 0;
                }
                if (buyerPh.isHub) { 
                    buyerSaleRatio = 0;
                }

                // Financials
                // Seller Receives: Price * (1 - sellerCommissionRatio)
                sellerEffect = (1 - sellerCommissionRatio) * source.totalAmount;
                
                sellerDetails = {
                    type: 'excess_rebalance',
                    baseAmount: source.totalAmount,
                    commissionRatio: sellerCommissionRatio,
                    originalSale: excess.salePercentage
                };

                // Buyer Pays: Price * (1 - buyerSaleRatio)
                sourceBuyerEffect = -(1 - buyerSaleRatio) * source.totalAmount;
                
                sourceBuyerDetails = {
                    type: 'excess_rebalance',
                    baseAmount: source.totalAmount,
                    saleRatio: buyerSaleRatio,
                    excessId: excess._id
                };
            }

            // Update Seller
            const sellerPrevBalance = sellerPh.balance;
            sellerPh.balance += sellerEffect;
            const sellerNewBalance = sellerPh.balance;

            transaction.stockExcessSources[i].balanceEffect = sellerEffect;
            await sellerPh.save({ session });

            await BalanceHistory.create([{
                pharmacy: sellerPh._id,
                type: 'transaction_revenue',
                amount: sellerEffect,
                previousBalance: sellerPrevBalance,
                newBalance: sellerNewBalance,
                relatedEntity: transaction._id,
                relatedEntityType: 'Transaction',
                description: `Revenue for transaction #${transaction.serial}`,
                description_ar: `عائد للمعاملة #${transaction.serial}`,
                details: sellerDetails
            }], { session });

            // Websocket notification
            try {
                const sellerUsers = await User.find({ pharmacy: sellerPh._id }).session(session);
                for (const user of sellerUsers) {
                    sendToUser(user._id.toString(), 'balanceUpdate', { balance: sellerPh.balance });
                }
            } catch (err) {}

            totalBuyerEffect += sourceBuyerEffect;
            buyerDetailsList.push(sourceBuyerDetails);
        }
    }

// 2. Process Final Buyer Effect
    if (buyerPh) {
        const buyerPrevBalance = buyerPh.balance;
        buyerPh.balance += totalBuyerEffect;
        const buyerNewBalance = buyerPh.balance;

        transaction.stockShortage.balanceEffect = totalBuyerEffect;
        await buyerPh.save({ session });

        await BalanceHistory.create([{
            pharmacy: buyerPh._id,
            type: 'transaction_payment',
            amount: totalBuyerEffect,
            previousBalance: buyerPrevBalance,
            newBalance: buyerNewBalance,
            relatedEntity: transaction._id,
            relatedEntityType: 'Transaction',
            description: `Payment for transaction #${transaction.serial}`,
            description_ar: `دفع للمعاملة #${transaction.serial}`,
            details: {
                sources: buyerDetailsList,
                totalBuyerEffect
            }
        }], { session });

        try {
            const buyerUsers = await User.find({ pharmacy: buyerPh._id }).session(session);
            for (const user of buyerUsers) {
                sendToUser(user._id.toString(), 'balanceUpdate', { balance: buyerPh.balance });
            }
        } catch (err) {}
    }

    // 3. Final stock sync
    for (const source of transaction.stockExcessSources) {
        const excess = await StockExcess.findById(source.stockExcess).session(session);
        if (excess) {
            const { syncExcessStatus } = require('./excessService');
            await syncExcessStatus(excess, session);
            await excess.save({ session });
        }
    }
    

};

/**
 * Notifies all stakeholders (buyer, sellers, delivery) about a transaction status change.
 * This should be called AFTER the DB transaction is committed to ensure delivery.
 */
exports.notifyParties = async (transaction) => {
    try {
        const { addNotificationJob } = require('../utils/queueManager');
        const Product = mongoose.model('Product');

        // 1. Fetch Stakeholders and Context
        const shortage = await StockShortage.findById(transaction.stockShortage.shortage).populate('product').populate('pharmacy');
        if (!shortage) return;

        const buyerPhId = shortage.pharmacy._id;
        const buyerIsHub = shortage.pharmacy.isHub;
        
        // Hide Hub Name
        const productName = shortage.product?.name || 'medicine';
        
        // Find all unique sellers
        const uniqueSellerPhIds = [...new Set(transaction.stockExcessSources.map(s => {
            if (s.sellerPharmacy && s.sellerPharmacy._id) return s.sellerPharmacy._id.toString();
            return s.sellerPharmacy?.toString();
        }).filter(Boolean))];

        const statusMsg = transaction.status.charAt(0).toUpperCase() + transaction.status.slice(1);
        const staticStatusAr = {
            'pending': 'قيد الانتظار',
            'accepted': 'مقبولة',
            'rejected': 'مرفوضة',
            'completed': 'مكتملة',
            'cancelled': 'ملغاة'
        };
        const statusMsgAr = staticStatusAr[transaction.status.toLowerCase()] || transaction.status;
        const serialMsg = `Transaction #${transaction.serial}`;
        const serialMsgAr = `المعاملة #${transaction.serial}`;

        // -- Notify Buyer --
        // If buyer is Hub, maybe we don't need to notify them in the same way? 
        // User asked: "i don't need the user to know anything about hub"
        // This implies if the User is the Buyer or Seller, they shouldn't see "Hub".
        // If User is Seller (selling to Hub), they interact with "Hub" (masked).
        
        // Notify Buyer standard logic
        const buyerUsers = await User.find({ pharmacy: buyerPhId });
        for (const user of buyerUsers) {
            await addNotificationJob(
                user._id.toString(),
                'transaction',
                `Transaction for "${productName}" is now ${statusMsg}.`,
                {
                    relatedEntity: transaction._id,
                    relatedEntityType: 'Transaction'
                },
                `المعاملة الخاصة بـ "${productName}" أصبحت الآن ${statusMsgAr}.`
            );
            sendToUser(user._id.toString(), 'transactionUpdate', { transactionId: transaction._id, status: transaction.status });
        }

        // -- Notify Sellers --
        for (const sellerPhId of uniqueSellerPhIds) {
            const sellerUsers = await User.find({ pharmacy: sellerPhId });
            for (const user of sellerUsers) {
                // If the buyer was a Hub, and we are notifying the seller, the message is generic enough "Your transaction..."
                // It doesn't explicitly say "Sold to Hub".
                // So default message is safe: "Your transaction for X is now Y"
                
                await addNotificationJob(
                    user._id.toString(),
                    'transaction',
                    `Your transaction for "${productName}" is now ${statusMsg}.`,
                    {
                        relatedEntity: transaction._id,
                        relatedEntityType: 'Transaction'
                    },
                    `معاملتك الخاصة بـ "${productName}" أصبحت الآن ${statusMsgAr}.`
                );
                sendToUser(user._id.toString(), 'transactionUpdate', { transactionId: transaction._id, status: transaction.status });
            }
        }

        // -- Notify Delivery (if assigned) --
        if (transaction.delivery) {
            await addNotificationJob(
                transaction.delivery.toString(),
                'transaction',
                `${serialMsg} for "${productName}" has been ${statusMsg}.`,
                {
                    relatedEntity: transaction._id,
                    relatedEntityType: 'Transaction'
                },
                `${serialMsgAr} لـ "${productName}" أصبحت ${statusMsgAr}.`
            );
            sendToUser(transaction.delivery.toString(), 'transactionUpdate', { transactionId: transaction._id, status: transaction.status });
        }

    } catch (error) {
        console.error('Error in notifyParties service:', error);
    }
};

/**
 * Reverts an "Add to Hub" transaction.
 * Specific logic: Cancel Hub Excess, Restore User Excess, Cancel Hub Shortage, Reverse Financials.
 */
exports.revertAddToHub = async (transaction, session, req) => {
    // 1. Fetch and Validate Hub Excess
    const hubExcess = await StockExcess.findById(transaction.added_to_hub.excessId).session(session);
    if (!hubExcess) throw new Error('Hub excess record not found');

    if (hubExcess.remainingQuantity !== hubExcess.originalQuantity) {
        throw new Error('Cannot revert: The transferred stock has already been used by the Hub.');
    }

    // 2. Cancel Hub Excess
    hubExcess.status = 'cancelled';
    let quantiyReverted = hubExcess.remainingQuantity; // Capture for restore
    hubExcess.remainingQuantity = 0; // Ensure it can't be used
    await hubExcess.save({ session });

    // Log the cancellation of the Hub Excess explicitly
    const auditService = require('./auditService');
    await auditService.logAction({
        user: req?.user?._id,
        action: 'CANCEL', 
        entityType: 'StockExcess',
        entityId: hubExcess._id,
        changes: { status: 'cancelled', reversalTransactionId: transaction._id }
    }, req);

    // 3. Cancel Hub Shortage (Do not restore it)
    // Use the global cancel shortage service logic
    const { cancelShortage, syncShortageStatus } = require('./shortageService');
    // Ensure we have ID
    const shortageId = transaction.stockShortage.shortage._id || transaction.stockShortage.shortage;

    // Restore shortage quantity first so it passes the "unused" check in cancelShortage
    const shortage = await StockShortage.findById(shortageId).session(session);
    if (shortage) {
        shortage.remainingQuantity += quantiyReverted;
        await syncShortageStatus(shortage, session);
        await shortage.save({ session });
    }

    await cancelShortage(shortageId, session, req);

    // 4. Restore Source Excesses (User's Stock)
    const { syncExcessStatus } = require('./excessService');
    for (const source of transaction.stockExcessSources) {
        // Handle populated or unpopulated stockExcess
        const excessId = source.stockExcess._id || source.stockExcess;
        const excess = await StockExcess.findById(excessId).session(session);
        if (excess) {
            excess.remainingQuantity += source.quantity;
            await syncExcessStatus(excess, session);
            await excess.save({ session });
        }
    }

    // 5. Financial Reversal
    // 5a. Revert Buyer (Hub) Payment
    // We fetch shortage again or use ID to get pharmacy if needed, but we already have shortageId above.
    // However, shortage object might be needed for pharmacy ID.
    const shortageObj = await StockShortage.findById(shortageId).session(session); 
    const buyerPh = await Pharmacy.findById(shortageObj.pharmacy).session(session);

    if (buyerPh && transaction.stockShortage.balanceEffect) {
        const prevBalance = buyerPh.balance;
        buyerPh.balance -= transaction.stockShortage.balanceEffect; // Subtract the (negative) effect
        await buyerPh.save({ session });

        await BalanceHistory.create([{
            pharmacy: buyerPh._id,
            type: 'transaction_payment',
            amount: -transaction.stockShortage.balanceEffect,
            previousBalance: prevBalance,
            newBalance: buyerPh.balance,
            relatedEntity: transaction._id,
            relatedEntityType: 'Transaction',
            description: `Reversal of payment for transaction #${transaction.serial}`,
            description_ar: `عكس عملية الدفع للمعاملة #${transaction.serial}`,
            details: { type: 'reversal' }
        }], { session });

        // Notify
        try {
            const users = await User.find({ pharmacy: buyerPh._id }).session(session);
            for (const user of users) {
                sendToUser(user._id.toString(), 'balanceUpdate', { balance: buyerPh.balance });
            }
        } catch (e) {}
    }

    // 5b. Revert Seller (User) Revenue
    for (const source of transaction.stockExcessSources) {
        const excessId = source.stockExcess._id || source.stockExcess;
        const excess = await StockExcess.findById(excessId).session(session);
        if (excess && source.balanceEffect) {
            const sellerPh = await Pharmacy.findById(excess.pharmacy).session(session);
            if (sellerPh) {
                const prevBalance = sellerPh.balance;
                sellerPh.balance -= source.balanceEffect;
                await sellerPh.save({ session });

                await BalanceHistory.create([{
                    pharmacy: sellerPh._id,
                    type: 'transaction_revenue',
                    amount: -source.balanceEffect,
                    previousBalance: prevBalance,
                    newBalance: sellerPh.balance,
                    relatedEntity: transaction._id,
                    relatedEntityType: 'Transaction',
                    description: `Reversal of revenue for transaction #${transaction.serial}`,
                    description_ar: `عكس عملية التحصيل للمعاملة #${transaction.serial}`,
                    details: { type: 'reversal' }
                }], { session });

                try {
                    const users = await User.find({ pharmacy: sellerPh._id }).session(session);
                    for (const user of users) {
                        sendToUser(user._id.toString(), 'balanceUpdate', { balance: sellerPh.balance });
                    }
                } catch (e) {}
            }
        }
    }

    // 6. Set Transaction Status
    transaction.status = 'cancelled';
    await transaction.save({ session });

    return transaction;
};
