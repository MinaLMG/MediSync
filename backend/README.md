# MediSync Backend

A Node.js/Express backend for the MediSync pharmacy network management system.

## 📁 Project Structure

```
backend/
├── app.js                    # Main Express application
├── .env                      # Environment variables
├── .gitignore               # Git ignore rules
├── package.json             # Dependencies
├── SCHEMA.md                # Database schema documentation
└── src/
    ├── db/
    │   └── mongoose.js      # MongoDB connection
    ├── models/              # Mongoose models (13 models)
    │   ├── index.js         # Central export
    │   ├── Pharmacy.js
    │   ├── User.js
    │   ├── Category.js
    │   ├── Manufacturer.js
    │   ├── Product.js
    │   ├── Volume.js
    │   ├── HasVolume.js
    │   ├── StockShortage.js
    │   ├── StockExcess.js
    │   ├── Transaction.js
    │   ├── Notification.js
    │   ├── Review.js
    │   └── AuditLog.js
    ├── controllers/         # Business logic (empty - ready for next step)
    ├── middlewares/         # Auth, validation (empty - ready for next step)
    ├── helpers/             # Utility functions (empty - ready for next step)
    └── config/              # Configuration files (empty - ready for next step)
```

## 🚀 Getting Started

### Prerequisites
- Node.js (v14 or higher)
- MongoDB (local or cloud instance)

### Installation

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables in `.env`:
```env
MONGODB_URI=mongodb://localhost:27017/MediSync
PORT=5000
JWT_SECRET=your_jwt_secret_key_change_this_in_production
```

3. Start MongoDB (if running locally):
```bash
# Windows
net start MongoDB

# macOS/Linux
sudo systemctl start mongod
```

4. Run the server:
```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

## 📊 Database Models

The system includes 13 models:

1. **Pharmacy** - Registered pharmacies with verification and ratings
2. **User** - System users (admin, owners, staff) with authentication
3. **Category** - Hierarchical product categories
4. **Manufacturer** - Product manufacturers
5. **Product** - Pharmaceutical products with unit conversions
6. **Volume** - Unit types (Box, Strip, Tablet, etc.)
7. **HasVolume** - Product-volume combinations with pricing
8. **StockShortage** - Pharmacy shortage requests
9. **StockExcess** - Pharmacy excess offers
10. **Transaction** - Shortage fulfillment records
11. **Notification** - User notifications
12. **Review** - Pharmacy ratings and reviews
13. **AuditLog** - Compliance and security tracking

See [SCHEMA.md](./SCHEMA.md) for detailed documentation.

## 🔧 API Endpoints (To Be Implemented)

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/forgot-password` - Request password reset
- `POST /api/auth/reset-password` - Reset password

### Pharmacies
- `GET /api/pharmacies` - List all pharmacies
- `GET /api/pharmacies/:id` - Get pharmacy details
- `POST /api/pharmacies` - Register new pharmacy
- `PUT /api/pharmacies/:id` - Update pharmacy
- `PATCH /api/pharmacies/:id/verify` - Verify pharmacy (admin)

### Products
- `GET /api/products` - List all products
- `GET /api/products/:id` - Get product details
- `POST /api/products` - Create product (admin)
- `PUT /api/products/:id` - Update product (admin)

### Stock Management
- `GET /api/shortages` - List shortages
- `POST /api/shortages` - Create shortage
- `GET /api/excesses` - List excesses
- `POST /api/excesses` - Create excess
- `PATCH /api/excesses/:id/accept` - Accept excess (admin)

### Transactions
- `GET /api/transactions` - List transactions
- `POST /api/transactions` - Create transaction
- `PATCH /api/transactions/:id/status` - Update transaction status

### Reviews
- `GET /api/reviews` - List reviews
- `POST /api/reviews` - Create review

### Notifications
- `GET /api/notifications` - Get user notifications
- `PATCH /api/notifications/:id/read` - Mark as read

## 🔐 Security Features

- Password hashing with bcrypt
- JWT authentication with refresh tokens
- Role-based access control (admin, pharmacy_owner, pharmacy_staff)
- Audit logging for compliance
- Input validation and sanitization (to be implemented)

## 📝 Next Steps

1. ✅ Database schema design
2. ✅ Mongoose models creation
3. ⏳ Authentication middleware
4. ⏳ Controllers implementation
5. ⏳ API routes
6. ⏳ Validation middleware
7. ⏳ Error handling
8. ⏳ API documentation (Swagger)
9. ⏳ Unit tests
10. ⏳ Integration with Flutter frontend

## 🤝 Contributing

This is a private project for pharmacy network management.

## 📄 License

Proprietary
