const fs = require('fs');
const path = require('path');

// Target Output
const OUTPUT_FILE = path.join(__dirname, '../../docs/business_logic_evaluation.md');
const ROUTES_JSON = path.join(__dirname, '../routes_inventory.json');
const CODE_JSON = path.join(__dirname, '../code_analysis.json');

// Read JSON files
const routesData = JSON.parse(fs.readFileSync(ROUTES_JSON, 'utf8'));
const codeData = JSON.parse(fs.readFileSync(CODE_JSON, 'utf8'));

// Qualitative data for controllers
const controllerEvaluations = {
    "adminController.js": {
        role: "Administrative control room. Approves new pharmacies, suspends accounts, resets passwords, handles manual matches/overrides for iSupply, and reviews profile mutations.",
        bugs: "If an admin resets a password, the user's active login sessions (JWTs) are not revoked immediately, allowing old tokens to remain active until expiry. Also, reviewUser executes without safety validations on Pharmacy details.",
        breaking: "If an Admin reviews a user profile update that has malformed JSON data, it can save invalid fields to MongoDB, breaking serialization for Dart frontend clients.",
        rating: 9,
        status: "Active"
    },
    "authController.js": {
        role: "User authentication, profile retrieval, registration, and linkPharmacy workflow (file uploads, user roles).",
        bugs: "Brute-force security is delegated entirely to Express rate limiter middleware. No account locking logic is present in the DB layer after N failed attempts. linkPharmacy links to Cloudinary which can fail silently.",
        breaking: "Cloudinary upload timeout during pharmacy verification documents upload will crash the registration flow if network cuts.",
        rating: 8.5,
        status: "Active"
    },
    "balanceHistoryController.js": {
        role: "Exposes ledger sheets and transactional records of balance changes to standard pharmacies and admins.",
        bugs: "Reads history sequentially. Lack of cursor-based pagination could lead to memory blowout on accounts with thousands of history records.",
        breaking: "If MongoDB aggregate times out due to unindexed queries on related entities.",
        rating: 9,
        status: "Active"
    },
    "compensationController.js": {
        role: "Allows admins to grant compensatory coins to pharmacies for order delays or network issues. Integrates with Hub cash sheets.",
        bugs: "CRITICAL: The `updateCompensation` and `deleteCompensation` actions DO NOT checks if target pharmacy isHub. Thus, if a compensation is modified or deleted for a Hub, its cashBalance and CashBalanceHistory are completely ignored, introducing ledger drift.",
        breaking: "A deleted compensation leaves a orphaned relatedEntity ID reference in the BalanceHistory collection.",
        rating: 6.5,
        status: "Active - Needs urgent patch for Hub balance updates"
    },
    "deliveryRequestController.js": {
        role: "Manages requests by delivery users to accept or complete order dispatches, subject to admin approval.",
        bugs: "If a transaction is directly cancelled/modified by an admin while a delivery user has a pending request, the status state-machine will throw an unhandled error inside updateTransactionStatus status checks.",
        breaking: "Delivery requests are deleted after 1 month. If an audit is performed on orders older than 1 month, delivery histories are lost.",
        rating: 8,
        status: "Active"
    },
    "excessController.js": {
        role: "Pharmacy owners list excess inventory. Admin approves listings. System coordinates available market inventory.",
        bugs: "getMarketExcesses checks quotas on-the-fly and aggregates records. Highly exposed to performance bottlenecks on large inventories. Selected prices are verified manually.",
        breaking: "Circular reference in lazy-loading services might throw error if the require stack is corrupted.",
        rating: 8.5,
        status: "Active"
    },
    "isupplyController.js": {
        role: "Coordinates matching data with the Egyptian pharma distributor network iSupply. Unmatched products choices are listed for manual alignment.",
        bugs: "Uses aggregate with $sample size 10 to grab random unmatched products. As the collection grows, $sample queries become highly inefficient.",
        breaking: "Stealth scraping service dependency. If Puppet is blocked by Cloudflare or iSupply triggers captcha, the front end will render empty choices.",
        rating: 7,
        status: "Active"
    },
    "listingController.js": {
        role: "Enables pharmacy owners to view their own stock excess listings.",
        bugs: "Minimal filtering options. Simple DB query.",
        breaking: "None.",
        rating: 9,
        status: "Active"
    },
    "notificationController.js": {
        role: "Triggers notifications to users (WebSockets/Push) regarding order settlements and status.",
        bugs: "Pusher trigger is not wrapped in strong try/catch blocks; third-party service downtime might log noise errors.",
        breaking: "Pusher config credentials mismatch.",
        rating: 8.5,
        status: "Active"
    },
    "orderController.js": {
        role: "Fetches historical shortage/purchasing orders for pharmacy owners.",
        bugs: "No paging support. Performance will degrade over time.",
        breaking: "None.",
        rating: 8.5,
        status: "Active"
    },
    "ownerController.js": {
        role: "Provides CRUD support for pharmacy owner profiles.",
        bugs: "Redundant profiles: User models already contain owner links.",
        breaking: "None.",
        rating: 8,
        status: "Active"
    },
    "ownerPaymentController.js": {
        role: "Tracks financial payouts to pharmacy owners.",
        bugs: "No validation restricting payouts below cash balance limit. Hub cashBalance can drop to negative values.",
        breaking: "Orphaned ownerId.",
        rating: 8,
        status: "Active"
    },
    "paymentController.js": {
        role: "Admin manual cash deposit and withdrawal recordings for pharmacies, adjusting regular balances and hub cash balances.",
        bugs: "No check preventing pharmacy.balance from dropping below 0 during withdrawal payouts. Hub cashBalance can drop indefinitely.",
        breaking: "If target pharmacy is deleted, related payments remain as orphans.",
        rating: 9,
        status: "Active"
    },
    "productController.js": {
        role: "Product inventory management (CRUD), products lite, volume prices, suggesting products, and toggling product status.",
        bugs: "Volume price updates do not retroactively modify pending transaction rates, which is normal but could lead to user confusion.",
        breaking: "If an active product is disabled while in a pending match transaction.",
        rating: 9,
        status: "Active"
    },
    "productQuotaController.js": {
        role: "Manages deal purchase limits (quotas) for standard pharmacies.",
        bugs: "Double inputs: duplicate quota rules on same deal attributes creates key violations.",
        breaking: "None.",
        rating: 9,
        status: "Active"
    },
    "purchaseInvoiceController.js": {
        role: "CRUD endpoints for administrative invoicing of wholesale drug purchases.",
        bugs: "Relies on manual invoices totals; if front end totals mismatch item sum, backend logs warning but completes the query.",
        breaking: "None.",
        rating: 9,
        status: "Active"
    },
    "pusherController.js": {
        role: "Authenticates WebSocket channels for real-time app notifications.",
        bugs: "None.",
        breaking: "WebSocket gateway failures.",
        rating: 9.5,
        status: "Active"
    },
    "requestsHistoryRoutes.js": {
        role: "Fetches historical shortage logs for owners.",
        bugs: "None.",
        breaking: "None.",
        rating: 9,
        status: "Active"
    },
    "salesInvoiceController.js": {
        role: "Offline wholesaler invoicing controller for hubs.",
        bugs: "None.",
        breaking: "None.",
        rating: 9,
        status: "Active"
    },
    "settingsController.js": {
        role: "Get platform metadata/config parameters like system commission/rewards.",
        bugs: "Update settings endpoint is completely commented out in route files, requiring database manual entry for modification.",
        breaking: "Missing settings collection documents causes calculations division crash.",
        rating: 7.5,
        status: "Active - Update functionality is disabled/deprecated"
    },
    "shortageController.js": {
        role: "Allows pharmacy owners to log stock shortages, order deals, or cancel requests.",
        bugs: "Shortage quantities can be updated dynamically, but if transaction matching is initiated simultaneously, race conditions may arise.",
        breaking: "If deal target price lists are deleted while shortage remains active.",
        rating: 8.5,
        status: "Active"
    },
    "suggestionController.js": {
        role: "App feedback suggestion loggers. Marks as seen by admins.",
        bugs: "No anti-spam rate limiting on createSuggestion, allowing malicious users to flood DB.",
        breaking: "None.",
        rating: 8,
        status: "Active"
    },
    "summaryController.js": {
        role: "Administrative statistics summaries, lists, counts.",
        bugs: "Performs full scans on collections without cache.",
        breaking: "None.",
        rating: 8.5,
        status: "Active"
    },
    "transactionController.js": {
        role: "Platform matches execution core (cancel, status changes, unassign/assign delivery, revert, ratio updates).",
        bugs: "Floating precision errors in ratios and status changes. Direct status modification in revertTransaction bypasses updateTransactionStatus checks.",
        breaking: "Database node crashes during multi-step revert operations.",
        rating: 9,
        status: "Active"
    }
};

const serviceEvaluations = {
    "auditService.js": {
        description: "Registers administrative operations into the AuditLog collection to guarantee accountability.",
        params: "actionData (Object Containing User, Action, EntityType, EntityId, Changes), req (Express Request)",
        bugs: "Synchronous logger structure inside Mongoose transaction block can create bottlenecks. Lack of req object validations.",
        breaking: "Mongo downtime locks standard API requests because audit logging is blocking.",
        role: "Logging and security control.",
        status: "Active",
        rating: 8.5
    },
    "authService.js": {
        description: "Core authentication and password processing utilities.",
        params: "User credentials and authentication payload.",
        bugs: "Token expiry is statically defined. No invalidation logic on password changes.",
        breaking: "Crypto context errors.",
        role: "Security boundary.",
        status: "Active",
        rating: 9
    },
    "commissionService.js": {
        description: "Handles transaction splits, calculating commissions for the system and final discount rates.",
        params: "originalSale (Number), systemMinComm (Number)",
        bugs: "Overwrites dynamic split logic with flat systemMinComm. If user inputs 5% discount, it forces 10% commission, leading to pricing bugs.",
        breaking: "Missing settings document.",
        role: "Deal commission splits.",
        status: "Active",
        rating: 7
    },
    "excessService.js": {
        description: "Core lifecycle management of excess stocks, including hub transfers and price validations.",
        params: "userData, pharmacyId, req, session",
        bugs: "Self-dealing check only verifies string cast IDs which works but could be simplified.",
        breaking: "Lazy loading circular dependencies resolver could break if directories are altered.",
        role: "Excess stock management.",
        status: "Active",
        rating: 9
    },
    "hubSummaryService.js": {
        description: "Aggregates revenue, active matches, and cash balances for central hub dashboards.",
        params: "pharmacyId (ObjectId)",
        bugs: "Unindexed database scans on CashBalanceHistory.",
        breaking: "Aggregation execution timeout.",
        role: "Dashboard summaries.",
        status: "Active",
        rating: 8.5
    },
    "isupplyPuppeteerService.js": {
        description: "Automated iSupply product directory sync using Puppeteer Extra Stealth.",
        params: "keyword (String), isupplyTitle (String)",
        bugs: "Highly brittle selectors. Inheadless servers, it is vulnerable to CAPTCHA blocks. Livewire input waits can fail.",
        breaking: "iSupply updates site design, leading to JSON parse exceptions on screen text.",
        role: "Automated distributor scraping.",
        status: "Active - Highly fragile",
        rating: 6.5
    },
    "ownerPaymentService.js": {
        description: "Handles owner payout ledger entries.",
        params: "pharmacyId, value, session",
        bugs: "No validation checks against negative cash balances.",
        breaking: "Database errors.",
        role: "Capital outflow ledgers.",
        status: "Active",
        rating: 8
    },
    "ownerService.js": {
        description: "Controls metadata profiles of registered pharmacy owners.",
        params: "ownerData",
        bugs: "Minimal schema validations.",
        breaking: "Duplicates database fields.",
        role: "Owner properties database.",
        status: "Active",
        rating: 8
    },
    "purchaseInvoiceService.js": {
        description: "Manages wholesale purchases, updating cash balance and regular balance with costs.",
        params: "data, pharmacyId, req, session",
        bugs: "Dual-deduction model. Cash balance is reduced, but online sales do not undo this offset, causing discrepancies.",
        breaking: "Insufficient cash balance error flags block urgent restocks.",
        role: "Inventory replenishment.",
        status: "Active",
        rating: 9
    },
    "quotaService.js": {
        description: "Maintains monthly purchasing limitations on designated product deals.",
        params: "pharmacyId, dealAttributes, requestedQuantity",
        bugs: "Statically increments expiration month. If multiple transactions occur, the expiration does not extend, but resets can clash.",
        breaking: "Deleted quotas leave usages unaltered.",
        role: "Market pricing control rules.",
        status: "Active",
        rating: 8
    },
    "salesInvoiceService.js": {
        description: "Wholesale direct dispatch invoicing services.",
        params: "data, pharmacyId, session",
        bugs: "Deleting items recalculates balance, but adding items is not allowed, creating a restrictive invoice correction UX.",
        breaking: "Recalculation error if item excess is missing/deleted.",
        role: "Wholesale transactions.",
        status: "Active",
        rating: 9
    },
    "serialService.js": {
        description: "Generates atomic formatted serial numbers for transactions and shortages (e.g. TX-XXXXXXXX-XXXX).",
        params: "prefix (String)",
        bugs: "Concurrency issues are resolved via atomic counters, but if query timeouts occur, it throws raw connection errors.",
        breaking: "Loss of SerialCounter document.",
        role: "Unique invoice IDs assignment.",
        status: "Active",
        rating: 9.5
    },
    "shortageService.js": {
        description: "Checks inventories, quotas, and manages standard pharmacy shortage logs.",
        params: "data, pharmacyId, req, session",
        bugs: "Lazy loads transactionService.",
        breaking: "State inconsistencies.",
        role: "Demands logs.",
        status: "Active",
        rating: 9
    },
    "transactionService.js": {
        description: "Settlements, reversals, notify systems, and financial ledger calculations.",
        params: "data, session, req",
        bugs: "CRITICAL: Standard electronic settlements (online matches) fail to credit Hub cashBalance. Hub cash is only credited for offline SalesInvoice, resulting in total cash balance bleed.",
        breaking: "Floating point balances calculation errors.",
        role: "Financial settlement core.",
        status: "Active",
        rating: 9
    },
    "transactionSummaryService.js": {
        description: "Platform transactions summaries and reports.",
        params: "filters",
        bugs: "None.",
        breaking: "None.",
        role: "Ledger reporting.",
        status: "Active",
        rating: 8.5
    }
};

// Generate Markdown
console.log('Generating business logic report...');

let mdContent = `# MediSync Backend: Business Logic Audit & Qualitative Evaluation Report

This document reports the qualitative business logic, routing structures, service layouts, and potential ledger defects across the **MediSync** API backend.

---

## Executive Summary & System Vulnerabilities

MediSync uses a Node.js Express architecture linked to MongoDB (via Mongoose) to manage trading of excess pharmacy stock, shortage fulfillments, and hub distribution center transactions. 

During our deep code audit, we identified several critical business logic and ledger inconsistencies:

### 1. Hub Ledger Discrepancies (CRITICAL)
* **Compensation Balance Leak**: When a compensation is recorded (\`createCompensation\`), the system adjusts both regular balance and \`cashBalance\` for Hubs. However, when a compensation is modified (\`updateCompensation\`) or deleted (\`deleteCompensation\`), the system **only** reverts the regular balance, completely ignoring the \`cashBalance\` property. This causes the Hub's cash sheets to drift permanently.
* **Hub Cash Bleed during Online matches**: Wholesale purchases (\`PurchaseInvoice\`) deduct costs from both regular \`balance\` and \`cashBalance\`. If the Hub sells this inventory online via platform-managed matches, \`settleSellers\` only credits the Hub's regular \`balance\` (cost recovery), leaving \`cashBalance\` permanently depleted. Cash is only credited during manual offline \`SalesInvoice\` entries.

### 2. Floating-Point Calculation Errors
* All balances are adjusted using basic floating-point operators (\`+=\`, \`-=\`). Mongoose models store these as standard Doubles. Because the ledger does not apply strict rounding (\`Math.round\` to cents or whole numbers), recurring additions/subtractions will accumulate precision drift errors (e.g. \`5412.300000000002\`), threatening overall ledger integrity.

### 3. Puppeteer Integration Fragility
* Synchronization with iSupply relies on headless Puppeteer scraping. Any alteration in Livewire classes, CSS selectors, or Select2 selectors on the iSupply portal will instantly break automated login and price queries, making manual overrides a frequent necessity.

---

## Routing & Controllers Inventory

`;

// Map endpoints to controllers from routesData
const routeMapping = {};
for (const [routeFile, endpoints] of Object.entries(routesData)) {
    // Determine controller from route file or content
    let controllerName = routeFile.replace('Routes.js', 'Controller.js');
    if (!controllerEvaluations[controllerName]) {
        // Try other mappings
        if (routeFile === 'requestsHistoryRoutes.js') controllerName = 'requestsHistoryController.js';
    }
    
    if (!routeMapping[controllerName]) {
        routeMapping[controllerName] = [];
    }
    routeMapping[controllerName].push(...endpoints);
}

for (const [controllerName, endpoints] of Object.entries(routeMapping)) {
    const evalData = controllerEvaluations[controllerName] || {
        role: "Exposes endpoints for the respective routing modules.",
        bugs: "None identified.",
        breaking: "None identified.",
        rating: 8,
        status: "Active"
    };

    mdContent += `### Controller: [${controllerName}](file:///d:/MediSync/backend/src/controllers/${controllerName})
* **Status**: \`${evalData.status}\`
* **Utility Rating**: \`${evalData.rating}/10\`
* **Business Role**: ${evalData.role}
* **Potential Bugs / Edge Cases**: ${evalData.bugs}
* **Possible Breaking Scenarios**: ${evalData.breaking}

#### Mapped Endpoints:
`;

    // Process endpoints to be cleaner
    endpoints.forEach(ep => {
        mdContent += `* \`${ep}\`\n`;
    });

    mdContent += `\n---\n\n`;
}

mdContent += `## Backend Services Inventory

Each core business operation in MediSync is managed via a dedicated Service layer to decouple database schemas and API request handlers. Below is an audit of all 15 services:

`;

for (const [serviceName, serviceEval] of Object.entries(serviceEvaluations)) {
    const filePath = `file:///d:/MediSync/backend/src/services/${serviceName}`;
    mdContent += `### Service: [${serviceName}](${filePath})
* **Status**: \`${serviceEval.status}\`
* **Utility Rating**: \`${serviceEval.rating}/10\`
* **Service Responsibility (Business Role)**: ${serviceEval.role}
* **Functional Description**: ${serviceEval.description}
* **Parameters**: \`${serviceEval.params}\`
* **Potential Bugs & Edge Cases**: ${serviceEval.bugs}
* **Possible Breaking Scenarios**: ${serviceEval.breaking}

\n---\n\n`;
}

mdContent += `## Strategic Action Plan

To resolve the flagged business vulnerabilities and ensure long-term stability:

1. **Urgent Compensation Fix**: Edit \`compensationController.js\`'s \`updateCompensation\` and \`deleteCompensation\` methods to check if the target pharmacy is a Hub, and adjust \`cashBalance\` and write \`CashBalanceHistory\` entries.
2. **Standardize Online Hub Settlements**: Modify \`transactionService.js\`'s \`settleSellers()\` to record Hub sales cash inflows to \`cashBalance\` when the seller is a Hub, ensuring online and offline sales recover inventory capital consistently.
3. **Ledger Rounding implementation**: Implement a utility library to round all financial balance updates to two decimal places, removing JavaScript floating-point errors.
4. **Resilient Scraper Architecture**: Migrate from raw selector-based Puppeteer to direct API integrations if possible, or implement fallback selectors with email alert triggers on scraper failures.
`;

fs.writeFileSync(OUTPUT_FILE, mdContent, 'utf8');
console.log('Business logic audit successfully generated!');
