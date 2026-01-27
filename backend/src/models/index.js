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
    AuditLog: require('./AuditLog'),
    Settings: require('./Settings'),
    ProductSuggestion: require('./ProductSuggestion'),
    AppSuggestion: require('./AppSuggestion'),
    DeliveryRequest: require('./DeliveryRequest'),
    ReversalTicket: require('./ReversalTicket'),
    BalanceHistory: require('./BalanceHistory')
};
