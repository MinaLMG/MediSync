const Joi = require('joi');

const createProductSchema = Joi.object({
    name: Joi.string().required().trim(),
    description: Joi.string().allow('').optional().trim(),
    conversions: Joi.array().items(
        Joi.object({
            from: Joi.string().required(),
            to: Joi.string().required(),
            value: Joi.number().min(1).required()
        })
    ).optional()
});

const suggestProductSchema = Joi.object({
    name: Joi.string().required().trim(),
    description: Joi.string().allow('').optional().trim(),
    manufacturer: Joi.string().optional().trim(),
    category: Joi.string().optional().trim()
});

module.exports = {
    createProductSchema,
    suggestProductSchema
};
