const Joi = require('joi');

const registerSchema = Joi.object({
    name: Joi.string().required().trim(),
    phone: Joi.string().pattern(/^01\d{9}$/).required().messages({
        'string.pattern.base': 'Please provide a valid Egyptian phone number (11 digits starting with 01)'
    }),
    email: Joi.string().email().required().lowercase().trim(),
    password: Joi.string().min(6).required(),
    role: Joi.string().valid('admin', 'pharmacy_owner', 'pharmacy_staff', 'delivery'),
    pharmacyId: Joi.string().hex().length(24).optional()
});

const loginSchema = Joi.object({
    email: Joi.string().email().required().lowercase().trim(),
    password: Joi.string().required()
});

module.exports = {
    registerSchema,
    loginSchema
};
