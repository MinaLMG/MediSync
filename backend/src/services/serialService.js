const Counter = require('../models/Counter');

/**
 * Generates an atomic, unique incrementing sequence.
 * @param {string} id Unique identifier for the counter (e.g., 'transaction', 'order')
 * @param {Object} session Optional Mongoose session for atomicity
 * @returns {Promise<number>} The next sequence number
 */
exports.getNextSequence = async (id, session = null) => {
    const counter = await Counter.findOneAndUpdate(
        { id },
        { $inc: { seq: 1 } },
        { new: true, upsert: true, session }
    );
    return counter.seq;
};

/**
 * Generates a formatted serial number based on date and an atomic sequence.
 * Format: YYYYMMDD-XXXX (e.g., 20260131-0101)
 * @param {string} entityName Name of the entity (transaction, order)
 * @param {Object} session Optional Mongoose session for atomicity
 * @returns {Promise<string>} The formatted serial
 */
exports.generateDateSerial = async (entityName, session = null) => {
    const date = new Date();
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    const datePrefix = `${yyyy}${mm}${dd}`;

    // We use a date-specific counter ID to reset counts daily or keep them unique
    const counterId = `${entityName}_${datePrefix}`;
    const seq = await exports.getNextSequence(counterId, session);
    
    // Starting at 101 as per existing logic
    const finalSeq = 100 + seq;
    
    return `${datePrefix}-${String(finalSeq).padStart(4, '0')}`;
};

/**
 * Generates a formatted order serial.
 * Format: ORD-YYYYMMDD-XXXX
 * @param {Object} session Optional Mongoose session for atomicity
 * @returns {Promise<string>}
 */
exports.generateOrderSerial = async (session = null) => {
    const date = new Date();
    const datePrefix = `${date.getFullYear()}${String(date.getMonth() + 1).padStart(2, '0')}${String(date.getDate()).padStart(2, '0')}`;
    
    const counterId = `order_${datePrefix}`;
    const seq = await exports.getNextSequence(counterId, session);
    
    const finalSeq = 100 + seq;
    
    return `ORD-${datePrefix}-${String(finalSeq).padStart(4, '0')}`;
};
