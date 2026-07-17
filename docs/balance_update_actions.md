# MediSync — Balance & Cash Balance Update Reference

> **Fields covered:** `Pharmacy.balance` (trade balance) · `Pharmacy.cashBalance` (hub cash) · `Owner.balance`  
> **History models:** `BalanceHistory` · `CashBalanceHistory`  
> Last updated: 2026-07-17

---

## Quick Glossary

| Term | Meaning |
|---|---|
| `balance` | The trade balance of any pharmacy (buyer, seller, or hub). Represents money owed to or from the platform. |
| `cashBalance` | Physical/operational cash held by a **Hub** pharmacy only. Used for purchasing stock. |
| `Owner.balance` | Balance of an individual `Owner` entity linked to a hub. Tracks money the owner is owed or has paid. |
| `BalanceHistory` | Audit log for every `balance` change. |
| `CashBalanceHistory` | Audit log for every `cashBalance` change. |

---

## 1. Transactions (Stock Matching)

**Domain:** Matching stock shortages with excess stock between pharmacies.  
**Controller:** `transactionController.js`  
**Service:** `transactionService.js`  
**Routes:** `transactionRoutes.js` — all restricted to `admin` (or `delivery` for assign)

---

### 1.1 `POST /api/transaction` — Create Transaction
> `createTransaction` controller → `transactionService.createTransaction`

No balance change at creation. Only stock quantities are locked.

---

### 1.2 `PUT /api/transaction/:id/status` — Update Transaction Status
> `updateTransactionStatus` controller → `transactionService.updateTransactionStatus`

This is the **primary financial trigger**. Balance changes depend on the target status:

#### → Status: `accepted` (from `pending`)
Triggers `settleSellers()`:

| Who | Field | Change | History Type | Formula |
|---|---|---|---|---|
| **Seller pharmacy** (per excess source) | `balance` | **+** | `transaction_revenue` | See formulas below |

**Seller balance formula (normal excess rebalance):**
```
sellerEffect = (1 - sellerCommissionRatio) × source.totalAmount
```
Where `sellerCommissionRatio` = `excess.salePercentage / 100` (or system minimum commission).

**Hub seller (hub-generated/hub-purchase excess):**
```
sellerEffect = excess.purchasePrice × source.quantity
```
(Hub gets cost price back, not sale price.)

**Shortage-fulfillment excess:**
```
sellerEffect = (1 + sellerBonusRatio) × source.totalAmount
```
Where `sellerBonusRatio` = `settings.shortageSellerReward / 100`.

> The **buyer's** computed payment amount (`totalBuyerEffect`) is stored in `transaction.stockShortage.balanceEffect` but is **not applied yet** — it waits for `completed`.

---

#### → Status: `completed` (from `accepted`)
Triggers `settleBuyer()`:

| Who | Field | Change | History Type | Formula |
|---|---|---|---|---|
| **Buyer pharmacy** | `balance` | **−** (negative amount) | `transaction_payment` | `totalBuyerEffect` (always negative) |

**Buyer balance formula (normal):**
```
buyerEffect = -(1 - buyerSaleRatio) × source.totalAmount  (per source, summed)
```
Where `buyerSaleRatio` = `shortage.salePercentage / 100`.

**Hub buyer:**
```
buyerSaleRatio = excess.salePercentage / 100
```

**Shortage-fulfillment:**
```
buyerEffect = -(1 + buyerCommissionRatio) × source.totalAmount
```
Where `buyerCommissionRatio` = `settings.shortageCommission / 100`.

---

#### → Status: `cancelled` or `rejected` (from `accepted`)
Triggers `reverseSellerSettlement()` (since sellers were already paid on `accepted`):

| Who | Field | Change | History Type |
|---|---|---|---|
| **Seller pharmacy** (per source) | `balance` | **−** `source.balanceEffect` | `transaction_revenue_reversal` |

If status jumped from `pending` directly to `cancelled`/`rejected`, no seller reversal is needed (sellers were never settled).

---

### 1.3 `POST /api/transaction/:id/revert` — Revert Completed Transaction
> `revertTransaction` controller → `transactionService.reverseSellerSettlement` + `reverseBuyerPayment`

Applies to **completed** transactions only. Full financial reversal + optional expense deductions.

#### Phase A — Reverse Seller Revenue
| Who | Field | Change | History Type |
|---|---|---|---|
| **Seller pharmacy** (per source) | `balance` | **−** `source.balanceEffect` | `transaction_revenue_reversal` |

#### Phase B — Reverse Buyer Payment
| Who | Field | Change | History Type |
|---|---|---|---|
| **Buyer pharmacy** | `balance` | **−** `stockShortage.balanceEffect` (subtracts a negative = adds back) | `transaction_payment_reversal` |

#### Phase C — Expense Deductions (Reversal Ticket)
Optional punishments assigned to any pharmacy at admin discretion, credited to the selected Hub's cash balance:

| Who | Field | Change | History Type | Condition |
|---|---|---|---|---|
| **Any designated pharmacy** | `balance` | **−** `expense.amount` | `expenses` | Always |
| **Selected Hub** | `cashBalance` | **+** `expense.amount` | `deposit` | Always (CashBalanceHistory) |

---

### 1.4 `PUT /api/transaction/reversal/:ticketId` — Update Reversal Ticket
> `updateReversalTicket` controller (inline in `transactionController.js`)

Corrects the expense penalties on an existing reversal ticket:

**Step 1 — Revert old expenses:**
| Who | Field | Change | History Type | Condition |
|---|---|---|---|---|
| **Previously penalised pharmacy** | `balance` | **+** `old expense.amount` | `expenses` (expense_reversal) | Always |
| **Old Hub** | `cashBalance` | **−** `old expense.amount` | `withdrawal` | Always |

**Step 2 — Apply new expenses:**
| Who | Field | Change | History Type | Condition |
|---|---|---|---|---|
| **Newly designated pharmacy** | `balance` | **−** `new expense.amount` | `expenses` (expense_adjustment) | Always |
| **Selected Hub** | `cashBalance` | **+** `new expense.amount` | `deposit` | Always |

---

### 1.5 Add-to-Hub Transaction Reversal

#### Full Revert — `revertAddToHub`
| Who | Field | Change | History Type |
|---|---|---|---|
| **Hub (buyer)** | `balance` | **−** `stockShortage.balanceEffect` | `transaction_payment` |
| **Seller pharmacy** (per source) | `balance` | **−** `source.balanceEffect` | `transaction_revenue` |

#### Partial Revert — `partialRevertAddToHub`
Proportional to `revertQuantity`:

| Who | Field | Change | History Type |
|---|---|---|---|
| **Seller pharmacy** | `balance` | **−** `NetRevertAmount` | `transaction_revenue` |
| **Hub (buyer)** | `balance` | **+** `NetRevertAmount` | `transaction_payment` |

Where: `NetRevertAmount = (|source.balanceEffect| / source.quantity) × revertQuantity`

---

## 2. Payments (Admin Manual Deposit/Withdrawal)

**Controller:** `paymentController.js`  
**Routes:** `paymentRoutes.js` — restricted to `admin`

---

### 2.1 `POST /api/payment` — Create Payment
> Admin manually records a deposit or withdrawal for a pharmacy.

| Who | Field | Change | History Type | Condition |
|---|---|---|---|---|
| **Pharmacy** | `balance` | **+** amount | `deposit` | `type === 'deposit'` |
| **Pharmacy** | `balance` | **−** amount | `withdrawal` | `type === 'withdrawal'` |
| **Hub** | `cashBalance` | **+** amount | `deposit` | `type === 'deposit'` |
| **Hub** | `cashBalance` | **−** amount | `withdrawal` | `type === 'withdrawal'` |

Both target pharmacy history (BalanceHistory) and Hub CashBalanceHistory are always created together.

---

### 2.2 `PUT /api/payment/:id` — Update Payment
> Reverts the old payment effects and re-applies the new values.

**Step 1 — Revert old:**
```
pharmacy.balance     -= oldPaymentEffect (BalanceHistory)
hub.cashBalance      -= oldPaymentEffect (CashBalanceHistory)
```

**Step 2 — Apply new:**
```
pharmacy.balance     += newPaymentEffect (BalanceHistory)
hub.cashBalance      += newPaymentEffect (CashBalanceHistory)
```

Where `paymentEffect = amount` (if deposit) or `-amount` (if withdrawal).

---

### 2.3 `DELETE /api/payment/:id` — Delete Payment
> Fully reverses the original payment's effect.

```
pharmacy.balance     -= paymentEffect (BalanceHistory)
hub.cashBalance      -= paymentEffect (CashBalanceHistory)
```

History type: reversed (`withdrawal` for what was a `deposit`, and vice versa).

---

## 3. Compensations (Admin Bonus/Penalty)

**Controller:** `compensationController.js`  
**Routes:** `compensationRoutes.js` — restricted to `admin`

---

### 3.1 `POST /api/compensation` — Create Compensation
> Admin grants a compensation amount (from a source Hub's cash balance) to a pharmacy.

| Who | Field | Change | History Type | Condition |
|---|---|---|---|---|
| **Pharmacy** | `balance` | **+** amount | `compensation` | Always |
| **Source Hub** | `cashBalance` | **−** amount | `withdrawal` | Always (CashBalanceHistory) |

---

### 3.2 `PUT /api/compensation/:id` — Update Compensation
> Adjusts the compensation amount and/or source Hub. Old values are reverted and new values applied.

**Step 1 — Revert old:**
```
pharmacy.balance     -= oldAmount (BalanceHistory)
oldHub.cashBalance   += oldAmount (CashBalanceHistory)
```

**Step 2 — Apply new:**
```
pharmacy.balance     += newAmount (BalanceHistory)
newHub.cashBalance   -= newAmount (CashBalanceHistory)
```

---

### 3.3 `DELETE /api/compensation/:id` — Delete Compensation
> Reverts both the pharmacy's received balance and the source Hub's cashBalance.

```
pharmacy.balance     -= compensation.amount (BalanceHistory)
hub.cashBalance      -= compensation.amount (CashBalanceHistory)
```

---

## 4. Purchase Invoices (Hub Buying Stock)

**Controller:** `purchaseInvoiceController.js`  
**Service:** `purchaseInvoiceService.js`  
**Routes:** `purchaseInvoiceRoutes.js`

Only **Hub** pharmacies can use this domain.

---

### 4.1 `POST /api/purchase-invoice` — Create Purchase Invoice
> Hub buys stock from a supplier. Reduces both cash and trade balance.

| Who | Field | Change | History Type |
|---|---|---|---|
| **Hub** | `cashBalance` | **−** `totalAmount` | `withdrawal` (CashBalanceHistory) |
| **Hub** | `balance` | **−** `totalAmount` | `purchase_invoice` (BalanceHistory) |

Guard: throws `400` if `hub.cashBalance < totalAmount`.

---

### 4.2 `PUT /api/purchase-invoice/:id` — Update Purchase Invoice
> Adjusts the invoice total. Corrects both balances by the difference.

| Who | Field | Change | History Type | Condition |
|---|---|---|---|---|
| **Hub** | `cashBalance` | **−** `balanceDiff` | `withdrawal` or `deposit` | if diff ≠ 0 |
| **Hub** | `balance` | **−** `balanceDiff` | `purchase_invoice` | if diff ≠ 0 |

`balanceDiff = newTotal - oldTotal`  
If diff > 0 (invoice grew): both balances decrease further. If diff < 0 (invoice shrank): both balances increase (refund).

Guard: throws `400` if `balanceDiff > 0` and `hub.cashBalance < balanceDiff`.

---

### 4.3 `DELETE /api/purchase-invoice/:id` — Delete Purchase Invoice
> Reverses the original purchase. Restores both balances.

| Who | Field | Change | History Type |
|---|---|---|---|
| **Hub** | `cashBalance` | **+** `invoice.totalAmount` | `deposit` (CashBalanceHistory) |
| **Hub** | `balance` | **+** `invoice.totalAmount` | `purchase_invoice` (BalanceHistory) |

Guard: throws `409` if any line item's stock has already been sold/taken.

---

## 5. Sales Invoices (Hub Selling Stock to Customers)

**Controller:** `salesInvoiceController.js`  
**Service:** `salesInvoiceService.js`  
**Routes:** `salesInvoiceRoutes.js`

Only **Hub** pharmacies can use this domain.

---

### 5.1 `POST /api/sales-invoice` — Create Sales Invoice
> Hub sells stock to an external customer. Increases cash balance (revenue) and partially recovers trade balance (cost price recovery).

| Who | Field | Change | History Type | Formula |
|---|---|---|---|---|
| **Hub** | `cashBalance` | **+** `totalSellingPrice` | `deposit` (CashBalanceHistory) | sum of (qty × sellingPrice) |
| **Hub** | `balance` | **+** `totalBuyingPrice` | `sales_invoice` (BalanceHistory) | sum of (qty × buyingPrice / cost) |

The `balance` increase here **cancels the inventory cost** that was previously deducted by the Purchase Invoice — it is NOT additional profit.

---

### 5.2 `PUT /api/sales-invoice/:id` — Update Sales Invoice
> Adjusts quantities, selling prices, or deletes line items.

| Who | Field | Change | History Type | Condition |
|---|---|---|---|---|
| **Hub** | `cashBalance` | **+/−** `balanceDiff` | `deposit`/`withdrawal` (CashBalanceHistory) | if selling price diff ≠ 0 |
| **Hub** | `balance` | **+/−** `buyingPriceDiff` | `sales_invoice` (BalanceHistory) | if buying price diff ≠ 0 |

`balanceDiff = newTotalSellingPrice - oldTotalSellingPrice`  
`buyingPriceDiff = newTotalBuyingPrice - oldTotalBuyingPrice`

---

### 5.3 `DELETE /api/sales-invoice/:id` — Delete Sales Invoice
> Fully reverses the sale. Reduces cash balance and removes cost recovery.

| Who | Field | Change | History Type |
|---|---|---|---|
| **Hub** | `cashBalance` | **−** `invoice.totalSellingPrice` | `withdrawal` (CashBalanceHistory) |
| **Hub** | `balance` | **−** `invoice.totalBuyingPrice` | `sales_invoice` (BalanceHistory) |

---

## 6. Owner Payments (Hub ↔ Owner Cash Transfers)

**Controller:** `ownerPaymentController.js`  
**Service:** `ownerPaymentService.js`  
**Routes:** `ownerPaymentRoutes.js` — Hub users only (scoped by `req.user.pharmacy`)

---

### 6.1 `POST /api/owner-payment` — Create Owner Payment
> Hub transfers cash to/from an owner. Positive `value` = money injected into Hub (from owner).

| Who | Field | Change |
|---|---|---|
| **Hub** | `cashBalance` | **+** value |
| **Owner** | `balance` | **−** value |

`CashBalanceHistory` is written. No `BalanceHistory` for `Pharmacy.balance`.

---

### 6.2 `PUT /api/owner-payment/:id` — Update Owner Payment
> Corrects the payment value. Applies only the difference.

| Who | Field | Change |
|---|---|---|
| **Hub** | `cashBalance` | **+** diff |
| **Owner** | `balance` | **−** diff |

`diff = newValue - oldValue`

---

### 6.3 `DELETE /api/owner-payment/:id` — Delete Owner Payment
> Reverses the original transfer.

| Who | Field | Change |
|---|---|---|
| **Hub** | `cashBalance` | **−** payment.value |
| **Owner** | `balance` | **+** payment.value |

---

## 7. Access Control Summary

| Endpoint Group | Admin | Pharmacy Owner | Hub User | Delivery |
|---|---|---|---|---|
| Transactions (create/status/revert) | ✅ | ❌ | ❌ | ❌ |
| Transaction assign | ❌ | ❌ | ❌ | ✅ |
| Payments (deposit/withdrawal) | ✅ | ❌ | ❌ | ❌ |
| Payments (view) | ✅ | ✅ (own) | ❌ | ❌ |
| Compensations | ✅ | ❌ | ❌ | ❌ |
| Purchase Invoices | ✅ | ❌ | ✅ (own hub) | ❌ |
| Sales Invoices | ✅ | ❌ | ✅ (own hub) | ❌ |
| Owner Payments | ✅ | ❌ | ✅ (own hub) | ❌ |

---

## 8. Balance History Type Reference

| `type` value | Applies to | Triggered by |
|---|---|---|
| `transaction_revenue` | Seller `balance` | `settleSellers` (on `accepted`) |
| `transaction_payment` | Buyer `balance` | `settleBuyer` (on `completed`) |
| `transaction_revenue_reversal` | Seller `balance` | `reverseSellerSettlement` |
| `transaction_payment_reversal` | Buyer `balance` | `reverseBuyerPayment` |
| `expenses` | Any pharmacy `balance` | Reversal ticket creation/update |
| `deposit` | Pharmacy `balance` / Hub `cashBalance` | Payment create/update (deposit type) |
| `withdrawal` | Pharmacy `balance` / Hub `cashBalance` | Payment create/update (withdrawal type) |
| `compensation` | Pharmacy `balance` | Compensation create/update/delete |
| `purchase_invoice` | Hub `balance` | Purchase invoice create/update/delete |
| `sales_invoice` | Hub `balance` | Sales invoice create/update/delete |

---

## 9. Key Business Logic Notes

> [!NOTE]
> **Two-Phase Settlement:** Sellers are settled on `accepted`, buyers are settled on `completed`. This means a seller gets credited before the buyer is charged — intentional design to incentivise timely delivery.

> [!IMPORTANT]
> **Hub Special Behaviour:** When a Hub is the seller and the excess is `isHubGenerated` or `isHubPurchase`, the seller effect is `purchasePrice × quantity` (not a commission-based formula). Hub profits are separated into the sales/purchase invoice domain.

> [!WARNING]
> **Balance vs CashBalance Distinction:** `Pharmacy.balance` is a virtual ledger balance (can go negative). `Pharmacy.cashBalance` is operational cash for purchasing — enforced as non-negative (throws 400 if insufficient before purchase).

> [!NOTE]
> **Real-time Push:** Every balance mutation fires a `balanceUpdate` Pusher WebSocket event to all users linked to the affected pharmacy. This happens **after** the DB transaction is committed.

> [!CAUTION]
> **Reversal Guard:** `revertTransaction` only works on `status === 'completed'` transactions. If the transaction already has a `reversalTicket`, a second revert is blocked (returns 409).
