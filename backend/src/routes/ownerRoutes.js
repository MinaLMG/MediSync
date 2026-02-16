const express = require('express');
const router = express.Router();
const ownerController = require('../controllers/ownerController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.post('/', ownerController.createOwner);
router.put('/:id', ownerController.updateOwner);
router.get('/', ownerController.getOwners);

module.exports = router;
