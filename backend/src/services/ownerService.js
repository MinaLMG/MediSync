const { Owner, Pharmacy } = require('../models');

/**
 * Creates a new owner for a hub pharmacy.
 */
exports.createOwner = async (data, pharmacyId) => {
    const { name } = data;
    
    const pharmacy = await Pharmacy.findById(pharmacyId);
    if (!pharmacy || !pharmacy.isHub) {
        throw new Error('Only hub pharmacies can have owners');
    }

    const owner = await Owner.create({
        name,
        pharmacy: pharmacyId,
        balance: 0
    });

    // Link to pharmacy
    pharmacy.linkedOwners.push(owner._id);
    await pharmacy.save();

    return owner;
};

/**
 * Updates an owner's name.
 */
exports.updateOwner = async (ownerId, data, pharmacyId) => {
    const { name } = data;
    const owner = await Owner.findOne({ _id: ownerId, pharmacy: pharmacyId });
    
    if (!owner) {
        throw new Error('Owner not found for this pharmacy');
    }

    if (name) owner.name = name;
    await owner.save();

    return owner;
};

/**
 * Gets all owners for a hub pharmacy.
 */
exports.getOwnersByPharmacy = async (pharmacyId) => {
    return await Owner.find({ pharmacy: pharmacyId }).sort({ name: 1 });
};
