const { Owner, Pharmacy } = require('../models');
const auditService = require('./auditService');

/**
 * Creates a new owner for a hub pharmacy.
 */
exports.createOwner = async (data, pharmacyId, session = null, req = null) => {
    const { name } = data;
    
    const pharmacy = await Pharmacy.findById(pharmacyId).session(session);
    if (!pharmacy || !pharmacy.isHub) {
        throw { message: 'Only hub pharmacies can have owners', code: 400 };
    }

    const owner = await Owner.create([{
        name,
        pharmacy: pharmacyId,
        balance: 0
    }], { session });

    // Link to pharmacy
    pharmacy.linkedOwners.push(owner[0]._id);
    await pharmacy.save({ session });

    if (req) {
        await auditService.logAction({
            user: req.user._id,
            action: 'CREATE',
            entityType: 'Owner',
            entityId: owner[0]._id,
            changes: { name }
        }, req);
    }

    return owner[0];
};

/**
 * Updates an owner's name.
 */
exports.updateOwner = async (ownerId, data, pharmacyId, session = null, req = null) => {
    const { name } = data;
    const owner = await Owner.findOne({ _id: ownerId, pharmacy: pharmacyId }).session(session);
    
    if (!owner) {
        throw { message: 'Owner not found for this pharmacy', code: 404 };
    }

    if (name && owner.name !== name) {
        const oldName = owner.name;
        owner.name = name;
        await owner.save({ session });

        if (req) {
            await auditService.logAction({
                user: req.user._id,
                action: 'UPDATE',
                entityType: 'Owner',
                entityId: owner._id,
                changes: { name, oldName }
            }, req);
        }
    }

    return owner;
};

/**
 * Gets all owners for a hub pharmacy.
 */
exports.getOwnersByPharmacy = async (pharmacyId) => {
    return await Owner.find({ pharmacy: pharmacyId }).sort({ name: 1 });
};
