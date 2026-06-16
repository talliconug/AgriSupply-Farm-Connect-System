# AgriSupply Backend API

A comprehensive Node.js/Express backend API for the AgriSupply Farm Connect System - a digital agriculture marketplace connecting Ugandan farmers with buyers.

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [API Documentation](#api-documentation)
- [Database Setup](#database-setup)
- [Deployment](#deployment)
- [Project Structure](#project-structure)

## ✨ Features

### Authentication & Users
- Email/Password registration and login
- Google OAuth authentication
- Phone OTP verification (SMS)
- JWT token-based authentication
- Role-based access control (Buyer, Farmer, Admin)
- Profile management
- Premium subscriptions

### Products & Marketplace
- Full CRUD for products
- Advanced search and filtering
- Categories and sub-categories
- Product images (multiple)
- Reviews and ratings
- Favorites/Wishlist
- Featured products

### Orders & Payments
- Shopping cart functionality
- Order lifecycle management
- Multiple payment methods:
  - MTN Mobile Money
  - Airtel Money
  - Card payments (Flutterwave)
  - Cash on Delivery
- Order tracking
- Refunds processing

### AI Features (OpenAI Integration)
- Farming assistant chatbot
- Crop/plant image analysis
- Pest identification
- Disease diagnosis
- Market predictions
- Weather recommendations
- Personalized farming tips

### Admin Dashboard
- User management
- Product moderation
- Order management
- Analytics & reporting
- System settings
- Broadcast notifications

## 🛠 Tech Stack

- **Runtime:** Node.js 18+
- **Framework:** Express.js 4.18
- **Database:** Supabase (PostgreSQL)
- **Authentication:** Supabase Auth + JWT
- **File Storage:** Supabase Storage
- **AI:** OpenAI GPT-4
- **Payments:**
  - MTN Mobile Money API
  - Airtel Money API
  - Flutterwave API
- **Other:**
  - Winston (Logging)
  - Multer (File uploads)
  - Express Validator
  - Helmet (Security)
  - CORS
  - Rate Limiting

## 🚀 Getting Started

### Prerequisites

- Node.js 18 or higher
- npm or yarn
- Supabase account
- Payment provider accounts (MTN, Airtel, Flutterwave)
- OpenAI API key

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/agrisupply.git
cd agrisupply/backend
```

2. Install dependencies:
```bash
npm install
```

3. Create environment file:
```bash
cp .env.example .env
```

4. Configure environment variables (see below)

5. Set up the database:
```bash
# Run the schema in Supabase SQL Editor
# File: database/schema.sql

# Optionally run seed data
# File: database/seed.sql
```

6. Start the development server:
```bash
npm run dev
```

The server will start on `http://localhost:5000`

## 🔐 Environment Variables

Create a `.env` file in the root directory:

```env
# Server
NODE_ENV=development
PORT=5000

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# JWT
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
JWT_EXPIRES_IN=7d
JWT_REFRESH_EXPIRES_IN=30d

# OpenAI
OPENAI_API_KEY=sk-your-openai-api-key

# MTN Mobile Money
MTN_API_KEY=your-mtn-api-key
MTN_API_SECRET=your-mtn-api-secret
MTN_CALLBACK_URL=https://your-domain.com/api/v1/payments/mtn/callback
MTN_ENVIRONMENT=sandbox

# Airtel Money
AIRTEL_CLIENT_ID=your-airtel-client-id
AIRTEL_CLIENT_SECRET=your-airtel-client-secret
AIRTEL_CALLBACK_URL=https://your-domain.com/api/v1/payments/airtel/callback
AIRTEL_ENVIRONMENT=sandbox

# Flutterwave
FLUTTERWAVE_PUBLIC_KEY=your-flutterwave-public-key
FLUTTERWAVE_SECRET_KEY=your-flutterwave-secret-key
FLUTTERWAVE_WEBHOOK_SECRET=your-webhook-secret

# Firebase (Push Notifications)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY=your-firebase-private-key
FIREBASE_CLIENT_EMAIL=your-firebase-client-email

# SMS (EgoSMS)
SMS_SERVICE=egosms
EGOSMS_API_URL=https://your-egosms-endpoint
EGOSMS_USERNAME=your-username
EGOSMS_PASSWORD=your-password
EGOSMS_SENDER_ID=AgriSupply
```

## 📚 API Documentation

### Base URL
```
Development: http://localhost:5000/api/v1
Production: https://api.agrisupply.ug/api/v1
```

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register new user |
| POST | `/auth/login` | Login with email/phone |
| POST | `/auth/google` | Google OAuth login |
| POST | `/auth/phone/send-otp` | Send phone OTP |
| POST | `/auth/phone/verify` | Verify phone OTP |
| POST | `/auth/forgot-password` | Request password reset |
| POST | `/auth/reset-password` | Reset password |
| POST | `/auth/refresh-token` | Refresh access token |
| POST | `/auth/logout` | Logout user |

### User Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users/profile` | Get current user profile |
| PUT | `/users/profile` | Update profile |
| POST | `/users/profile/photo` | Upload profile photo |
| DELETE | `/users/profile/photo` | Delete profile photo |
| PUT | `/users/address` | Update address |
| GET | `/users/farmers` | List all farmers |
| GET | `/users/farmers/:id` | Get farmer profile |
| POST | `/users/farmers/:id/follow` | Follow farmer |
| DELETE | `/users/farmers/:id/follow` | Unfollow farmer |
| GET | `/users/statistics` | Get user statistics |

### Product Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/products` | List products (with filters) |
| GET | `/products/search` | Search products |
| GET | `/products/featured` | Get featured products |
| GET | `/products/categories` | Get all categories |
| GET | `/products/my-products` | Get farmer's products |
| GET | `/products/:id` | Get product details |
| POST | `/products` | Create product (farmer) |
| PUT | `/products/:id` | Update product |
| DELETE | `/products/:id` | Delete product |
| POST | `/products/:id/images` | Upload product images |
| DELETE | `/products/:id/images/:imageId` | Delete product image |
| GET | `/products/:id/reviews` | Get product reviews |
| POST | `/products/:id/reviews` | Add review |
| POST | `/products/:id/favorite` | Add to favorites |
| DELETE | `/products/:id/favorite` | Remove from favorites |
| GET | `/products/favorites` | Get user's favorites |

### Order Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/orders` | Get buyer's orders |
| GET | `/orders/farmer` | Get farmer's orders |
| GET | `/orders/:id` | Get order details |
| POST | `/orders` | Create new order |
| PUT | `/orders/:id/status` | Update order status |
| POST | `/orders/:id/confirm` | Confirm order (farmer) |
| POST | `/orders/:id/ship` | Mark as shipped |
| POST | `/orders/:id/deliver` | Mark as delivered |
| POST | `/orders/:id/cancel` | Cancel order |
| POST | `/orders/:id/refund` | Request refund |
| GET | `/orders/:id/tracking` | Get tracking info |
| GET | `/orders/statistics` | Get order statistics |

### Payment Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/payments/initiate` | Initiate payment |
| GET | `/payments/:id/status` | Get payment status |
| POST | `/payments/mtn/callback` | MTN callback |
| POST | `/payments/airtel/callback` | Airtel callback |
| POST | `/payments/card/callback` | Card callback |
| POST | `/payments/:id/verify` | Verify payment |
| POST | `/payments/:id/retry` | Retry payment |
| GET | `/payments/methods` | Get payment methods |
| POST | `/payments/:id/refund` | Process refund |
| GET | `/payments/history` | Get payment history |

### AI Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/ai/chat` | Chat with AI assistant |
| POST | `/ai/analyze-image` | Analyze crop image |
| GET | `/ai/sessions` | Get chat sessions |
| GET | `/ai/sessions/:id` | Get chat session |
| DELETE | `/ai/sessions/:id` | Delete session |
| POST | `/ai/crop-analysis` | Get crop analysis |
| GET | `/ai/farming-tips` | Get farming tips |
| GET | `/ai/market-predictions` | Get market predictions |
| GET | `/ai/weather-recommendations` | Weather advice |
| POST | `/ai/pest-identification` | Identify pest |
| POST | `/ai/disease-diagnosis` | Diagnose disease |
| GET | `/ai/usage` | Get AI usage stats |

### Admin Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/dashboard` | Get dashboard stats |
| GET | `/admin/users` | List all users |
| GET | `/admin/users/:id` | Get user details |
| PUT | `/admin/users/:id` | Update user |
| POST | `/admin/users/:id/verify` | Verify user |
| POST | `/admin/users/:id/suspend` | Suspend user |
| POST | `/admin/users/:id/unsuspend` | Unsuspend user |
| DELETE | `/admin/users/:id` | Delete user |
| GET | `/admin/products` | List all products |
| PUT | `/admin/products/:id` | Update product |
| DELETE | `/admin/products/:id` | Delete product |
| GET | `/admin/orders` | List all orders |
| PUT | `/admin/orders/:id` | Update order |
| GET | `/admin/payments` | List all payments |
| POST | `/admin/payments/:id/refund` | Process refund |
| GET | `/admin/analytics/sales` | Sales analytics |
| GET | `/admin/analytics/users` | User analytics |
| GET | `/admin/analytics/products` | Product analytics |
| GET | `/admin/analytics/regional` | Regional analytics |
| POST | `/admin/notifications/broadcast` | Send broadcast |
| GET | `/admin/reports/export` | Export reports |
| GET | `/admin/settings` | Get settings |
| PUT | `/admin/settings` | Update settings |

### Notification Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications` | Get notifications |
| GET | `/notifications/unread/count` | Get unread count |
| GET | `/notifications/:id` | Get notification |
| PUT | `/notifications/:id/read` | Mark as read |
| PUT | `/notifications/read-all` | Mark all as read |
| DELETE | `/notifications/:id` | Delete notification |
| DELETE | `/notifications` | Delete all |
| GET | `/notifications/preferences` | Get preferences |
| PUT | `/notifications/preferences` | Update preferences |
| POST | `/notifications/devices` | Register device |
| DELETE | `/notifications/devices/:token` | Unregister device |

## 💾 Database Setup

### Using Supabase

1. Create a new Supabase project at [supabase.com](https://supabase.com)

2. Go to SQL Editor and run the schema:
```sql
-- Copy contents of database/schema.sql and execute
```

3. (Optional) Run seed data:
```sql
-- Copy contents of database/seed.sql and execute
```

4. Configure Storage buckets:
- Go to Storage in Supabase Dashboard
- Create buckets: `profile-photos`, `product-images`, `review-images`, `ai-images`, `documents`
- Set appropriate RLS policies

### Database Tables

| Table | Description |
|-------|-------------|
| users | User accounts and profiles |
| products | Product listings |
| orders | Customer orders |
| order_items | Items in orders |
| order_status_history | Order status changes |
| payments | Payment transactions |
| refunds | Refund records |
| notifications | User notifications |
| notification_preferences | Notification settings |
| user_devices | Push notification devices |
| product_reviews | Product reviews |
| product_favorites | User favorites |
| farmer_followers | Farmer-follower relationships |
| ai_chat_sessions | AI chat history |
| ai_usage | AI usage tracking |
| cart_items | Shopping cart |
| system_settings | App configuration |
| farmer_payouts | Farmer earnings |

## 🚢 Deployment

### Using Railway

1. Connect your GitHub repository
2. Add environment variables
3. Deploy

### Using Render

1. Create new Web Service
2. Connect repository
3. Set build command: `npm install`
4. Set start command: `npm start`
5. Add environment variables

### Using Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
```

## 📁 Project Structure

```
backend/
├── database/
│   ├── schema.sql          # Database schema
│   └── seed.sql            # Seed data
├── src/
│   ├── config/
│   │   ├── supabase.js     # Supabase client
│   │   └── constants.js    # App constants
│   ├── controllers/
│   │   ├── adminController.js
│   │   ├── aiController.js
│   │   ├── authController.js
│   │   ├── notificationController.js
│   │   ├── orderController.js
│   │   ├── paymentController.js
│   │   ├── productController.js
│   │   └── userController.js
│   ├── middleware/
│   │   ├── authMiddleware.js
│   │   ├── errorMiddleware.js
│   │   └── uploadMiddleware.js
│   ├── routes/
│   │   ├── adminRoutes.js
│   │   ├── aiRoutes.js
│   │   ├── authRoutes.js
│   │   ├── notificationRoutes.js
│   │   ├── orderRoutes.js
│   │   ├── paymentRoutes.js
│   │   ├── productRoutes.js
│   │   └── userRoutes.js
│   ├── utils/
│   │   ├── helpers.js
│   │   ├── logger.js
│   │   └── validators.js
│   └── index.js            # Entry point
├── .env.example
├── package.json
└── README.md
```

## 📞 Support

For support, email support@agrisupply.ug or join our Slack channel.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Made with ❤️ for Ugandan Farmers
