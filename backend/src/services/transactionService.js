const mongoose = require('mongoose');
const {
    Transaction,
    StockShortage,
    StockExcess,
    Pharmacy,
    Settings,
    BalanceHistory,
    User,
    Reservation,
    DeliveryRequest,
    Product
} = require('../models');
const { sendToUser = null } = require('../utils/pusherManager') || {};
const serialService = require('./serialService');
const auditService = require('./auditService');

// Lazy-loaded services to avoid circular dependencies (where they reference transactionService)
const getShortageService = () => require('./shortageService');
const getExcessService = () => require('./excessService');

// =============================================================================
// TRANSACTION CREATION & STATUS MANAGEMENT
// =============================================================================

/**
 * Creates a new transaction from a shortage and one or more excess sources.
 * Validates availability, updates inventory, handles reservations, and logs the action.
 * 
 * @param {Object} data - Transaction data (shortageId, quantityTaken, excessSources, etc.)
 * @param {Object} session - Mongoose session for atomicity.
 * @param {Object} [req] - Express request object for audit logging.
 * @returns {Promise<Object>} The created transaction.
 */
exports.createTransaction = async (data, session, req = null) => {
    const { shortageId, quantityTaken, excessSources, buyerCommissionRatio, sellerBonusRatio, commissionRatio } = data;

    // 0. Validate quantity
    if (!quantityTaken || quantityTaken <= 0) {
        throw { message: 'Quantity taken must be a positive number', code: 400 };
    }

    // 1. Check shortage
    const shortage = await StockShortage.findById(shortageId).session(session);
    if (!shortage || !['active', 'partially_fulfilled'].includes(shortage.status)) {
        throw { message: 'Shortage not found or not active', code: 404 };
    }

    // 1.1 Check Product Status
    const productObj = await Product.findById(shortage.product).session(session);
    if (!productObj || productObj.status !== 'active') {
        throw { message: 'This product is currently inactive and cannot be transacted.', code: 400 };
    }

    const remainingNeeded = shortage.remainingQuantity;
    if (quantityTaken > remainingNeeded) {
        throw { message: `Requested quantity (${quantityTaken}) exceeds remaining needed (${remainingNeeded})`, code: 409 };
    }

    let totalAmount = 0;
    let totalQuantity = 0;
    const refinedSources = [];
    let shortage_fulfillment = false

    // 2. Check and update excesses
    for (const source of excessSources) {
        const excess = await StockExcess.findById(source.stockExcessId).session(session);
        if (!excess || !['available', 'partially_fulfilled'].includes(excess.status) || excess.remainingQuantity < source.quantity) {
            throw { message: `Excess ${source.stockExcessId} is no longer available in requested quantity`, code: 409 };
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
        throw { message: 'Total quantity from sources does not match quantity taken from shortage', code: 400 };
    }

    // 3. Update shortage and parent Order
    shortage.remainingQuantity -= quantityTaken;
    await getShortageService().syncShortageStatus(shortage, session);

    // 4. Generate Serial atomically
    const serial = await serialService.generateDateSerial('transaction');

    // 5. Create transaction
    // Ratios are left undefined if not explicitly provided as overrides.
    // This allows settleTransaction to fetch the LATEST system rates at the moment of payment.
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
        // Only store if explicitly provided as overrides (in percentage, so / 100)
        commissionRatio: commissionRatio !== undefined ? commissionRatio / 100 : undefined,
        buyerCommissionRatio: buyerCommissionRatio !== undefined ? buyerCommissionRatio / 100 : undefined,
        sellerBonusRatio: sellerBonusRatio !== undefined ? sellerBonusRatio / 100 : undefined
    });

    await transaction.save({ session });

    // 6. Sync excess statuses to 'fulfilled' or 'partially_fulfilled'
    for (const source of refinedSources) {
        const excess = await StockExcess.findById(source.stockExcess).session(session);
        await getExcessService().syncExcessStatus(excess, session);
    }

    // 7. Cleanup reservations (BLOCKING - critical for data consistency)
    if (shortage.order && shortage.targetPrice) {
        // Determine which sale percentage to use for lookup
        const saleToLookup = shortage.originalSalePercentage || shortage.salePercentage || 0;

        await Reservation.findOneAndUpdate(
            {
                product: shortage.product,
                volume: shortage.volume,
                price: shortage.targetPrice,
                expiryDate: shortage.expiryDate || "ANY",
                salePercentage: saleToLookup
            },
            { $inc: { quantity: -quantityTaken } },
            { session }
        );
    }


    return transaction;
};

/**
 * Updates transaction status (Accepted, Rejected, Completed, Cancelled).
 * Handles stock restoration on cancellation/rejection.
 * 
 * @param {string} transactionId - The ID of the transaction to update.
 * @param {string} status - The target status.
 * @param {Object} req - Request object for audit logging.
 * @param {Object} session - Mongoose session for atomicity.
 * @returns {Promise<Object>} The updated transaction.
 */
exports.updateTransactionStatus = async (transactionId, status, req, session) => {
    const transaction = await Transaction.findById(transactionId).session(session);

    if (!transaction) {
        throw { message: 'Transaction not found', code: 404 };
    }

    if (transaction.status === 'completed' || transaction.status === 'cancelled') {
        throw { message: 'Cannot change status of a finished transaction', code: 409 };
    }

    if (transaction.status === status) {
        return transaction; // No change detected
    }

    const oldStatus = transaction.status;
    if (status !== 'completed') {// the settle transaction is the only function can set transaction status to accepted
        transaction.status = status;
    }
    console.log(`[DEBUG] transaction ${transaction._id} status set to ${transaction.status} (target: ${status})`);

    if (status === 'cancelled' || status === 'rejected') {
        const excessService = getExcessService();
        const shortageService = getShortageService();

        // 1. Restore excess quantities
        for (const source of transaction.stockExcessSources) {
            const excess = await StockExcess.findById(source.stockExcess).session(session);
            if (excess) {
                excess.remainingQuantity += source.quantity;
                await excessService.syncExcessStatus(excess, session);
            }
        }

        // 2. Reduce shortage fulfillment
        const shortage = await StockShortage.findById(transaction.stockShortage.shortage).session(session);
        if (shortage) {
            shortage.remainingQuantity += transaction.stockShortage.quantityTaken;
            await shortageService.syncShortageStatus(shortage, session);

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

        // 4. Reject all pending delivery requests for this transaction
        await DeliveryRequest.updateMany(
            { transaction: transaction._id, status: 'pending' },
            { status: 'rejected' },
            { session }
        );
    }
    // [New] Autonomous approval of DeliveryRequest for the assigned delivery user
    else if ((status === 'accepted' || status === 'completed')) {
        if (transaction.delivery) {
            // Approve the active request for this transaction/user
            await DeliveryRequest.updateMany(
                { transaction: transaction._id, delivery: transaction.delivery, status: 'pending' },
                { status: 'approved' },
                { session }
            );
        }
        if (status === 'completed') {
            await exports.settleTransaction(transaction, session);
        }
    }


    await transaction.save({ session });


    return transaction;
};

/**
 * Unassigns a delivery person from a transaction.
 * Resets delivery status and notifies the delivery user.
 * 
 * @param {string} transactionId - Transaction ID.
 * @param {Object} session - Mongoose session.
 * @param {Object} [req] - Request object for auditing.
 * @returns {Promise<Object>} The updated transaction.
 */
exports.unassignTransaction = async (transactionId, session, req = null) => {
    const transaction = await Transaction.findById(transactionId).session(session);
    if (!transaction) {
        throw { message: 'Transaction not found', code: 404 };
    }

    const oldDeliveryId = transaction.delivery;
    transaction.delivery = undefined;

    // [UPDATED] Only reject pending requests for the user being unassigned
    if (oldDeliveryId) {
        await DeliveryRequest.updateMany(
            { transaction: transaction._id, delivery: oldDeliveryId, status: 'pending' },
            { status: 'rejected' },
            { session }
        );
    }

    await transaction.save({ session });

    // Notify the unassigned user
    if (oldDeliveryId) {
        try {
            const { addNotificationJob } = require('../utils/queueManager');
            setImmediate(() => addNotificationJob(
                oldDeliveryId.toString(),
                'transaction',
                `You have been detached from Transaction #${transaction.serial || transaction._id.toString().slice(-6)}.`,
                {
                    relatedEntity: transaction._id,
                    relatedEntityType: 'Transaction'
                },
                `تم فصلك عن المعاملة #${transaction.serial || transaction._id.toString().slice(-6)}.`
            ));
        } catch (notifErr) {
            console.error('Notification error in unassignTransaction service:', notifErr);
        }
    }

    return transaction;
};

// =============================================================================
// FINANCIAL SETTLEMENT & REVERSAL
// =============================================================================

/**
 * Executes the financial settlement for a completed transaction.
 * Calculates commissions, bonuses, and hub-specific logic.
 * Updates pharmacy balances and records ledger entries.
 * 
 * @param {Object} transaction - The transaction document to settle.
 * @param {Object} session - Mongoose session.
 */
exports.settleTransaction = async (transaction, session) => {
    if (transaction.status === 'completed') {
        return; // Already settled
    }

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

            // --- Case A: Shortage Fulfillment (Admin Matching) ---
            if (excess.shortage_fulfillment) {
                // CASE 1: Shortage Fulfillment
                // If not provided at creation, use latest system settings
                if (transaction.sellerBonusRatio === undefined) {
                    transaction.sellerBonusRatio = settings.shortageSellerReward / 100;
                }
                if (transaction.buyerCommissionRatio === undefined) {
                    transaction.buyerCommissionRatio = settings.shortageCommission / 100;
                }

                let bonusRatio = transaction.sellerBonusRatio;
                let commRatio = transaction.buyerCommissionRatio;

                // --- Hub-Specific Overrides ---
                // If a Hub is the seller, they don't get a bonus since it's a system transfer.
                // If a Hub is the buyer, they don't pay commission to themselves.
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
                // --- Case B: Regular Transaction (Market Order or Direct Match) ---

                // 1. Validation: original sale percentage must match if it exists
                if (shortage.originalSalePercentage && shortage.originalSalePercentage !== excess.salePercentage) {
                    throw { message: `Data Mismatch: Original sale percentage for excess ${excess._id} is ${excess.salePercentage}%, but shortage expected ${shortage.originalSalePercentage}%. Please re-list or adjust stock.`, code: 409 };
                }

                // Commission is based on the excess sale value.
                // The baseline system commission is used as a floor during creation, but here
                // we use the actual percentage stored or agreed upon.
                let sellerCommissionRatio = (excess.salePercentage !== undefined && excess.salePercentage !== null)
                    ? (excess.salePercentage / 100)
                    : systemMinCommRatio;

                // 3. Calculate Sale Ratio (Buyer Receives)
                // The sale the buyer explicitly selected and agreed on (from shortage)
                let buyerSaleRatio = (shortage.salePercentage || 0) / 100;

                // Sub-case: Hub Seller Logic
                if (sellerPh.isHub && (excess.isHubGenerated || excess.isHubPurchase)) {
                    // Hub selling transferred or purchased items
                    // Use purchase price directly as positive effect
                    sellerEffect = excess.purchasePrice * source.quantity;

                    sellerDetails = {
                        type: excess.isHubPurchase ? 'hub_purchase_sale' : 'hub_transfer_sale',
                        baseAmount: source.totalAmount,
                        purchasePrice: excess.purchasePrice,
                        quantity: source.quantity,
                        sellingPrice: source.agreedPrice
                    };
                } else {
                    // Regular seller (not hub) - calculate commission normally.
                    // The profit is (1 - commissionRatio) * totalAmount.
                    sellerEffect = (1 - sellerCommissionRatio) * source.totalAmount;

                    sellerDetails = {
                        type: 'excess_rebalance',
                        baseAmount: source.totalAmount,
                        commissionRatio: sellerCommissionRatio,
                        originalSale: excess.salePercentage
                    };
                }

                // Sub-case: Hub Buyer Logic (Net Zero Effect)
                // If the buyer is a Hub, they are essentially taking stock in at the same "value" 
                // the seller received it at, ensuring no system "leakage" during transfers.
                if (buyerPh.isHub) {
                    buyerSaleRatio = (excess.salePercentage || 0) / 100;
                }

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
                product: excess.product,
                quantity: source.quantity,
                details: sellerDetails
            }], { session });

            // Websocket notification
            try {
                const sellerUsers = await User.find({ pharmacy: sellerPh._id }).session(session);
                for (const user of sellerUsers) {
                    sendToUser(user._id.toString(), 'balanceUpdate', { balance: sellerPh.balance });
                }
            } catch (err) { }

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
            product: shortage.product,
            quantity: transaction.stockShortage.quantityTaken,
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
        } catch (err) { }
    }

    // 3. Final stock sync
    const excessService = getExcessService();
    for (const source of transaction.stockExcessSources) {
        const excess = await StockExcess.findById(source.stockExcess).session(session);
        if (excess) {
            await excessService.syncExcessStatus(excess, session);
        }
    }

    transaction.status = 'completed';
    await transaction.save({ session });
};

// =============================================================================
// STAKEHOLDER NOTIFICATIONS
// =============================================================================

/**
 * Notifies all stakeholders (buyer, sellers, delivery) about a transaction status change.
 * Fires after DB commit via push notifications and WebSocket.
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
            setImmediate(() => addNotificationJob(
                user._id.toString(),
                'transaction',
                `Transaction for "${productName}" is now ${statusMsg}.`,
                {
                    relatedEntity: transaction._id,
                    relatedEntityType: 'Transaction'
                },
                `المعاملة الخاصة بـ "${productName}" أصبحت الآن ${statusMsgAr}.`
            ));
            sendToUser(user._id.toString(), 'transactionUpdate', { transactionId: transaction._id, status: transaction.status });
        }

        // -- Notify Sellers --
        for (const sellerPhId of uniqueSellerPhIds) {
            const sellerUsers = await User.find({ pharmacy: sellerPhId });
            for (const user of sellerUsers) {
                // If the buyer was a Hub, and we are notifying the seller, the message is generic enough "Your transaction..."
                // It doesn't explicitly say "Sold to Hub".
                // So default message is safe: "Your transaction for X is now Y"

                setImmediate(() => addNotificationJob(
                    user._id.toString(),
                    'transaction',
                    `Your transaction for "${productName}" is now ${statusMsg}.`,
                    {
                        relatedEntity: transaction._id,
                        relatedEntityType: 'Transaction'
                    },
                    `معاملتك الخاصة بـ "${productName}" أصبحت الآن ${statusMsgAr}.`
                ));
                sendToUser(user._id.toString(), 'transactionUpdate', { transactionId: transaction._id, status: transaction.status });
            }
        }

        // -- Notify Delivery (if assigned) --
        if (transaction.delivery) {
            setImmediate(() => addNotificationJob(
                transaction.delivery.toString(),
                'transaction',
                `${serialMsg} for "${productName}" has been ${statusMsg}.`,
                {
                    relatedEntity: transaction._id,
                    relatedEntityType: 'Transaction'
                },
                `${serialMsgAr} لـ "${productName}" أصبحت ${statusMsgAr}.`
            ));
            sendToUser(transaction.delivery.toString(), 'transactionUpdate', { transactionId: transaction._id, status: transaction.status });
        }

    } catch (error) {
        console.error('Error in notifyParties service:', error);
    }
};

/**
 * Reverts an "Add to Hub" transaction. 
 * Reverses Hub stock creation, restores original user stock, and reverses all financials.
 * 
 * @param {Object} transaction - Hub transfer transaction.
 * @param {Object} session - Mongoose session.
 * @param {Object} [req] - Request for auditing.
 */
exports.revertAddToHub = async (transaction, session, req) => {
    // 1. Fetch and Validate Hub Excess
    const hubExcess = await StockExcess.findById(transaction.added_to_hub.excessId).session(session);
    if (!hubExcess) throw { message: 'Hub excess record not found', code: 404 };

    if (hubExcess.remainingQuantity !== hubExcess.originalQuantity) {
        throw { message: 'Cannot revert: The transferred stock has already been used by the Hub.', code: 409 };
    }

    // 2. Cancel Hub Excess
    hubExcess.status = 'cancelled';
    let quantiyReverted = hubExcess.remainingQuantity; // Capture for restore
    hubExcess.remainingQuantity = 0; // Ensure it can't be used
    await hubExcess.save({ session });

    // Log the cancellation of the Hub Excess explicitly

    // 3. Cancel Hub Shortage (Do not restore it)
    const shortageService = getShortageService();
    const shortageId = transaction.stockShortage.shortage._id || transaction.stockShortage.shortage;

    // Restore shortage quantity first so it passes the "unused" check in cancelShortage
    const shortage = await StockShortage.findById(shortageId).session(session);
    if (shortage) {
        shortage.remainingQuantity += quantiyReverted;
        await shortageService.syncShortageStatus(shortage, session);
        await shortage.save({ session });
    }

    await shortageService.cancelShortage(shortageId, session, req);

    // 4. Restore Source Excesses (User's Stock)
    const excessService = getExcessService();
    for (const source of transaction.stockExcessSources) {
        // Handle populated or unpopulated stockExcess
        const excessId = source.stockExcess._id || source.stockExcess;
        const excess = await StockExcess.findById(excessId).session(session);
        if (excess) {
            excess.remainingQuantity += source.quantity;
            await excessService.syncExcessStatus(excess, session);
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
            product: shortageObj.product,
            quantity: transaction.stockShortage.quantityTaken,
            details: { type: 'reversal' }
        }], { session });

        // Notify
        try {
            const users = await User.find({ pharmacy: buyerPh._id }).session(session);
            for (const user of users) {
                sendToUser(user._id.toString(), 'balanceUpdate', { balance: buyerPh.balance });
            }
        } catch (e) { }
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
                    product: excess.product,
                    quantity: source.quantity,
                    details: { type: 'reversal' }
                }], { session });

                try {
                    const users = await User.find({ pharmacy: sellerPh._id }).session(session);
                    for (const user of users) {
                        sendToUser(user._id.toString(), 'balanceUpdate', { balance: sellerPh.balance });
                    }
                } catch (e) { }
            }
        }
    }

    // 6. Set Transaction Status
    transaction.status = 'cancelled';
    await transaction.save({ session });
    await auditService.logAction({
        user: req?.user?._id || transaction.stockShortage.shortage.pharmacy, // Fallback if req is missing
        action: 'REVERT_ADD_TO_HUB',
        entityType: 'Transaction',
        entityId: transaction._id,
    }, req);
    return transaction;
};

/**
 * Partially reverts an "Add to Hub" transaction.
 * Reduces Hub stock, restores original user stock, and reverses proportional financials.
 * 
 * @param {Object} transaction - Hub transfer transaction.
 * @param {number} revertQuantity - Quantity to take back from the Hub.
 * @param {Object} session - Mongoose session.
 * @param {Object} [req] - Request for auditing.
 */
exports.partialRevertAddToHub = async (transaction, revertQuantity, session, req) => {
    // 1. Validation
    if (revertQuantity <= 0) throw { message: 'Revert quantity must be positive', code: 400 };

    const hubExcess = await StockExcess.findById(transaction.added_to_hub.excessId).session(session);
    if (!hubExcess) throw { message: 'Hub excess record not found', code: 404 };

    if (hubExcess.remainingQuantity < revertQuantity) {
        throw { message: 'Cannot revert: Requested quantity exceeds Hub remaining stock.', code: 409 };
    }


    // 2. Adjust Hub Excess
    hubExcess.originalQuantity -= revertQuantity;
    hubExcess.remainingQuantity -= revertQuantity;

    const excessService = getExcessService();
    await excessService.syncExcessStatus(hubExcess, session);
    await hubExcess.save({ session });

    // 3. Adjust Hub Shortage
    const shortageService = getShortageService();
    const shortageId = transaction.stockShortage.shortage._id || transaction.stockShortage.shortage;
    const shortage = await StockShortage.findById(shortageId).session(session);
    if (shortage) {
        shortage.quantity -= revertQuantity;
        // fulfilledQuantity is implicitly adjusted as it's computed as total - remaining.
        await shortage.save({ session });
        await shortageService.syncShortageStatus(shortage, session);
    } else {
        throw { message: 'Cannot revert: Hub Shortage record not found.', code: 409 };
    }

    // 4. Restore Source Excesses and Adjust Financials Proportionally
    const source = transaction.stockExcessSources[0];
    if (!source) throw { message: 'Transaction source not found', code: 404 };

    const excessId = source.stockExcess._id || source.stockExcess;
    const excess = await StockExcess.findById(excessId).session(session);

    if (!excess) {
        throw { message: `Cannot revert: seller excess record ${excessId} not found.`, code: 409 };
    }

    // Restore quantity to original seller's excess
    excess.remainingQuantity += revertQuantity;
    await getExcessService().syncExcessStatus(excess, session);
    await excess.save({ session });

    // Calculate proportional amounts from the transaction itself (Source of Truth for historical values)
    const unitGrossPrice = source.totalAmount / source.quantity;
    const unitNetSettlement = Math.abs(source.balanceEffect) / source.quantity;

    const GrossRevertAmount = unitGrossPrice * revertQuantity;
    const NetRevertAmount = unitNetSettlement * revertQuantity;

    // Financial Reversal for Seller    
    const sellerPh = await Pharmacy.findById(excess.pharmacy).session(session);
    if (sellerPh) {
        const prevBalance = sellerPh.balance;
        sellerPh.balance -= NetRevertAmount;
        await sellerPh.save({ session });

        await BalanceHistory.create([{
            pharmacy: sellerPh._id,
            type: 'transaction_revenue',
            amount: -NetRevertAmount,
            previousBalance: prevBalance,
            newBalance: sellerPh.balance,
            relatedEntity: transaction._id,
            relatedEntityType: 'Transaction',
            description: `Partial reversal of revenue (${revertQuantity} units) for transaction #${transaction.serial}`,
            description_ar: `عكس جزئي للتحصيل (${revertQuantity} وحدة) للمعاملة #${transaction.serial}`,
            product: excess.product,
            quantity: revertQuantity,
            details: { type: 'partial_reversal', revertQuantity: revertQuantity }
        }], { session });

        try {
            const users = await User.find({ pharmacy: sellerPh._id }).session(session);
            for (const user of users) {
                sendToUser(user._id.toString(), 'balanceUpdate', { balance: sellerPh.balance });
            }
        } catch (e) { }
    } else {
        throw { message: 'Cannot revert: seller pharmacy record not found.', code: 409 };
    }

    // Adjust transaction metadata for this source
    source.quantity -= revertQuantity;
    source.balanceEffect -= NetRevertAmount;
    source.totalAmount -= GrossRevertAmount;


    // 5. Revert Buyer (Hub) Payment

    const buyerPh = await Pharmacy.findById(shortage.pharmacy).session(session);
    if (buyerPh) {
        const prevBalance = buyerPh.balance;
        buyerPh.balance += NetRevertAmount;
        await buyerPh.save({ session });

        await BalanceHistory.create([{
            pharmacy: buyerPh._id,
            type: 'transaction_payment',
            amount: NetRevertAmount,
            previousBalance: prevBalance,
            newBalance: buyerPh.balance,
            relatedEntity: transaction._id,
            relatedEntityType: 'Transaction',
            description: `Partial reversal of payment (${revertQuantity} units) for transaction #${transaction.serial}`,
            description_ar: `عكس جزئي للدفع (${revertQuantity} وحدة) للمعاملة #${transaction.serial}`,
            product: shortage.product,
            quantity: revertQuantity,
            details: { type: 'partial_reversal', revertQuantity }
        }], { session });

        try {
            const users = await User.find({ pharmacy: buyerPh._id }).session(session);
            for (const user of users) {
                sendToUser(user._id.toString(), 'balanceUpdate', { balance: buyerPh.balance });
            }
        } catch (e) { }
    } else {
        throw { message: 'Cannot revert: buyer pharmacy record not found.', code: 409 };
    }

    transaction.stockShortage.quantityTaken -= revertQuantity;
    transaction.stockShortage.balanceEffect += NetRevertAmount;

    // Update Transaction Totals
    transaction.totalQuantity -= revertQuantity;
    transaction.totalAmount -= GrossRevertAmount;

    if (transaction.totalQuantity === 0) {
        transaction.status = 'cancelled';
    }

    await auditService.logAction({
        user: req?.user?._id || transaction.stockShortage.shortage.pharmacy, // Fallback if req is missing
        action: 'PARTIAL_REVERT_ADD_TO_HUB',
        entityType: 'Transaction',
        entityId: transaction._id,
        changes: { revertQuantity }
    }, req);

    await transaction.save({ session });
    return transaction;
};
