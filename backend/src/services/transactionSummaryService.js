const { Transaction, StockExcess, SalesInvoice, StockShortage, ReversalTicket, Compensation } = require('../models');
const mongoose = require('mongoose');

/**
 * Calculates total system revenue for the admin.
 */
exports.getTransactionsSummary = async (query) => {
    const { startDate, endDate } = query;
    console.log("start date",startDate)
    console.log("end date",endDate)
    const dateFilter = {};
    if (startDate || endDate) {
        dateFilter.createdAt = {};
        if (startDate) dateFilter.createdAt.$gte = new Date(startDate);
        if (endDate) dateFilter.createdAt.$lte = new Date(endDate);
    }
    console.log("datefilter",dateFilter)
    
    // 1. Transaction Revenue (Simplified)
    const transactions = await Transaction.find({
        ...dateFilter,
        status: 'completed'
    }).populate({
        path: 'stockShortage.shortage',
        select: 'product',
        populate: {
            path: 'product',
            select: 'name'
        }
    });
    
    let totalTransactionRevenue = 0;
    const transactionEntries = [];
    
    for (const tx of transactions) {
        const buyerEffect = tx.stockShortage.balanceEffect || 0;
        const sellersEffect = tx.stockExcessSources.reduce((sum, s) => sum + (s.balanceEffect || 0), 0);
        const netEffect = buyerEffect + sellersEffect;
        const revenue = -netEffect;
        
        totalTransactionRevenue += revenue;
        
        // Collect entry details
        transactionEntries.push({
            _id: tx._id,
            productName: tx.stockShortage?.shortage?.product?.name || 'Unknown Product',
            buyerEffect,
            sellersEffect,
            revenue,
            createdAt: tx.createdAt
        });
    }
    
    // 2. Hub Sales Invoice Impact (Profit only, not revenue)
    const salesDateFilter = {};
    if (startDate || endDate) {
        salesDateFilter.date = {};
        if (startDate) salesDateFilter.date.$gte = new Date(startDate);
        if (endDate) salesDateFilter.date.$lte = new Date(endDate);
    }
    
    const salesInvoices = await SalesInvoice.find(salesDateFilter);
    let totalSalesInvoiceProfit = 0;
    const salesInvoiceEntries = [];
    
    for (const inv of salesInvoices) {
        const profit = inv.totalRevenuePrice || 0;
        totalSalesInvoiceProfit += profit;
        
        salesInvoiceEntries.push({
            _id: inv._id,
            totalSellingPrice: inv.totalSellingPrice,
            totalBuyingPrice: inv.totalBuyingPrice,
            totalRevenuePrice: profit,
            date: inv.date
        });
    }

    // 3. Reversal Ticket Expenses (Punishments)
    const reversalDateFilter = {};
    if (startDate || endDate) {
        reversalDateFilter.createdAt = {};
        if (startDate) reversalDateFilter.createdAt.$gte = new Date(startDate);
        if (endDate) reversalDateFilter.createdAt.$lte = new Date(endDate);
    }
    
    const reversalTickets = await ReversalTicket.find(reversalDateFilter);
    let totalPunishmentRevenue = 0;
    const reversalEntries = [];
    
    for (const ticket of reversalTickets) {
        const totalExpenses = (ticket.expenses || []).reduce((sum, exp) => sum + (exp.amount || 0), 0);
        totalPunishmentRevenue += totalExpenses;
        
        reversalEntries.push({
            _id: ticket._id,
            totalExpenses,
            createdAt: ticket.createdAt
        });
    }
    
    // 4. Compensations (Losses)
    const compensationDateFilter = {};
    if (startDate || endDate) {
        compensationDateFilter.createdAt = {};
        if (startDate) compensationDateFilter.createdAt.$gte = new Date(startDate);
        if (endDate) compensationDateFilter.createdAt.$lte = new Date(endDate);
    }
    
    const compensations = await Compensation.find(compensationDateFilter);
    let totalCompensationLoss = 0;
    const compensationEntries = [];
    
    for (const comp of compensations) {
        const amount = comp.amount || 0;
        totalCompensationLoss += amount;
        
        compensationEntries.push({
            _id: comp._id,
            amount,
            createdAt: comp.createdAt
        });
    }
    
    const totalRevenue = totalTransactionRevenue + totalSalesInvoiceProfit + totalPunishmentRevenue - totalCompensationLoss;
    
    return {
        totalRevenue,
        breakdown: {
            transactionRevenue: totalTransactionRevenue,
            salesInvoiceProfit: totalSalesInvoiceProfit,
            punishmentRevenue: totalPunishmentRevenue,
            compensationLoss: totalCompensationLoss
        },
        entries: {
            transactions: transactionEntries,
            salesInvoices: salesInvoiceEntries,
            reversalTickets: reversalEntries,
            compensations: compensationEntries
        }
    };
};
