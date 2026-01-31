const Joi = require('joi');

const createExcessSchema = Joi.object({
    product: Joi.string().hex().length(24).required(),
    volume: Joi.string().hex().length(24).required(),
    quantity: Joi.number().integer().min(1).required(),
    expiryDate: Joi.string().pattern(/^(0[1-9]|1[0-2])\/\d{2}$/).required().messages({
        'string.pattern.base': 'Expiry date must be in MM/YY format'
    }),
    selectedPrice: Joi.number().min(0).required(),
    salePercentage: Joi.number().min(0).max(100).optional(),
    shortage_fulfillment: Joi.boolean().optional()
});

const updateExcessSchema = Joi.object({
    quantity: Joi.number().integer().min(0).optional(),
    selectedPrice: Joi.number().min(0).optional(),
    salePercentage: Joi.number().min(0).max(100).optional(),
    shortage_fulfillment: Joi.boolean().optional(),
    // These are prohibited but we include them to handle validation messages if sent
    product: Joi.any().forbidden(),
    volume: Joi.any().forbidden(),
    expiryDate: Joi.any().forbidden()
});

const createShortageSchema = Joi.object({
    product: Joi.string().hex().length(24).required(),
    volume: Joi.string().hex().length(24).required(),
    quantity: Joi.number().integer().min(1).required(),
    notes: Joi.string().max(500).allow('').optional()
});

const createOrderSchema = Joi.object({
    items: Joi.array().items(
        Joi.object({
            product: Joi.string().hex().length(24).required(),
            volume: Joi.string().hex().length(24).required(),
            quantity: Joi.number().integer().min(1).required(),
            notes: Joi.string().max(500).allow('').optional()
        })
    ).min(1).required(),
    notes: Joi.string().max(1000).allow('').optional()
});

module.exports = {
    createExcessSchema,
    updateExcessSchema,
    createShortageSchema,
    createOrderSchema
};
