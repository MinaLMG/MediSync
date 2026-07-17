/**
 * Rounds a number to 2 decimal places (cent-level precision).
 * Prevents floating-point drift from repeated += / -= operations on balances.
 *
 * Use this for EVERY balance/cashBalance mutation:
 *   pharmacy.balance = round2(pharmacy.balance + effect);
 *
 * @param {number} value
 * @returns {number}
 */
const round2 = (value) => Math.round(value * 100) / 100;

module.exports = { round2 };
