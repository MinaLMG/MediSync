const { StockExcess, HasVolume, StockShortage, Settings, Product, Transaction, Pharmacy, SalesInvoice, User } = require('../models');
const auditService = require('./auditService');
const serialService = require('./serialService');
const mongoose = require('mongoose');

/**
 * Creates a new stock excess.
 */
exports.createExcess = async (userData, pharmacyId, req = null, session = null) => {
    const { 
        product, 
        volume, 
        quantity, 
        expiryDate, 
        selectedPrice, 
        salePercentage, 
        shortage_fulfillment,
        isHubGenerated,
        isHubPurchase,
        purchasePrice,
    } = userData;

    // Check product status
    const productObj = await Product.findById(product).session(session);
    if (!productObj || productObj.status !== 'active') {
        throw { message: 'This product is currently inactive and cannot be added as an excess.', code: 400 };
    }

    // Check if a Shortage exists for this product (Constraint)
    const existingShortage = await StockShortage.findOne({
        pharmacy: pharmacyId,
        product,
        status: { $in: ['active', 'partially_fulfilled'] }
    }).session(session);

    if (existingShortage) { // Only check for regular user adds
        const pharmacy = await Pharmacy.findById(pharmacyId).session(session);   
        if (!pharmacy ||!pharmacy.isHub) {
            throw { message: 'You cannot add an excess for this product because you already have an active shortage for it.', code: 409 };
        }
    }
    const isShortageFulfillment = shortage_fulfillment === true;

    const settings = await Settings.getSettings();
    const systemMinComm = settings.minimumCommission;

    let finalSalePercentage;
    if (!isShortageFulfillment) {
        // If regular excess, unsure salePercentage defaults to system min (10%) if not provided
        // or if provided as 0, it means 0 user discount, but we still take 10% commission?
        // User said: "If the sale is less than 30%, we still take our minimum commission of 10%".
        // "If the sale is 10%, the user sees no sale." -> Means totalSale=10, Commission=10, UserSale=0.
        // So `salePercentage` stored in DB should be the TOTAL cut (System + User).
        // If user enters 0, we effectively take 10%.
        // But if user enters 0, is it "0 sale to end user" or "0 cut"? 
        // "note for the sale that notified the users that the mininmum commision sale % is x"
        // So the input `salePercentage` IS the total sale.
        // If not provided, we should default it to `systemMinComm` (e.g. 10).
        if (salePercentage === undefined || salePercentage === null) {
              finalSalePercentage = systemMinComm;
        } else {
             // Ensure it's at least min comm?
             // "If the sale is 10%, the user sees no sale." -> Implies we accept 10%.
             // What if they enter 5%? Then we take 5%? Or 10%?
             // "we still take our minimum commission of 10%".
             // So if they enter 5%, we must take 10%. 
             // We should probably force it to be at least systemMinComm.
             finalSalePercentage = Math.max(salePercentage, systemMinComm);
        }
    } else {
        // Shortage: we use provided or 0? 
        // Usually shortage has its own logic (buyer pays commission). 
        // We'll leave it as is or default to 0 if null.
        finalSalePercentage = 0; 
    }



    // Check if Selected Price is New
    const hasVolume = await HasVolume.findOne({ product, volume }).session(session);
    let isNewPrice = false;
    if (hasVolume && !hasVolume.prices.includes(selectedPrice)) {
        isNewPrice = true;
    }

    // Use flags exactly as provided by caller (no auto-detection)
    const finalIsHubGenerated = isHubGenerated || false;
    const finalIsHubPurchase = isHubPurchase || false;

    // Calculate purchase price based on which flag is set
    let finalPurchasePrice = purchasePrice;

    if (finalIsHubGenerated && !finalPurchasePrice) {
        // Add to Hub: Cost = Price * (1 - Sale%)
        const saleRatio = finalSalePercentage ? (finalSalePercentage / 100) : 0;
        finalPurchasePrice = selectedPrice * (1.0 - saleRatio);
    } else if (finalIsHubPurchase && !finalPurchasePrice) {
        // Purchase Invoice: Must provide explicit purchase price
        throw { message: 'Purchase price is required for hub purchase invoices', code: 400 };
    }

    const excessData = {
        pharmacy: pharmacyId, 
        product,
        volume,
        originalQuantity: quantity,
        remainingQuantity: quantity,
        expiryDate,
        selectedPrice,
        salePercentage: finalSalePercentage,
         shortage_fulfillment: isShortageFulfillment,
        isNewPrice,
        status: 'pending' 
    };
    if(isHubPurchase){  
        excessData.isHubPurchase = true;
    }
    if(isHubGenerated){ 
        excessData.isHubGenerated = true;
    }
    if (finalPurchasePrice) {
        excessData.purchasePrice = finalPurchasePrice;
    }  

    const excess = session
        ? (await StockExcess.create([excessData], { session }))[0]
        : await StockExcess.create(excessData);

    await auditService.logAction({
        user: req?.user?._id,
        action: 'CREATE',
        entityType: 'StockExcess',
        entityId: excess._id,
        changes: excess.toObject()
    }, req);

    return excess;
};

/**
 * Approves an excess, setting its status to 'available'.
 * Handles pricing updates in HasVolume.
 */
exports.approveExcess = async (excessId, session = null) => {
    const excess = await StockExcess.findByIdAndUpdate(
        excessId, 
        { status: 'available' }, 
        { new: true, session }
    );
    if (!excess) throw { message: 'Excess not found', code: 404 };

    if (excess.isNewPrice) {
        const hasVol = await HasVolume.findOne({ product: excess.product, volume: excess.volume }).session(session);
        if (hasVol && !hasVol.prices.includes(excess.selectedPrice)) {
            hasVol.prices.push(excess.selectedPrice);
            hasVol.prices.sort((a, b) => a - b);
            await hasVol.save({ session });
        }
    }

    // Notify User
    try {
        const { addNotificationJob } = require('../utils/queueManager');
        const product = await Product.findById(excess.product).session(session);
        const productName = product ? product.name : 'Unknown Product';
        const owner = await User.findOne({ pharmacy: excess.pharmacy }).session(session);
        if (owner) {
            setImmediate(() => addNotificationJob(
                owner._id.toString(),
                'system',
                `Your stock excess listing for "${productName}" has been approved.`,
                {
                    relatedEntity: excess._id,
                    relatedEntityType: 'StockExcess'
                },
                `تم الموافقة على قائمة العرض الخاصة بك لـ "${productName}".`
            ));
        }
    } catch (err) {
        console.error('Error in approveExcess notification:', err);
    }

    return excess;
};

/**
 * Updates an existing excess.
 */
exports.updateExcess = async (excessId, updateData, user, req = null, session = null) => {
    const { quantity, selectedPrice, salePercentage, shortage_fulfillment } = updateData;
    
    const excess = await StockExcess.findById(excessId).session(session);
    if (!excess) throw { message: 'Excess not found', code: 404 };

    // Ownership Check
    if (user.role !== 'admin' && excess.pharmacy.toString() !== user.pharmacy.toString()) {
        throw { message: 'Not authorized to update this excess', code: 403 };
    }

    if (['fulfilled', 'expired', 'rejected'].includes(excess.status)) {
        throw { message: `Cannot update excess with status ${excess.status}. It is locked.`, code: 409 };
    }

    const taken = excess.originalQuantity - excess.remainingQuantity;
    const hasBeenSold = taken > 0;

    // Validate quantity decrease only
    if (quantity !== undefined && quantity !== excess.originalQuantity) {
        if (excess.isHubGenerated || excess.isHubPurchase) {
            throw { message: 'Quantity for hub stock cannot be updated manually. Please update via the source document.', code: 409 };
        }
        if (quantity > excess.originalQuantity) {
             throw { message: 'Excesses can only be decreased in quantity, not increased.', code: 400 };
        }
        if (quantity < taken) throw { message: `Quantity cannot be less than taken (${taken}).`, code: 400 };
        excess.originalQuantity = quantity;
        excess.remainingQuantity = quantity - taken;
    }

    // Enforce restrictions based on sold quantity
    if (hasBeenSold) {
        // Stock has been sold/committed - cannot change terms
        if (selectedPrice !== undefined && selectedPrice !== excess.selectedPrice) {
            throw { message: 'Cannot change price for excess with committed stock.', code: 409 };
        }
        if (salePercentage !== undefined && salePercentage !== excess.salePercentage) {
            throw { message: 'Cannot change sale percentage for excess with committed stock.', code: 409 };
        }
        if (shortage_fulfillment !== undefined && shortage_fulfillment !== excess.shortage_fulfillment) {
            throw { message: 'Cannot change fulfillment type for excess with committed stock.', code: 409 };
        }
        if (updateData.expiryDate !== undefined && updateData.expiryDate !== excess.expiryDate) {
            throw { message: 'Cannot change expiry date for excess with committed stock.', code: 409 };
        }
    }  else {
        // No stock sold yet - allow updates
        let needsReapproval = false;

        // 1. Shortage Fulfillment Change
        if (shortage_fulfillment !== undefined && shortage_fulfillment !== excess.shortage_fulfillment) {
            excess.shortage_fulfillment = shortage_fulfillment;
            needsReapproval = true;
        }

        // 2. Sale Percentage Change
        if (!excess.shortage_fulfillment) {
            if (salePercentage !== undefined && salePercentage !== excess.salePercentage) {
                const settings = await Settings.getSettings();
                excess.salePercentage = Math.max(salePercentage, settings.minimumCommission);
                needsReapproval = true;
            }
        } else {
            excess.salePercentage = 0;
            excess.saleAmount = 0;
        }

        // 3. Price Change
        if (selectedPrice !== undefined && selectedPrice !== excess.selectedPrice) {
            if (excess.isHubGenerated || excess.isHubPurchase) {
                throw { message: 'Price for hub stock cannot be updated manually. Please update via the source document.', code: 409 };
            }
            excess.selectedPrice = selectedPrice;
            needsReapproval = true;
           // Re-calculate isNewPrice for the price list logic
            const { HasVolume } = require('../models');
            const hasVolume = await HasVolume.findOne({ product: excess.product, volume: excess.volume }).session(session);
            excess.isNewPrice = hasVolume && !hasVolume.prices.includes(selectedPrice);
        }

        // 4. Expiry Date Change
        if (updateData.expiryDate !== undefined && updateData.expiryDate !== excess.expiryDate) {
            if (excess.isHubGenerated || excess.isHubPurchase) {
                throw { message: 'Expiry date for hub stock cannot be updated manually. Please update via the source document.', code: 409 };
            }
            // Basic format validation
            if (!/^(0[1-9]|1[0-2])\/\d{2}$/.test(updateData.expiryDate)) {
                throw { message: 'Expiry date must be in MM/YY format', code: 400 };
            }
            excess.expiryDate = updateData.expiryDate;
            needsReapproval = true;
        }

        // Centralized Sale Amount Calculation
        excess.saleAmount = (excess.selectedPrice * (excess.salePercentage || 0)) / 100;

        // If something critical changed, put back to pending
        if (needsReapproval) {
            excess.status = 'pending';
        }
    }

    await exports.syncExcessStatus(excess, session);
    await excess.save({ session });

    await auditService.logAction({
        user: user._id,
        action: 'UPDATE',
        entityType: 'StockExcess',
        entityId: excess._id,
        changes: updateData
    }, req);

    return excess;
};

exports.syncExcessStatus = async (excess, session = null) => {
    // Don't change pending, rejected, or cancelled status
    if (['pending', 'rejected', 'cancelled'].includes(excess.status)) {
        return;
    }
    if(excess.remainingQuantity==0){
        // No remaining quantity (all taken)
        excess.status = 'fulfilled';
    }
    else if (excess.remainingQuantity == excess.originalQuantity ) {
        excess.status = 'available';
    } else {
        excess.status = 'partially_fulfilled';
    }
    if  (session)   
    await excess.save({ session });
};

/**
 * Moves excess quantity to a Hub pharmacy.
 */
exports.addToHub = async (excessId, hubId, quantity, req = null) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const excess = await StockExcess.findById(excessId).session(session);
        if (!excess) throw { message: 'Excess not found', code: 404 };
        if (excess.remainingQuantity < quantity) throw { message: 'Requested quantity exceeds available', code: 409 };

        const hub = await Pharmacy.findById(hubId).session(session);
        if (!hub || !hub.isHub) throw { message: 'Target pharmacy is not a valid Hub', code: 400 };

        // Check for self-dealing (Hub cannot add to itself)
        if (excess.pharmacy.toString() === hub._id.toString()) {
            throw { message: 'Cannot add excess to the same hub account (Self-dealing detected).', code: 409 };
        }

        // Services imported here to avoid circular dependency
        const shortageService = require('./shortageService');
        const transactionService = require('./transactionService');

        // 1. Create a shortage at the hub
        const shortage = await shortageService.createShortage(
            {
                product: excess.product,
                volume: excess.volume,
                quantity: quantity,
                isSystemGenerated: true // Mark as system generated
            },
            hubId,
            req,
            session
        );

        // 2. Create the transaction (Hub as buyer)
        const transaction = await transactionService.createTransaction({
            shortageId: shortage._id,
            quantityTaken: quantity,
            excessSources: [{ stockExcessId: excess._id, quantity: quantity }],
        }, session, req);
        
        // 3. Complete the transaction (Accepted -> Completed)
        await transactionService.updateTransactionStatus(transaction._id, 'accepted', req, session);
        await transactionService.updateTransactionStatus(transaction._id, 'completed', req, session);

        // 4. Create new excess at the hub (instantly available)
        const purchasePrice = (1 - (excess.salePercentage / 100)) * excess.selectedPrice;

        const hubExcess = await exports.createExcess({
            product: excess.product,
            volume: excess.volume,
            quantity: quantity,
            expiryDate: excess.expiryDate,
            selectedPrice: excess.selectedPrice,
            salePercentage: excess.salePercentage,
            shortage_fulfillment: excess.shortage_fulfillment,
            isHubGenerated: true,  // Transfer from pharmacy to hub
            isHubPurchase: false,   // NOT a direct purchase from supplier
            purchasePrice: purchasePrice,
        }, hubId, req, session);
        //approve the excess
        await exports.approveExcess(hubExcess._id, session);
        
        // Update transaction with added_to_hub reference
        transaction.added_to_hub = { excessId: hubExcess._id };
        await transaction.save({ session });

        await session.commitTransaction();

        // 5. Notify parties (after commit)
        await transactionService.notifyParties(transaction);

        await auditService.logAction({
            user: req?.user?._id,
            action: 'ADD_TO_HUB',
            entityType: 'StockExcess',
            entityId: excessId,
            changes: { hubId, quantity, newExcessId: hubExcess._id }
        }, req);

        return { success: true, transaction, hubExcess };
    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('❌ [Excess Service] addToHub failed:', error);

        throw error;
    } finally {
        session.endSession();
    }
};

/**
 * Propagates buying price update to all related sales invoices.
 */
exports.propagateBuyingPriceUpdate = async (excessId, newBuyingPrice, session = null) => {
    // Find all sales invoices that contain this excess
    const invoices = await SalesInvoice.find({ 'items.excess': excessId }).session(session);
    
    for (const invoice of invoices) {
        let totalBuying = 0;
        let totalSelling = 0;
        
        for (const item of invoice.items) {
            if (item.excess.toString() === excessId.toString()) {
                item.buyingPrice = newBuyingPrice;
            }
            totalBuying += (item.buyingPrice * item.quantity);
            totalSelling += (item.sellingPrice * item.quantity);
        }
        
        invoice.totalBuyingPrice = totalBuying;
        invoice.totalSellingPrice = totalSelling;
        invoice.totalRevenuePrice = totalSelling - totalBuying;
        
        await invoice.save({ session });
    }
};
