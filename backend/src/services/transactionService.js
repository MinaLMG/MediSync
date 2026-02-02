const mongoose = require('mongoose');
const { Transaction, StockShortage, StockExcess, Pharmacy, Settings, BalanceHistory, User } = require('../models');
const { sendToUser } = require('../utils/pusherManager');

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
                const bonusRatio = transaction.sellerBonusRatio !== undefined
                    ? transaction.sellerBonusRatio
                    : (settings.shortageSellerReward / 100);
                
                const commRatio = transaction.buyerCommissionRatio !== undefined
                    ? transaction.buyerCommissionRatio
                    : (settings.shortageCommission / 100);

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
                const excessComm = (excess.salePercentage !== undefined && excess.salePercentage !== null)
                    ? (excess.salePercentage / 100)
                    : systemMinCommRatio;

                const finalCommRatio = Math.max(systemMinCommRatio, excessComm);
                sellerEffect = (1 - finalCommRatio) * source.totalAmount;
                sellerDetails = {
                    type: 'excess_rebalance',
                    baseAmount: source.totalAmount,
                    commissionRatio: finalCommRatio,
                    systemMinRatio: systemMinCommRatio,
                    offeredRatio: excessComm
                };

                sourceBuyerEffect = -source.totalAmount;
                sourceBuyerDetails = {
                    type: 'excess_rebalance',
                    baseAmount: source.totalAmount,
                    commissionRatio: 0,
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
        const mongoose = require('mongoose');
        const Product = mongoose.model('Product');

        // 1. Fetch Stakeholders and Context
        const shortage = await StockShortage.findById(transaction.stockShortage.shortage).populate('product');
        if (!shortage) return;

        const buyerPhId = shortage.pharmacy;
        const productName = shortage.product?.name || 'medicine';
        
        // Find all unique sellers
        const uniqueSellerPhIds = [...new Set(transaction.stockExcessSources.map(s => {
            // Check if sellerPharmacy is already an object or just an ID
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
