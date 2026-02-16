const { Settings } = require('../models');

/**
 * Calculates the agreed commission and sale percentage from an original sale percentage.
 * Uses the "sale split" logic: comm = max(systemMinComm, ceil(sale / 3))
 * 
 * @param {number} originalSale - The original sale percentage
 * @returns {Promise<{commission: number, agreedSale: number}>}
 */
exports.calculateAgreedCommission = async (originalSale) => {
    const settings = await Settings.getSettings();
    const systemMinComm = settings.minimumCommission || 10;
    
    return calculateAgreedCommissionSync(originalSale, systemMinComm);
};

/**
 * Synchronous version that accepts systemMinComm as a parameter.
 * Use this when you already have the settings loaded.
 * 
 * @param {number} originalSale - The original sale percentage
 * @param {number} systemMinComm - The system minimum commission
 * @returns {{commission: number, agreedSale: number}}
 */
exports.calculateAgreedCommissionSync = (originalSale, systemMinComm = 10) => {
    const commission = Math.max(systemMinComm, Math.ceil(originalSale / 3));
    const agreedSale = Math.max(0, originalSale - commission);
    
    return {
        commission,
        agreedSale
    };
};
