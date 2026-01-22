# MediSync Backend - Database Schema Documentation

## Overview
MediSync is a pharmacy network management system that helps pharmacies balance their stock by connecting those with shortages to those with excesses.

## Entity Relationship Diagram

```
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│  Pharmacy   │──────<│     User     │       │  Category   │
└─────────────┘       └──────────────┘       └─────────────┘
      │                                              │
      │                                              │
      ├──────────────────┬──────────────────┐       │
      │                  │                  │       │
      ▼                  ▼                  ▼       ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────────┐
│StockShortage│   │ StockExcess │   │    Product      │
└─────────────┘   └─────────────┘   └─────────────────┘
      │                  │                  │
      │                  │                  │
      └────────┬─────────┘                  │
               ▼                            │
        ┌─────────────┐                     │
        │ Transaction │                     │
        └─────────────┘                     │
               │                            │
               ▼                            ▼
          ┌────────┐                  ┌──────────┐
          │ Review │                  │HasVolume │
          └────────┘                  └──────────┘
                                            │
                                            ▼
                                      ┌──────────┐
                                      │  Volume  │
                                      └──────────┘
```

## Models

### 1. Pharmacy
Represents a registered pharmacy in the network.

**Fields:**
- `name` - Pharmacy name
- `phone` - Contact phone
- `email` - Contact email
- `ownerName` - Owner's name as per license
- `nationalId` - National ID number
- `pharmacistCard` - Pharmacist syndicate card
- `commercialRegistry` - Commercial registry number
- `taxCard` - Tax card number
- `pharmacyLicense` - Pharmacy license number
- `signImage` - Pharmacy sign image path
- `address` - Object containing street, city, governorate, postalCode
- `location` - GeoJSON Point for mapping (coordinates: [longitude, latitude])
- `status` - pending | active | suspended | rejected
- `verified` - Boolean, admin verification status
- `rating` - Average rating (0-5)
- `totalTransactions` - Transaction counter

**Indexes:**
- Geospatial index on `location` for proximity queries
- Text index on `name`, `address.city`, `address.governorate`

---

### 2. User
Represents system users (admins, pharmacy owners, staff).

**Fields:**
- `name` - User's full name
- `phone` - Unique phone number
- `email` - Unique email address
- `hashedPassword` - Bcrypt hashed password
- `role` - admin | pharmacy_owner | pharmacy_staff
- `pharmacy` - Reference to Pharmacy (required for non-admin users)
- `status` - active | inactive | suspended
- `lastLogin` - Last login timestamp
- `refreshToken` - JWT refresh token
- `passwordResetToken` - Password reset token
- `passwordResetExpires` - Reset token expiration

**Methods:**
- `comparePassword(candidatePassword)` - Compare plain password with hash
- `toJSON()` - Removes sensitive fields from output

**Middleware:**
- Pre-save hook to hash passwords

---

### 3. Category
Product categories with hierarchical support.

**Fields:**
- `name` - Category name (English)
- `nameAr` - Category name (Arabic)
- `description` - Category description
- `parentCategory` - Reference to parent Category (for hierarchy)
- `icon` - Icon name or path

**Indexes:**
- Text index on `name`, `nameAr`

---

### 4. Manufacturer
Product manufacturers.

**Fields:**
- `name` - Manufacturer name (English)
- `nameAr` - Manufacturer name (Arabic)
- `country` - Country of origin
- `website` - Company website
- `contactInfo` - Contact information

**Indexes:**
- Text index on `name`, `nameAr`

---

### 5. Product
Pharmaceutical products.

**Fields:**
- `name` - Product name
- `description` - Product description
- `activeIngredient` - Scientific/chemical name
- `manufacturer` - Reference to Manufacturer
- `category` - Reference to Category
- `conversions` - Array of unit conversions:
  - `from` - Source unit (e.g., "Box")
  - `to` - Target unit (e.g., "Strip")
  - `value` - Conversion factor (e.g., 1 Box = 10 Strips)
- `status` - active | discontinued

**Indexes:**
- Text index on `name`, `activeIngredient`, `description`

**Example conversions:**
```javascript
conversions: [
  { from: "Box", to: "Strip", value: 10 },
  { from: "Strip", to: "Tablet", value: 10 }
]
// Means: 1 Box = 10 Strips, 1 Strip = 10 Tablets
```

---

### 6. Volume
Unit types (Box, Strip, Tablet, Bottle, etc.).

**Fields:**
- `name` - Volume/unit name (unique)

---

### 7. HasVolume
Junction table linking products to their available volumes with pricing.

**Fields:**
- `product` - Reference to Product
- `volume` - Reference to Volume
- `value` - Value relative to base unit
- `price` - Price for this product-volume combination

**Indexes:**
- Unique compound index on `product` + `volume`

**Example:**
```javascript
// Panadol Box
{
  product: ObjectId("Panadol"),
  volume: ObjectId("Box"),
  value: 100,  // 100 tablets per box
  price: 50    // 50 EGP per box
}
```

---

### 8. StockShortage
Pharmacy requests for products they need.

**Fields:**
- `pharmacy` - Reference to requesting Pharmacy
- `product` - Reference to Product
- `volume` - Reference to Volume
- `quantity` - Quantity needed
- `expiryDate` - Minimum acceptable expiry date (default: 10 years from now)
- `maxPrice` - Maximum price willing to pay (default: 0 = no limit)
- `status` - active | in_progress | fulfilled | cancelled
- `notes` - Additional notes

**Indexes:**
- `pharmacy` + `status`
- `product` + `volume` + `status`

---

### 9. StockExcess
Pharmacy offers for products they have in excess.

**Fields:**
- `pharmacy` - Reference to offering Pharmacy
- `product` - Reference to Product
- `volume` - Reference to Volume
- `quantity` - Quantity available
- `expiryDate` - Product expiry date
- `sellingPrice` - Asking price
- `minPrice` - Minimum acceptable price
- `accepted` - Boolean, admin approval status
- `status` - available | reserved | sold | expired

**Indexes:**
- `pharmacy` + `status`
- `product` + `volume` + `status` + `accepted`
- `expiryDate`

---

### 10. Transaction
Records of shortage fulfillment from one or more excess sources.

**Fields:**
- `stockShortage` - Reference to the shortage being fulfilled
- `stockExcessSources` - Array of sources:
  - `stockExcess` - Reference to StockExcess
  - `quantity` - Quantity taken from this source
  - `agreedPrice` - Price per unit
  - `totalAmount` - quantity × agreedPrice
- `buyerPharmacy` - Reference to buyer Pharmacy
- `sellerPharmacies` - Array of seller Pharmacy references
- `product` - Reference to Product
- `volume` - Reference to Volume
- `totalQuantity` - Total quantity transferred
- `totalAmount` - Total transaction amount
- `status` - pending | accepted | rejected | completed | cancelled

**Indexes:**
- `stockShortage`
- `buyerPharmacy` + `status`
- `sellerPharmacies` + `status`
- `product` + `status`

**Note:** One shortage can be fulfilled by multiple excess sources.

---

### 11. Notification
User notifications for various events.

**Fields:**
- `user` - Reference to User
- `type` - transaction | message | system | alert
- `priority` - low | normal | high
- `message` - Notification text
- `relatedEntity` - Dynamic reference to related entity
- `relatedEntityType` - Entity model name (Transaction, StockShortage, etc.)
- `actionUrl` - Deep link to relevant app page
- `seen` - Boolean, read status
- `seenAt` - Timestamp when marked as seen

**Indexes:**
- `user` + `seen` + `createdAt` (descending)
- `user` + `type` + `seen`

---

### 12. Review
Pharmacy ratings and reviews after transactions.

**Fields:**
- `reviewerPharmacy` - Reference to reviewing Pharmacy
- `reviewedPharmacy` - Reference to reviewed Pharmacy
- `transaction` - Reference to Transaction
- `rating` - Rating (1-5)
- `comment` - Review text
- `response` - Response from reviewed pharmacy

**Indexes:**
- Unique compound index on `reviewerPharmacy` + `transaction`
- `reviewedPharmacy`

**Post-save Hook:**
- Automatically updates the reviewed pharmacy's average rating

---

### 13. AuditLog
Compliance and security tracking.

**Fields:**
- `user` - Reference to User who performed action
- `action` - CREATE | UPDATE | DELETE | LOGIN | LOGOUT
- `entityType` - Model name of affected entity
- `entityId` - ID of affected entity
- `changes` - Object containing changes made
- `ipAddress` - Request IP address
- `userAgent` - Request user agent

**Indexes:**
- `user` + `createdAt` (descending)
- `entityType` + `entityId` + `createdAt` (descending)
- `action` + `createdAt` (descending)

---

## Usage

Import all models:
```javascript
const { Pharmacy, User, Product, Transaction } = require('./src/models');
```

Or import individually:
```javascript
const Pharmacy = require('./src/models/Pharmacy');
```

## Next Steps

1. Create controllers for business logic
2. Create routes for API endpoints
3. Add authentication middleware
4. Add validation middleware
5. Create seed data for testing
