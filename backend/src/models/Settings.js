const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema({
    minimumCommission: {
        type: Number,
        default: 10,
        min: 0.01,
        max: 20
    },
    shortageCommission: {
        type: Number,
        default: 2,
        min: 0
    }
}, {
    timestamps: true
});

// Since we only want one settings document
settingsSchema.statics.getSettings = async function() {
    let settings = await this.findOne();
    if (!settings) {
        settings = await this.create({});
    }
    return settings;
};

module.exports = mongoose.model('Settings', settingsSchema);
