// Central export file for all models
module.exports = {
    Pharmacy: require('./Pharmacy'),
    User: require('./User'),
    Volume: require('./Volume'),
    Product: require('./Product'),
    HasVolume: require('./HasVolume'),
    StockShortage: require('./StockShortage'),
    StockExcess: require('./StockExcess'),
    Transaction: require('./Transaction'),
    Notification: require('./Notification'),
    Review: require('./Review'),
    AuditLog: require('./AuditLog'),
    Settings: require('./Settings'),
    ProductSuggestion: require('./ProductSuggestion')
};
