const Joi = require('joi');

/**
 * Middleware to validate request data against a Joi schema.
 * @param {Object} schema Joi schema object
 * @param {string} source 'body' | 'query' | 'params'
 */
const validate = (schema, source = 'body') => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req[source], {
            abortEarly: false,
            stripUnknown: true,
            allowUnknown: false
        });

        if (error) {
            const errorMessage = error.details
                .map((detail) => detail.message.replace(/['"]/g, ''))
                .join(', ');
            
            return res.status(400).json({
                success: false,
                message: 'Validation Error',
                errors: errorMessage
            });
        }

        // Replace request data with validated/stripped values
        req[source] = value;
        next();
    };
};

module.exports = validate;
