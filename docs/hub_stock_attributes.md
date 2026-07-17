# Product Stock Excess Attributes: `isHubGenerated` vs `isHubPurchase`

This document details the definition, usage, controller/service actions, and overall impact of the `isHubGenerated` and `isHubPurchase` attributes on the `StockExcess` model in MediSync.

---

## 1. Cheat Sheet Comparison

| Attribute | Definition | When is it `true`? | `purchasePrice` Calculation | Audit History `type` |
|---|---|---|---|---|
| **`isHubGenerated`** | Represents excess stock transferred to the Hub from a pharmacy. | Created via "Add to Hub" (`excessService.addToHub`). | Computed automatically: `selectedPrice * (1.0 - salePercentage / 100)` | `'hub_transfer_sale'` |
| **`isHubPurchase`** | Represents stock purchased directly by the Hub from an external supplier. | Created via "Purchase Invoice" (`purchaseInvoiceService.createPurchaseInvoice`). | Explicitly provided in the invoice row listing. | `'hub_purchase_sale'` |

---

## 2. Deep Dive: `isHubGenerated`

### 2.1 Creation Flow
1. A regular pharmacy has an approved stock excess.
2. The Hub requests to take custody of this excess (or a portion of it) using the **Add to Hub** action.
3. Under the hood, `excessService.addToHub` verifies available quantity, creates a system shortage at the Hub, and executes a transfer transaction from the pharmacy to the Hub.
4. Finally, a new `StockExcess` record is inserted under the Hub's pharmacy ID with:
   - `isHubGenerated: true`
   - `isHubPurchase: false`
   - `purchasePrice` dynamically set to the discounted price: `selectedPrice * (1.0 - salePercentage / 100)`
   - `relatedPharmacy` set to the original selling pharmacy's ID.

---

## 3. Deep Dive: `isHubPurchase`

### 3.1 Creation Flow
1. An admin/Hub creator receives goods from external suppliers and records them via a **Purchase Invoice**.
2. Under the hood, `purchaseInvoiceService.createPurchaseInvoice` processes each item.
3. It creates/approves a new `StockExcess` record under the Hub's pharmacy ID with:
   - `isHubGenerated: false`
   - `isHubPurchase: true`
   - `purchasePrice` set to the explicit `buyingPrice` specified in the invoice.
   - `relatedPharmacy` is left empty (since it comes from an external vendor, not an internal pharmacy).

---

## 4. How Controllers and Services Treat Them

### 4.1 Shielded from Manual Edits
Both attributes declare that the stock belongs to Hub custody and was generated via a formal upstream process (a Payment/Transfer or a Purchase Invoice). Thus, manual edits to core parameters on the Stock Excess are forbidden:
- **Quantity Updates**: If `isHubGenerated || isHubPurchase` is true, the `updateExcess` service throws a `409 Conflict` error when trying to modify quantities. Quantities must instead be updated directly through the source document (e.g. updating the Purchase Invoice).
- **Price/Expiry Updates**: Updating the `selectedPrice` or `expiryDate` directly on the Stock Excess is blocked and throws a `409 Conflict`.

### 4.2 Sale Cost Retrieval (COGS)
When a Hub transaction completes (a client pharmacy buys stock from the Hub's excess):
- In `transactionService.js`, if the seller is a Hub, the system calculates `sellerEffect` using the item's cost price (`excess.purchasePrice * quantity`).
- Mapped history record tracks:
  - If `isHubPurchase === true` $\rightarrow$ history log matches `type: 'hub_purchase_sale'`.
  - If `isHubGenerated === true` $\rightarrow$ history log matches `type: 'hub_transfer_sale'`.

### 4.3 Sales Invoice Calculation
When a sales invoice is created or canceled for Hub sales:
- The system recovers inventory cost using `salesInvoice.totalBuyingPrice` (sum of `excess.purchasePrice * quantity` across invoice items).
- The Hub's `balance` is adjusted by `totalBuyingPrice` to cancel out/reverse inventory procurement costs, separating trade profit from cost recovery.
- If deleted, this amount is reversed by deducting it from the Hub's standard trade balance.
