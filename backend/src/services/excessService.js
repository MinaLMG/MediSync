const { StockExcess, HasVolume, StockShortage, Settings, Product, Transaction, Pharmacy } = require('../models');
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
    } = userData;

    // Check product status
    const productObj = await Product.findById(product).session(session);
    if (!productObj || productObj.status !== 'active') {
        throw new Error('This product is currently inactive and cannot be added as an excess.');
    }

    // Check if a Shortage exists for this product (Constraint)
    const existingShortage = await StockShortage.findOne({
        pharmacy: pharmacyId,
        product,
        status: { $in: ['active', 'partially_fulfilled'] }
    }).session(session);

    if (existingShortage) { // Only check for regular user adds
        throw new Error('You cannot add an excess for this product because you already have an active shortage for it.');
    }
    const isShortageFulfillment = shortage_fulfillment === true;

    const settings = await Settings.getSettings();
    const systemMinComm = settings.minimumCommission;

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

    const excessData = {
        pharmacy: pharmacyId, 
        product,
        volume,
        originalQuantity: quantity,
        remainingQuantity: userData.remainingQuantity !== undefined ? userData.remainingQuantity : quantity,
        expiryDate,
        selectedPrice,
        salePercentage: finalSalePercentage,
         shortage_fulfillment: isShortageFulfillment,
        isNewPrice,
        status: 'pending' 
    };

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
    
    if (!excess) throw new Error('Excess not found');

    if (excess.isNewPrice) {
        const hasVol = await HasVolume.findOne({ product: excess.product, volume: excess.volume }).session(session);
        if (hasVol && !hasVol.prices.includes(excess.selectedPrice)) {
            hasVol.prices.push(excess.selectedPrice);
            hasVol.prices.sort((a, b) => a - b);
            await hasVol.save({ session });
        }
    }

    return excess;
};

/**
 * Updates an existing excess.
 */
exports.updateExcess = async (excessId, updateData, user, req = null) => {
    const { quantity, selectedPrice, salePercentage, shortage_fulfillment } = updateData;
    
    const excess = await StockExcess.findById(excessId);
    if (!excess) throw new Error('Excess not found');

    // Ownership Check
    if (user.role !== 'admin' && excess.pharmacy.toString() !== user.pharmacy.toString()) {
        throw new Error('Not authorized to update this excess');
    }

    if (['fulfilled', 'expired', 'rejected'].includes(excess.status)) {
        throw new Error(`Cannot update excess with status ${excess.status}. It is locked.`);
    }

    const taken = excess.originalQuantity - excess.remainingQuantity;

    // Validate quantity decrease
    if (quantity !== undefined) {
        if (quantity < taken) throw new Error(`Quantity cannot be less than taken (${taken}).`);
        excess.originalQuantity = quantity;
        excess.remainingQuantity = quantity - taken;
    }

    // Update sale info
    if (shortage_fulfillment !== undefined) excess.shortage_fulfillment = shortage_fulfillment;
    
    if (excess.shortage_fulfillment) {
        excess.salePercentage = 0;
        excess.saleAmount = 0;
    } else if (salePercentage !== undefined) {
        excess.salePercentage = salePercentage;
        excess.saleAmount = (selectedPrice || excess.selectedPrice) * salePercentage / 100;
    }

    if (selectedPrice !== undefined && excess.status === 'pending') {
        excess.selectedPrice = selectedPrice;
    }

    await exports.syncExcessStatus(excess);
    await excess.save();

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
    const query = Transaction.find({ 'stockExcessSources.stockExcess': excess._id });
    if (session) query.session(session);
    const transactions = await query;
    
    const hasActiveOrCompleted = transactions.some(t => ['pending', 'accepted', 'completed'].includes(t.status));
    
    // Don't change pending, rejected, or cancelled status
    if (['pending', 'rejected', 'cancelled'].includes(excess.status)) {
        return;
    }
    
    if (excess.remainingQuantity > 0) {
        // Has remaining quantity
        if (hasActiveOrCompleted) {
            // Some quantity has been taken
            excess.status = 'partially_fulfilled';
        } else {
            // No active transactions
            excess.status = 'available';
        }
    } else {
        // No remaining quantity (all taken)
        excess.status = 'fulfilled';
    }
};

/**
 * Moves excess quantity to a Hub pharmacy.
 */
exports.addToHub = async (excessId, hubId, quantity, req = null) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        const excess = await StockExcess.findById(excessId).session(session);
        if (!excess) throw new Error('Excess not found');
        if (excess.remainingQuantity < quantity) throw new Error('Requested quantity exceeds available');

        const hub = await Pharmacy.findById(hubId).session(session);
        if (!hub || !hub.isHub) throw new Error('Target pharmacy is not a valid Hub');

        // Check for self-dealing (Hub cannot add to itself)
        if (excess.pharmacy.toString() === hub._id.toString()) {
            throw new Error('Cannot add excess to the same hub account (Self-dealing detected).');
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
        await transactionService.updateTransactionStatus(transaction._id, 'accepted', session, req);
        await transactionService.updateTransactionStatus(transaction._id, 'completed', session, req);

        // 4. Create new excess at the hub (instantly available)
        const hubExcess = await exports.createExcess({
            product: excess.product,
            volume: excess.volume,
            quantity: quantity,
            remainingQuantity: quantity,
            expiryDate: excess.expiryDate,
            selectedPrice: excess.selectedPrice,
            salePercentage: excess.salePercentage,
            shortage_fulfillment: excess.shortage_fulfillment,
        }, hubId, req, session);

        // Approve excess (sets status to available and handles price updates)
        await exports.approveExcess(hubExcess._id, session);

        // Update hubExcess with isHubGenerated (since createExcess doesn't support it directly yet or we modify createExcess, but direct update is safer here)
        hubExcess.isHubGenerated = true;
        await hubExcess.save({ session });

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
