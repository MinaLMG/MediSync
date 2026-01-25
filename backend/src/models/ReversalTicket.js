const mongoose = require('mongoose');

const reversalTicketSchema = new mongoose.Schema({
    transaction: { 
        type: mongoose.Schema.Types.ObjectId, 
        ref: 'Transaction', 
        required: true 
    },
    punishments: [
        {
            user: { 
                type: mongoose.Schema.Types.ObjectId, 
                ref: 'User'
            },
            pharmacy: {
                type: mongoose.Schema.Types.ObjectId, 
                ref: 'Pharmacy'
            },
            amount: { 
                type: Number, 
                required: true 
            } // Positive value means taking from account
        }
    ],
    description: {
        type: String,
        trim: true
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('ReversalTicket', reversalTicketSchema);
