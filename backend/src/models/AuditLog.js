const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    action: {
        type: String,
        enum: ['CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'CHANGE_PASSWORD', 'CANCEL', 'ADD_TO_HUB', 'REMOVE_FROM_HUB', 'APPROVE_EXCESS', 'REJECT_EXCESS', 'ADD_TO_STOCK', 'REMOVE_FROM_STOCK', 'ADD_TO_BALANCE', 'REMOVE_FROM_BALANCE', 'ADD_TO_CASH', 'REMOVE_FROM_CASH', 'APPROVE', 'REJECT', 'LINK_PHARMACY', 'SETTLE', 'REVERT', 'UNASSIGN', 'REVIEW', 'ADJUST', 'UPDATE_REQUEST', 'REVERT_ADD_TO_HUB', 'PARTIAL_REVERT_ADD_TO_HUB'],
        required: true
    },
    entityType: {
        type: String,
        required: true
    },
    entityId: {
        type: mongoose.Schema.Types.ObjectId
    },
    changes: {
        type: mongoose.Schema.Types.Mixed
    },
    ipAddress: {
        type: String,
        trim: true
    },
    userAgent: {
        type: String,
        trim: true
    }
}, {
    timestamps: true
});

// Indexes for efficient querying
auditLogSchema.index({ user: 1, createdAt: -1 });
auditLogSchema.index({ entityType: 1, entityId: 1, createdAt: -1 });
auditLogSchema.index({ action: 1, createdAt: -1 });

module.exports = mongoose.model('AuditLog', auditLogSchema);
