const { AuditLog } = require('../models');

/**
 * Records an action in the audit log.
 * @param {Object} params
 * @param {string} params.user ID of the user performing the action
 * @param {string} params.action CREATE | UPDATE | DELETE | LOGIN | etc.
 * @param {string} params.entityType Model name
 * @param {string} params.entityId ID of the affected entity
 * @param {Object} [params.changes] Object containing the changes
 * @param {Object} [req] Express request object to capture IP and User Agent
 */
exports.logAction = async ({ user, action, entityType, entityId, changes }, req = null) => {
    try {
        await AuditLog.create({
            user,
            action,
            entityType,
            entityId,
            changes,
            ipAddress: req ? req.ip : 'system',
            userAgent: req ? req.headers['user-agent'] : 'system'
        });
    } catch (error) {
        console.error('Audit Log Error:', error);

        // We don't throw here to avoid failing the main business action
    }
};
