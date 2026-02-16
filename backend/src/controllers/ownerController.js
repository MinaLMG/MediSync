const ownerService = require('../services/ownerService');

exports.createOwner = async (req, res) => {
    try {
        const owner = await ownerService.createOwner(req.body, req.user.pharmacy);
        res.status(201).json({ success: true, data: owner });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

exports.updateOwner = async (req, res) => {
    try {
        const owner = await ownerService.updateOwner(req.params.id, req.body, req.user.pharmacy);
        res.status(200).json({ success: true, data: owner });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};

exports.getOwners = async (req, res) => {
    try {
        const owners = await ownerService.getOwnersByPharmacy(req.user.pharmacy);
        res.status(200).json({ success: true, data: owners });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
