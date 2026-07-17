# MediSync Backend: Business Logic Audit & Qualitative Evaluation Report

This document reports the qualitative business logic, routing structures, service layouts, and potential ledger defects across the **MediSync** API backend.

---

## Executive Summary & System Vulnerabilities

MediSync uses a Node.js Express architecture linked to MongoDB (via Mongoose) to manage trading of excess pharmacy stock, shortage fulfillments, and hub distribution center transactions. 

During our deep code audit, we identified several critical business logic and ledger inconsistencies:

### 1. Hub Ledger Discrepancies (CRITICAL)
* **Compensation Balance Leak (Resolved)**: Previously, creating a compensation adjusted both the regular trade balance and the `cashBalance` for Hubs, whereas update/delete actions only reverted the regular trade balance (causing discrepancy). This was resolved by stripping `cashBalance` updates entirely from the compensation lifecycle across all stages (`createCompensation`, `updateCompensation`, and `deleteCompensation`), as compensations represent bookkeeping adjustments and not physical cash flows.
* **Hub Cash Bleed during Online matches**: Wholesale purchases (`PurchaseInvoice`) deduct costs from both regular `balance` and `cashBalance`. If the Hub sells this inventory online via platform-managed matches, `settleSellers` only credits the Hub's regular `balance` (cost recovery), leaving `cashBalance` permanently depleted. Cash is only credited during manual offline `SalesInvoice` entries.

### 2. Floating-Point Calculation Errors
* All balances are adjusted using basic floating-point operators (`+=`, `-=`). Mongoose models store these as standard Doubles. Because the ledger does not apply strict rounding (`Math.round` to cents or whole numbers), recurring additions/subtractions will accumulate precision drift errors (e.g. `5412.300000000002`), threatening overall ledger integrity.

### 3. Puppeteer Integration Fragility
* Synchronization with iSupply relies on headless Puppeteer scraping. Any alteration in Livewire classes, CSS selectors, or Select2 selectors on the iSupply portal will instantly break automated login and price queries, making manual overrides a frequent necessity.

---

## Routing & Controllers Inventory

### Controller: [adminController.js](file:///d:/MediSync/backend/src/controllers/adminController.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Business Role**: Administrative control room. Approves new pharmacies, suspends accounts, resets passwords, handles manual matches/overrides for iSupply, and reviews profile mutations.
* **Potential Bugs / Edge Cases**: If an admin resets a password, the user's active login sessions (JWTs) are not revoked immediately, allowing old tokens to remain active until expiry. Also, reviewUser executes without safety validations on Pharmacy details.
* **Possible Breaking Scenarios**: If an Admin reviews a user profile update that has malformed JSON data, it can save invalid fields to MongoDB, breaking serialization for Dart frontend clients.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.use(admin);`
* `router.get('/waiting-users', getLimiter, getWaitingUsers);`
* `router.get('/active-users', getLimiter, getActiveUsers);`
* `router.put('/review-user/:id', strictLimiter, reviewUser);`
* `router.get('/pharmacies', getLimiter, getAllPharmacies);`
* `router.get('/pending-counts', getLimiter, getPendingCounts);`
* `router.post('/create-delivery', strictLimiter, createDeliveryUser);`
* `router.put('/suspend-user/:id', strictLimiter, suspendUser);`
* `router.put('/reset-password/:id', sensitiveLimiter, resetUserPassword);`
* `router.get('/pending-updates', getLimiter, getUsersWithPendingUpdates);`
* `router.put('/review-update/:id', strictLimiter, reviewUpdateData);`
* `router.get('/pharmacies/:id', getLimiter, getPharmacyDetail);`
* `router.get('/hubs', getLimiter, getHubs);`
* `router.get('/pharmacies/:pharmacyId/orders', getLimiter, getPharmacyOrders);`
* `router.get('/pharmacies/:pharmacyId/balance-history', getLimiter, getPharmacyBalanceHistory);`
* `router.get('/pharmacies-summary', getLimiter, getPharmaciesSummary);`
* `router.get('/isupply/random-unmatched', getRandomUnmatchedProduct);`
* `router.patch('/isupply/match', matchProduct);`
* `router.post('/isupply/reject-choice', rejectChoice);`

---

### Controller: [authController.js](file:///d:/MediSync/backend/src/controllers/authController.js)
* **Status**: `Active`
* **Utility Rating**: `8.5/10`
* **Business Role**: User authentication, profile retrieval, registration, and linkPharmacy workflow (file uploads, user roles).
* **Potential Bugs / Edge Cases**: Brute-force security is delegated entirely to Express rate limiter middleware. No account locking logic is present in the DB layer after N failed attempts. linkPharmacy links to Cloudinary which can fail silently.
* **Possible Breaking Scenarios**: Cloudinary upload timeout during pharmacy verification documents upload will crash the registration flow if network cuts.

#### Mapped Endpoints:
* `router.post('/register', strictLimiter, register);`
* `router.post('/login', strictLimiter, login);`
* `router.post('/social-login', strictLimiter, socialLogin);`
* `router.get('/profile', protect, getProfile);`
* `router.put('/profile-update-request', protect, requestProfileUpdate);`
* `router.put('/preferences', protect, updatePreferences);`
* `router.put('/change-password', protect, strictLimiter, changePassword);`
* `router.post('/link-pharmacy', protect, upload.fields([`

---

### Controller: [balanceHistoryController.js](file:///d:/MediSync/backend/src/controllers/balanceHistoryController.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Business Role**: Exposes ledger sheets and transactional records of balance changes to standard pharmacies and admins.
* **Potential Bugs / Edge Cases**: Reads history sequentially. Lack of cursor-based pagination could lead to memory blowout on accounts with thousands of history records.
* **Possible Breaking Scenarios**: If MongoDB aggregate times out due to unindexed queries on related entities.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.get('/my', getMyBalanceHistory);`
* `router.get('/:pharmacyId', admin, getPharmacyBalanceHistory);`

---

### Controller: [compensationController.js](file:///d:/MediSync/backend/src/controllers/compensationController.js)
* **Status**: `Active - Patched & Decoupled from cashBalance`
* **Utility Rating**: `8.5/10`
* **Business Role**: Allows admins to grant compensatory coins to pharmacies for order delays or network issues. Updates standard `balance` with cent-level rounding precision.
* **Potential Bugs / Edge Cases**: None. The previously observed ledger drift bug was fixed by stripping all `cashBalance` logic from this controller, enforcing the rule that compensations only change bookkeeping trade balances.
* **Possible Breaking Scenarios**: A deleted compensation leaves an orphaned relatedEntity ID reference in the BalanceHistory collection (retained for audit transparency).

#### Mapped Endpoints:
* `router.use(protect);`
* `router.use(admin);`
* `router.post('/', strictLimiter, createCompensation);`
* `router.get('/:pharmacyId', getCompensations);`
* `router.put('/:id', strictLimiter, updateCompensation);`
* `router.delete('/:id', strictLimiter, deleteCompensation);`

---

### Controller: [deliveryRequestController.js](file:///d:/MediSync/backend/src/controllers/deliveryRequestController.js)
* **Status**: `Active`
* **Utility Rating**: `8/10`
* **Business Role**: Manages requests by delivery users to accept or complete order dispatches, subject to admin approval.
* **Potential Bugs / Edge Cases**: If a transaction is directly cancelled/modified by an admin while a delivery user has a pending request, the status state-machine will throw an unhandled error inside updateTransactionStatus status checks.
* **Possible Breaking Scenarios**: Delivery requests are deleted after 1 month. If an audit is performed on orders older than 1 month, delivery histories are lost.

#### Mapped Endpoints:
* `router.post('/', protect, authorize('delivery'), strictLimiter, deliveryRequestController.createRequest);`
* `router.get('/my-requests', protect, authorize('delivery'), getLimiter, deliveryRequestController.getMyRequests);`
* `router.get('/pending', protect, admin, getLimiter, deliveryRequestController.getPendingRequests);`
* `router.put('/:id/review', protect, admin, strictLimiter, deliveryRequestController.reviewRequest);`
* `router.delete('/cleanup', protect, admin, strictLimiter, deliveryRequestController.cleanupRequests);`

---

### Controller: [excessController.js](file:///d:/MediSync/backend/src/controllers/excessController.js)
* **Status**: `Active`
* **Utility Rating**: `8.5/10`
* **Business Role**: Pharmacy owners list excess inventory. Admin approves listings. System coordinates available market inventory.
* **Potential Bugs / Edge Cases**: getMarketExcesses checks quotas on-the-fly and aggregates records. Highly exposed to performance bottlenecks on large inventories. Selected prices are verified manually.
* **Possible Breaking Scenarios**: Circular reference in lazy-loading services might throw error if the require stack is corrupted.

#### Mapped Endpoints:
* `router.post('/', protect, authorize('pharmacy_owner'), strictLimiter, excessController.createExcess);`
* `router.put('/:id', protect, authorize('admin', 'pharmacy_owner'), strictLimiter, excessController.updateExcess);`
* `router.get('/my', protect, authorize('pharmacy_owner'), getLimiter, excessController.getMyExcesses);`
* `router.get('/market', protect, authorize('admin', 'pharmacy_owner'), getLimiter, excessController.getMarketExcesses);`
* `router.get('/pending', protect, authorize('admin'), getLimiter, excessController.getPendingExcesses);`
* `router.get('/fulfilled', protect, authorize('admin'), getLimiter, excessController.getFulfilledExcesses);`
* `router.get('/available', protect, authorize('admin', 'pharmacy_owner'), getLimiter, excessController.getAvailableExcesses);`
* `router.get('/pharmacy/:pharmacyId', protect, authorize('admin', 'pharmacy_owner'), getLimiter, excessController.getPharmacyExcesses);`
* `router.get('/market-insight', protect, getLimiter, excessController.getMarketInsight);`
* `router.put('/:id/approve', protect, authorize('admin'), strictLimiter, excessController.approveExcess);`
* `router.put('/:id/reject', protect, authorize('admin'), strictLimiter, excessController.rejectExcess);`
* `router.post('/add-to-hub', protect, authorize('admin'), strictLimiter, excessController.addToHub);`
* `router.get('/hub-system', protect, excessController.getHubSystemSummary);`
* `router.delete('/:id', protect, authorize('admin', 'pharmacy_owner'), strictLimiter, excessController.deleteExcess);`

---

### Controller: [listingController.js](file:///d:/MediSync/backend/src/controllers/listingController.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Business Role**: Enables pharmacy owners to view their own stock excess listings.
* **Potential Bugs / Edge Cases**: Minimal filtering options. Simple DB query.
* **Possible Breaking Scenarios**: None.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.get('/my', authorize('pharmacy_owner'), getLimiter, getMyListings);`

---

### Controller: [notificationController.js](file:///d:/MediSync/backend/src/controllers/notificationController.js)
* **Status**: `Active`
* **Utility Rating**: `8.5/10`
* **Business Role**: Triggers notifications to users (WebSockets/Push) regarding order settlements and status.
* **Potential Bugs / Edge Cases**: Pusher trigger is not wrapped in strong try/catch blocks; third-party service downtime might log noise errors.
* **Possible Breaking Scenarios**: Pusher config credentials mismatch.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.get('/', getLimiter, notificationController.getMyNotifications);`
* `router.put('/mark-all-seen', strictLimiter, notificationController.markAllAsSeen);`
* `router.put('/:id/seen', strictLimiter, notificationController.markAsSeen);`
* `router.post('/test', strictLimiter, (req, res) => {`

---

### Controller: [orderController.js](file:///d:/MediSync/backend/src/controllers/orderController.js)
* **Status**: `Active`
* **Utility Rating**: `8.5/10`
* **Business Role**: Fetches historical shortage/purchasing orders for pharmacy owners.
* **Potential Bugs / Edge Cases**: No paging support. Performance will degrade over time.
* **Possible Breaking Scenarios**: None.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.get('/my', authorize('pharmacy_owner'), getLimiter, getMyOrders);`

---

### Controller: [ownerPaymentController.js](file:///d:/MediSync/backend/src/controllers/ownerPaymentController.js)
* **Status**: `Active`
* **Utility Rating**: `8/10`
* **Business Role**: Tracks financial payouts to pharmacy owners.
* **Potential Bugs / Edge Cases**: No validation restricting payouts below cash balance limit. Hub cashBalance can drop to negative values.
* **Possible Breaking Scenarios**: Orphaned ownerId.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.post('/', ownerPaymentController.createPayment);`
* `router.get('/', ownerPaymentController.getPayments);`
* `router.put('/:id', ownerPaymentController.updatePayment);`
* `router.delete('/:id', ownerPaymentController.deletePayment);`

---

### Controller: [ownerController.js](file:///d:/MediSync/backend/src/controllers/ownerController.js)
* **Status**: `Active`
* **Utility Rating**: `8/10`
* **Business Role**: Provides CRUD support for pharmacy owner profiles.
* **Potential Bugs / Edge Cases**: Redundant profiles: User models already contain owner links.
* **Possible Breaking Scenarios**: None.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.post('/', ownerController.createOwner);`
* `router.put('/:id', ownerController.updateOwner);`
* `router.get('/', ownerController.getOwners);`

---

### Controller: [paymentController.js](file:///d:/MediSync/backend/src/controllers/paymentController.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Business Role**: Admin manual cash deposit and withdrawal recordings for pharmacies, adjusting regular balances and hub cash balances.
* **Potential Bugs / Edge Cases**: No check preventing pharmacy.balance from dropping below 0 during withdrawal payouts. Hub cashBalance can drop indefinitely.
* **Possible Breaking Scenarios**: If target pharmacy is deleted, related payments remain as orphans.

#### Mapped Endpoints:
* `router.get('/hub-cash', protect, getHubCashSummary);`
* `router.get('/', protect, authorize('admin', 'pharmacy_owner'), getPayments);`
* `router.post('/', protect, authorize('admin'), createPayment);`
* `router.put('/:id', protect, authorize('admin'), updatePayment);`
* `router.delete('/:id', protect, authorize('admin'), deletePayment);`

---

### Controller: [productQuotaController.js](file:///d:/MediSync/backend/src/controllers/productQuotaController.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Business Role**: Manages deal purchase limits (quotas) for standard pharmacies.
* **Potential Bugs / Edge Cases**: Double inputs: duplicate quota rules on same deal attributes creates key violations.
* **Possible Breaking Scenarios**: None.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.use(authorize('admin'));`
* `router.post('/', productQuotaController.createQuota);`
* `router.get('/', productQuotaController.getQuotas);`
* `router.put('/:id', productQuotaController.updateQuota);`
* `router.delete('/:id', productQuotaController.deleteQuota);`

---

### Controller: [productController.js](file:///d:/MediSync/backend/src/controllers/productController.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Business Role**: Product inventory management (CRUD), products lite, volume prices, suggesting products, and toggling product status.
* **Potential Bugs / Edge Cases**: Volume price updates do not retroactively modify pending transaction rates, which is normal but could lead to user confusion.
* **Possible Breaking Scenarios**: If an active product is disabled while in a pending match transaction.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.get('/', getLimiter, productController.getAllProducts);`
* `router.get('/lite', getLimiter, productController.getProductsLite);`
* `router.post('/suggest', authorize('pharmacy_owner'), strictLimiter, productController.suggestProduct);`
* `router.get('/suggestions', getLimiter, productController.getSuggestions);`
* `router.put('/suggestions/:id', authorize('admin'), strictLimiter, productController.updateSuggestionStatus);`
* `router.get('/:id', getLimiter, productController.getProductById);`
* `router.post('/', authorize('admin'), strictLimiter, productController.createProduct);`
* `router.put('/:id', authorize('admin'), strictLimiter, productController.updateProduct);`
* `router.post('/volume/:hasVolumeId/price', authorize('admin'), strictLimiter, productController.addPriceToVolume);`
* `router.delete('/volume/:hasVolumeId/price', authorize('admin'), strictLimiter, productController.removePriceFromVolume);`
* `router.patch('/volume/:hasVolumeId/value', authorize('admin'), strictLimiter, productController.updateHasVolumeValue);`
* `router.patch('/:id/toggle-status', protect, authorize('admin'), strictLimiter, productController.toggleProductStatus);`

---

### Controller: [purchaseInvoiceController.js](file:///d:/MediSync/backend/src/controllers/purchaseInvoiceController.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Business Role**: CRUD endpoints for administrative invoicing of wholesale drug purchases.
* **Potential Bugs / Edge Cases**: Relies on manual invoices totals; if front end totals mismatch item sum, backend logs warning but completes the query.
* **Possible Breaking Scenarios**: None.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.post('/', purchaseInvoiceController.createInvoice);`
* `router.get('/', purchaseInvoiceController.getInvoices);`
* `router.put('/:id', purchaseInvoiceController.updateInvoice);`
* `router.delete('/:id', purchaseInvoiceController.deleteInvoice);`

---

### Controller: [pusherController.js](file:///d:/MediSync/backend/src/controllers/pusherController.js)
* **Status**: `Active`
* **Utility Rating**: `9.5/10`
* **Business Role**: Authenticates WebSocket channels for real-time app notifications.
* **Potential Bugs / Edge Cases**: None.
* **Possible Breaking Scenarios**: WebSocket gateway failures.

#### Mapped Endpoints:
* `router.post('/auth', protect, authenticate);`

---

### Controller: [requestsHistoryController.js](file:///d:/MediSync/backend/src/controllers/requestsHistoryController.js)
* **Status**: `Active`
* **Utility Rating**: `8/10`
* **Business Role**: Exposes endpoints for the respective routing modules.
* **Potential Bugs / Edge Cases**: None identified.
* **Possible Breaking Scenarios**: None identified.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.get('/my', authorize('pharmacy_owner'), getLimiter, getMyRequestsHistory);`

---

### Controller: [salesInvoiceController.js](file:///d:/MediSync/backend/src/controllers/salesInvoiceController.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Business Role**: Offline wholesaler invoicing controller for hubs.
* **Potential Bugs / Edge Cases**: None.
* **Possible Breaking Scenarios**: None.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.post('/', salesInvoiceController.createInvoice);`
* `router.get('/', salesInvoiceController.getInvoices);`
* `router.put('/:id', salesInvoiceController.updateInvoice);`
* `router.delete('/:id', salesInvoiceController.deleteInvoice);`

---

### Controller: [settingsController.js](file:///d:/MediSync/backend/src/controllers/settingsController.js)
* **Status**: `Active - Update functionality is disabled/deprecated`
* **Utility Rating**: `7.5/10`
* **Business Role**: Get platform metadata/config parameters like system commission/rewards.
* **Potential Bugs / Edge Cases**: Update settings endpoint is completely commented out in route files, requiring database manual entry for modification.
* **Possible Breaking Scenarios**: Missing settings collection documents causes calculations division crash.

#### Mapped Endpoints:
* `router.get('/', protect, getLimiter, getSettings);`
* `// router.put('/', protect, strictLimiter, updateSettings);`

---

### Controller: [shortageController.js](file:///d:/MediSync/backend/src/controllers/shortageController.js)
* **Status**: `Active`
* **Utility Rating**: `8.5/10`
* **Business Role**: Allows pharmacy owners to log stock shortages, order deals, or cancel requests.
* **Potential Bugs / Edge Cases**: Shortage quantities can be updated dynamically, but if transaction matching is initiated simultaneously, race conditions may arise.
* **Possible Breaking Scenarios**: If deal target price lists are deleted while shortage remains active.

#### Mapped Endpoints:
* `router.post('/', protect, authorize('pharmacy_owner'), strictLimiter, createShortage);`
* `router.post('/order', protect, authorize('pharmacy_owner'), strictLimiter, createOrder);`
* `router.put('/:id', protect, authorize('pharmacy_owner'), strictLimiter, updateShortage); // Keep generic update first`
* `router.put('/:id/cancel', protect, authorize('pharmacy_owner'), strictLimiter, cancelShortage);`
* `router.get('/my', protect, authorize('pharmacy_owner'), getLimiter, getMyShortages);`
* `router.get('/orders', protect, authorize('admin'), getLimiter, getOrders);`
* `router.get('/active', protect, authorize('admin'), getLimiter, getActiveShortages);`
* `router.get('/fulfilled', protect, authorize('admin'), getLimiter, getFulfilledShortages);`
* `router.get('/global-active', protect, getLimiter, getGlobalActiveShortages);`
* `router.delete('/:id', protect, authorize('admin', 'pharmacy_owner'), strictLimiter, deleteShortage);`

---

### Controller: [suggestionController.js](file:///d:/MediSync/backend/src/controllers/suggestionController.js)
* **Status**: `Active`
* **Utility Rating**: `8/10`
* **Business Role**: App feedback suggestion loggers. Marks as seen by admins.
* **Potential Bugs / Edge Cases**: No anti-spam rate limiting on createSuggestion, allowing malicious users to flood DB.
* **Possible Breaking Scenarios**: None.

#### Mapped Endpoints:
* `router.post('/', protect, strictLimiter, suggestionController.createSuggestion);`
* `router.put('/:id/seen', protect, admin, strictLimiter, suggestionController.markAsSeen);`
* `router.get('/', protect, admin, getLimiter, suggestionController.getAllSuggestions);`

---

### Controller: [summaryController.js](file:///d:/MediSync/backend/src/controllers/summaryController.js)
* **Status**: `Active`
* **Utility Rating**: `8.5/10`
* **Business Role**: Administrative statistics summaries, lists, counts.
* **Potential Bugs / Edge Cases**: Performs full scans on collections without cache.
* **Possible Breaking Scenarios**: None.

#### Mapped Endpoints:
* `router.get('/pharmacies-list', protect, summaryController.getPharmaciesList);`
* `router.get('/admin', protect, admin, summaryController.getAdminSummary);`

---

### Controller: [transactionController.js](file:///d:/MediSync/backend/src/controllers/transactionController.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Business Role**: Platform matches execution core (cancel, status changes, unassign/assign delivery, revert, ratio updates).
* **Potential Bugs / Edge Cases**: Floating precision errors in ratios and status changes. Direct status modification in revertTransaction bypasses updateTransactionStatus checks.
* **Possible Breaking Scenarios**: Database node crashes during multi-step revert operations.

#### Mapped Endpoints:
* `router.use(protect);`
* `router.get('/matchable', authorize('admin'), getLimiter, getMatchableProducts);`
* `router.get('/matches/:productId', authorize('admin'), getLimiter, getMatchesForProduct);`
* `router.get('/', authorize('admin', 'delivery'), getLimiter, getTransactions);`
* `router.post('/fulfill', authorize('admin'), strictLimiter, fulfillOrder); // Order specific`
* `router.post('/', authorize('admin'), strictLimiter, createTransaction);`
* `router.put('/:id/status', authorize('admin'), strictLimiter, updateTransactionStatus);`
* `router.put('/:id/ratios', authorize('admin'), strictLimiter, updateTransactionRatios);`
* `router.put('/:id', authorize('admin'), strictLimiter, updateTransaction);`
* `router.post('/:id/revert', authorize('admin'), sensitiveLimiter, revertTransaction);`
* `router.put('/reversal/:ticketId', authorize('admin'), sensitiveLimiter, updateReversalTicket);`
* `router.put('/:id/assign', authorize('delivery'), strictLimiter, assignTransaction);`
* `router.put('/:id/unassign', authorize('admin'), strictLimiter, unassignTransaction);`

---

## Backend Services Inventory

Each core business operation in MediSync is managed via a dedicated Service layer to decouple database schemas and API request handlers. Below is an audit of all 15 services:

### Service: [auditService.js](file:///d:/MediSync/backend/src/services/auditService.js)
* **Status**: `Active`
* **Utility Rating**: `8.5/10`
* **Service Responsibility (Business Role)**: Logging and security control.
* **Functional Description**: Registers administrative operations into the AuditLog collection to guarantee accountability.
* **Parameters**: `actionData (Object Containing User, Action, EntityType, EntityId, Changes), req (Express Request)`
* **Potential Bugs & Edge Cases**: Synchronous logger structure inside Mongoose transaction block can create bottlenecks. Lack of req object validations.
* **Possible Breaking Scenarios**: Mongo downtime locks standard API requests because audit logging is blocking.


---

### Service: [authService.js](file:///d:/MediSync/backend/src/services/authService.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Service Responsibility (Business Role)**: Security boundary.
* **Functional Description**: Core authentication and password processing utilities.
* **Parameters**: `User credentials and authentication payload.`
* **Potential Bugs & Edge Cases**: Token expiry is statically defined. No invalidation logic on password changes.
* **Possible Breaking Scenarios**: Crypto context errors.


---

### Service: [commissionService.js](file:///d:/MediSync/backend/src/services/commissionService.js)
* **Status**: `Active`
* **Utility Rating**: `7/10`
* **Service Responsibility (Business Role)**: Deal commission splits.
* **Functional Description**: Handles transaction splits, calculating commissions for the system and final discount rates.
* **Parameters**: `originalSale (Number), systemMinComm (Number)`
* **Potential Bugs & Edge Cases**: Overwrites dynamic split logic with flat systemMinComm. If user inputs 5% discount, it forces 10% commission, leading to pricing bugs.
* **Possible Breaking Scenarios**: Missing settings document.


---

### Service: [excessService.js](file:///d:/MediSync/backend/src/services/excessService.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Service Responsibility (Business Role)**: Excess stock management.
* **Functional Description**: Core lifecycle management of excess stocks, including hub transfers and price validations.
* **Parameters**: `userData, pharmacyId, req, session`
* **Potential Bugs & Edge Cases**: Self-dealing check only verifies string cast IDs which works but could be simplified.
* **Possible Breaking Scenarios**: Lazy loading circular dependencies resolver could break if directories are altered.


---

### Service: [hubSummaryService.js](file:///d:/MediSync/backend/src/services/hubSummaryService.js)
* **Status**: `Active`
* **Utility Rating**: `8.5/10`
* **Service Responsibility (Business Role)**: Dashboard summaries.
* **Functional Description**: Aggregates revenue, active matches, and cash balances for central hub dashboards.
* **Parameters**: `pharmacyId (ObjectId)`
* **Potential Bugs & Edge Cases**: Unindexed database scans on CashBalanceHistory.
* **Possible Breaking Scenarios**: Aggregation execution timeout.


---

### Service: [isupplyPuppeteerService.js](file:///d:/MediSync/backend/src/services/isupplyPuppeteerService.js)
* **Status**: `Active - Highly fragile`
* **Utility Rating**: `6.5/10`
* **Service Responsibility (Business Role)**: Automated distributor scraping.
* **Functional Description**: Automated iSupply product directory sync using Puppeteer Extra Stealth.
* **Parameters**: `keyword (String), isupplyTitle (String)`
* **Potential Bugs & Edge Cases**: Highly brittle selectors. Inheadless servers, it is vulnerable to CAPTCHA blocks. Livewire input waits can fail.
* **Possible Breaking Scenarios**: iSupply updates site design, leading to JSON parse exceptions on screen text.


---

### Service: [ownerPaymentService.js](file:///d:/MediSync/backend/src/services/ownerPaymentService.js)
* **Status**: `Active`
* **Utility Rating**: `8/10`
* **Service Responsibility (Business Role)**: Capital outflow ledgers.
* **Functional Description**: Handles owner payout ledger entries.
* **Parameters**: `pharmacyId, value, session`
* **Potential Bugs & Edge Cases**: No validation checks against negative cash balances.
* **Possible Breaking Scenarios**: Database errors.


---

### Service: [ownerService.js](file:///d:/MediSync/backend/src/services/ownerService.js)
* **Status**: `Active`
* **Utility Rating**: `8/10`
* **Service Responsibility (Business Role)**: Owner properties database.
* **Functional Description**: Controls metadata profiles of registered pharmacy owners.
* **Parameters**: `ownerData`
* **Potential Bugs & Edge Cases**: Minimal schema validations.
* **Possible Breaking Scenarios**: Duplicates database fields.


---

### Service: [purchaseInvoiceService.js](file:///d:/MediSync/backend/src/services/purchaseInvoiceService.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Service Responsibility (Business Role)**: Inventory replenishment.
* **Functional Description**: Manages wholesale purchases, updating cash balance and regular balance with costs.
* **Parameters**: `data, pharmacyId, req, session`
* **Potential Bugs & Edge Cases**: Dual-deduction model. Cash balance is reduced, but online sales do not undo this offset, causing discrepancies.
* **Possible Breaking Scenarios**: Insufficient cash balance error flags block urgent restocks.


---

### Service: [quotaService.js](file:///d:/MediSync/backend/src/services/quotaService.js)
* **Status**: `Active`
* **Utility Rating**: `8/10`
* **Service Responsibility (Business Role)**: Market pricing control rules.
* **Functional Description**: Maintains monthly purchasing limitations on designated product deals.
* **Parameters**: `pharmacyId, dealAttributes, requestedQuantity`
* **Potential Bugs & Edge Cases**: Statically increments expiration month. If multiple transactions occur, the expiration does not extend, but resets can clash.
* **Possible Breaking Scenarios**: Deleted quotas leave usages unaltered.


---

### Service: [salesInvoiceService.js](file:///d:/MediSync/backend/src/services/salesInvoiceService.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Service Responsibility (Business Role)**: Wholesale transactions.
* **Functional Description**: Wholesale direct dispatch invoicing services.
* **Parameters**: `data, pharmacyId, session`
* **Potential Bugs & Edge Cases**: Deleting items recalculates balance, but adding items is not allowed, creating a restrictive invoice correction UX.
* **Possible Breaking Scenarios**: Recalculation error if item excess is missing/deleted.


---

### Service: [serialService.js](file:///d:/MediSync/backend/src/services/serialService.js)
* **Status**: `Active`
* **Utility Rating**: `9.5/10`
* **Service Responsibility (Business Role)**: Unique invoice IDs assignment.
* **Functional Description**: Generates atomic formatted serial numbers for transactions and shortages (e.g. TX-XXXXXXXX-XXXX).
* **Parameters**: `prefix (String)`
* **Potential Bugs & Edge Cases**: Concurrency issues are resolved via atomic counters, but if query timeouts occur, it throws raw connection errors.
* **Possible Breaking Scenarios**: Loss of SerialCounter document.


---

### Service: [shortageService.js](file:///d:/MediSync/backend/src/services/shortageService.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Service Responsibility (Business Role)**: Demands logs.
* **Functional Description**: Checks inventories, quotas, and manages standard pharmacy shortage logs.
* **Parameters**: `data, pharmacyId, req, session`
* **Potential Bugs & Edge Cases**: Lazy loads transactionService.
* **Possible Breaking Scenarios**: State inconsistencies.


---

### Service: [transactionService.js](file:///d:/MediSync/backend/src/services/transactionService.js)
* **Status**: `Active`
* **Utility Rating**: `9/10`
* **Service Responsibility (Business Role)**: Financial settlement core.
* **Functional Description**: Settlements, reversals, notify systems, and financial ledger calculations.
* **Parameters**: `data, session, req`
* **Potential Bugs & Edge Cases**: CRITICAL: Standard electronic settlements (online matches) fail to credit Hub cashBalance. Hub cash is only credited for offline SalesInvoice, resulting in total cash balance bleed.
* **Possible Breaking Scenarios**: Floating point balances calculation errors.


---

### Service: [transactionSummaryService.js](file:///d:/MediSync/backend/src/services/transactionSummaryService.js)
* **Status**: `Active`
* **Utility Rating**: `8.5/10`
* **Service Responsibility (Business Role)**: Ledger reporting.
* **Functional Description**: Platform transactions summaries and reports.
* **Parameters**: `filters`
* **Potential Bugs & Edge Cases**: None.
* **Possible Breaking Scenarios**: None.


---

## Strategic Action Plan

To resolve the flagged business vulnerabilities and ensure long-term stability:

1. **Urgent Compensation Fix**: Edit `compensationController.js`'s `updateCompensation` and `deleteCompensation` methods to check if the target pharmacy is a Hub, and adjust `cashBalance` and write `CashBalanceHistory` entries.
2. **Standardize Online Hub Settlements**: Modify `transactionService.js`'s `settleSellers()` to record Hub sales cash inflows to `cashBalance` when the seller is a Hub, ensuring online and offline sales recover inventory capital consistently.
3. **Ledger Rounding implementation**: Implement a utility library to round all financial balance updates to two decimal places, removing JavaScript floating-point errors.
4. **Resilient Scraper Architecture**: Migrate from raw selector-based Puppeteer to direct API integrations if possible, or implement fallback selectors with email alert triggers on scraper failures.
