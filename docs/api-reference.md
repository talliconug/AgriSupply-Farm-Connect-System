# AgriSupply API Reference (Current System)

This document uses endpoint definitions in this format:
- Endpoint
- Auth
- Role
- Body example (when applicable)

Base URL:
- Production: `https://agrisupply-farm-connect-system.onrender.com/api/v1`
- Local: `http://localhost:3000/api/v1`

Common response shape:

```json
{
	"success": true,
	"message": "Optional message",
	"data": {}
}
```

---

## 1) Authentication APIs

### 1.1 Register user
- Endpoint: `POST /auth/register`
- auth: none
- role: farmer or buyer
- Body example:

```json
{
	"email": "farmer@example.com",
	"password": "StrongPass123",
	"fullName": "Amina Nanteza",
	"phone": "+256700123456",
	"role": "farmer"
}
```

### 1.2 Login
- Endpoint: `POST /auth/login`
- auth: none
- role: farmer, buyer, or admin
- Body example:

```json
{
	"email": "farmer@example.com",
	"password": "StrongPass123"
}
```

### 1.3 Google auth
- Endpoint: `POST /auth/google`
- auth: none
- role: farmer or buyer
- Body example:

```json
{
	"idToken": "google-id-token"
}
```

### 1.4 Send phone OTP
- Endpoint: `POST /auth/phone/send-otp`
- auth: none
- role: farmer or buyer
- Body example:

```json
{
	"phone": "+256700123456"
}
```

### 1.5 Verify phone OTP
- Endpoint: `POST /auth/phone/verify-otp`
- auth: none
- role: farmer or buyer
- Body example:

```json
{
	"phone": "+256700123456",
	"otp": "123456"
}
```

### 1.6 Forgot password
- Endpoint: `POST /auth/forgot-password`
- auth: none
- role: any
- Body example:

```json
{
	"email": "farmer@example.com"
}
```

### 1.7 Reset password
- Endpoint: `POST /auth/reset-password`
- auth: none
- role: any

### 1.8 Refresh token
- Endpoint: `POST /auth/refresh-token`
- auth: none
- role: any

### 1.9 Logout
- Endpoint: `POST /auth/logout`
- auth: bearer token
- role: farmer, buyer, or admin

### 1.10 Update password
- Endpoint: `PUT /auth/password`
- auth: bearer token
- role: farmer, buyer, or admin
- Body example:

```json
{
	"currentPassword": "StrongPass123",
	"newPassword": "NewStrongPass123"
}
```

### 1.11 Current user
- Endpoint: `GET /auth/me`
- auth: bearer token
- role: farmer, buyer, or admin

### 1.12 Delete account
- Endpoint: `DELETE /auth/account`
- auth: bearer token
- role: farmer, buyer, or admin

---

## 2) User APIs

### 2.1 Get profile
- Endpoint: `GET /users/profile`
- auth: bearer token
- role: farmer, buyer, or admin

### 2.2 Update profile
- Endpoint: `PUT /users/profile`
- auth: bearer token
- role: farmer, buyer, or admin
- Body example:

```json
{
	"fullName": "Updated Name",
	"phone": "+256700000001",
	"region": "Central",
	"bio": "Farmer from Wakiso"
}
```

### 2.3 Upload profile photo
- Endpoint: `POST /users/profile/photo`
- auth: bearer token
- role: farmer, buyer, or admin
- Body type: multipart/form-data (`photo`)

### 2.4 Delete profile photo
- Endpoint: `DELETE /users/profile/photo`
- auth: bearer token
- role: farmer, buyer, or admin

### 2.5 Update address
- Endpoint: `PUT /users/address`
- auth: bearer token
- role: farmer, buyer, or admin
- Body example:

```json
{
	"region": "Central",
	"district": "Wakiso",
	"address": "Kira Road Plot 12"
}
```

### 2.6 List farmers
- Endpoint: `GET /users/farmers`
- auth: optional
- role: public

### 2.7 Get farmer profile
- Endpoint: `GET /users/farmers/:id`
- auth: optional
- role: public

### 2.8 Farmer analytics
- Endpoint: `GET /users/farmers/:id/analytics`
- auth: bearer token
- role: farmer, buyer, or admin

### 2.9 Follow farmer
- Endpoint: `POST /users/farmers/:id/follow`
- auth: bearer token
- role: buyer or farmer

### 2.10 Unfollow farmer
- Endpoint: `DELETE /users/farmers/:id/follow`
- auth: bearer token
- role: buyer or farmer

### 2.11 Following list
- Endpoint: `GET /users/following`
- auth: bearer token
- role: buyer or farmer

### 2.12 Followers list
- Endpoint: `GET /users/followers`
- auth: bearer token
- role: farmer

### 2.13 User statistics
- Endpoint: `GET /users/statistics`
- auth: bearer token
- role: farmer, buyer, or admin

---

## 3) Product APIs

### 3.1 Get products
- Endpoint: `GET /products`
- auth: optional
- role: public

### 3.2 Search products
- Endpoint: `GET /products/search`
- auth: optional
- role: public

### 3.3 Featured products
- Endpoint: `GET /products/featured`
- auth: optional
- role: public

### 3.4 Product categories
- Endpoint: `GET /products/categories`
- auth: none
- role: public

### 3.5 Get my products
- Endpoint: `GET /products/my-products`
- auth: bearer token
- role: farmer

### 3.6 Get product by ID
- Endpoint: `GET /products/:id`
- auth: optional
- role: public

### 3.7 Create product
- Endpoint: `POST /products`
- auth: bearer token
- role: farmer
- Body example:

```json
{
	"name": "Fresh Tomatoes",
	"description": "Organic tomatoes",
	"category": "vegetables",
	"price": 3500,
	"unit": "kg",
	"quantity": 80,
	"isOrganic": true
}
```

### 3.8 Update product
- Endpoint: `PUT /products/:id`
- auth: bearer token
- role: farmer (owner)

### 3.9 Add product images
- Endpoint: `POST /products/:id/images`
- auth: bearer token
- role: farmer (owner)
- Body type: multipart/form-data (`images`)

### 3.10 Delete product image
- Endpoint: `DELETE /products/:id/images/:imageIndex`
- auth: bearer token
- role: farmer (owner)

### 3.11 Delete product
- Endpoint: `DELETE /products/:id`
- auth: bearer token
- role: farmer (owner)

### 3.12 Get product reviews
- Endpoint: `GET /products/:id/reviews`
- auth: none
- role: public

### 3.13 Add review
- Endpoint: `POST /products/:id/reviews`
- auth: bearer token
- role: buyer or farmer
- Body example:

```json
{
	"rating": 5,
	"comment": "Excellent quality"
}
```

### 3.14 Update review
- Endpoint: `PUT /products/:id/reviews/:reviewId`
- auth: bearer token
- role: review owner

### 3.15 Delete review
- Endpoint: `DELETE /products/:id/reviews/:reviewId`
- auth: bearer token
- role: review owner

### 3.16 Add to favorites
- Endpoint: `POST /products/:id/favorite`
- auth: bearer token
- role: buyer or farmer

### 3.17 Remove from favorites
- Endpoint: `DELETE /products/:id/favorite`
- auth: bearer token
- role: buyer or farmer

### 3.18 Get favorites
- Endpoint: `GET /products/favorites/list`
- auth: bearer token
- role: buyer or farmer

---

## 4) Order APIs

### 4.1 Get my orders
- Endpoint: `GET /orders`
- auth: bearer token
- role: buyer

### 4.2 Get farmer orders
- Endpoint: `GET /orders/farmer`
- auth: bearer token
- role: farmer

### 4.3 Get order by ID
- Endpoint: `GET /orders/:id`
- auth: bearer token
- role: order owner, related farmer, or admin

### 4.4 Create order
- Endpoint: `POST /orders`
- auth: bearer token
- role: buyer
- Body example:

```json
{
	"items": [
		{ "productId": "<uuid>", "quantity": 2 }
	],
	"deliveryAddress": "Kampala, Ntinda",
	"paymentMethod": "marzpay"
}
```

### 4.5 Update order status
- Endpoint: `PUT /orders/:id/status`
- auth: bearer token
- role: farmer or admin

### 4.6 Confirm order
- Endpoint: `POST /orders/:id/confirm`
- auth: bearer token
- role: farmer

### 4.7 Ship order
- Endpoint: `POST /orders/:id/ship`
- auth: bearer token
- role: farmer

### 4.8 Deliver order
- Endpoint: `POST /orders/:id/deliver`
- auth: bearer token
- role: farmer or admin

### 4.9 Cancel order
- Endpoint: `POST /orders/:id/cancel`
- auth: bearer token
- role: order owner, related farmer, or admin

### 4.10 Request refund
- Endpoint: `POST /orders/:id/refund`
- auth: bearer token
- role: order owner

### 4.11 Tracking
- Endpoint: `GET /orders/:id/tracking`
- auth: bearer token
- role: order owner, related farmer, or admin

### 4.12 Order history
- Endpoint: `GET /orders/:id/history`
- auth: bearer token
- role: order owner, related farmer, or admin

### 4.13 Order statistics summary
- Endpoint: `GET /orders/statistics/summary`
- auth: bearer token
- role: farmer, buyer, or admin

---

## 5) Payment APIs

### 5.1 Initiate payment
- Endpoint: `POST /payments/initiate`
- auth: bearer token
- role: buyer
- Body example:

```json
{
	"orderId": "<order-id>",
	"method": "mtn_mobile",
	"phone": "+256700123456"
}
```

### 5.2 Payment status
- Endpoint: `GET /payments/:orderId/status`
- auth: bearer token
- role: buyer, farmer, or admin

### 5.3 MTN callback
- Endpoint: `POST /payments/mtn/callback`
- auth: none
- role: webhook provider

### 5.4 Airtel callback
- Endpoint: `POST /payments/airtel/callback`
- auth: none
- role: webhook provider

### 5.5 MarzPay callback
- Endpoint: `POST /payments/marzpay/callback`
- auth: none
- role: webhook provider

### 5.6 Validate phone
- Endpoint: `POST /payments/validate-phone`
- auth: bearer token
- role: buyer

### 5.7 Wallet balance
- Endpoint: `GET /payments/wallet-balance`
- auth: bearer token
- role: admin

### 5.8 MarzPay transactions
- Endpoint: `GET /payments/marzpay-transactions`
- auth: bearer token
- role: admin

### 5.9 Card callback
- Endpoint: `POST /payments/card/callback`
- auth: none
- role: webhook provider

### 5.10 Verify payment
- Endpoint: `GET /payments/verify/:transactionId`
- auth: bearer token
- role: buyer, farmer, or admin

### 5.11 Retry payment
- Endpoint: `POST /payments/:orderId/retry`
- auth: bearer token
- role: buyer

### 5.12 Process refund
- Endpoint: `POST /payments/:orderId/refund`
- auth: bearer token
- role: admin

### 5.13 Payment methods
- Endpoint: `GET /payments/methods`
- auth: none
- role: public

### 5.14 Payment history
- Endpoint: `GET /payments/history`
- auth: bearer token
- role: buyer, farmer, or admin

---

## 6) Notification APIs

### 6.1 Get notifications
- Endpoint: `GET /notifications`
- auth: bearer token
- role: farmer, buyer, or admin

### 6.2 Unread count
- Endpoint: `GET /notifications/unread-count`
- auth: bearer token
- role: farmer, buyer, or admin

### 6.3 Get notification by ID
- Endpoint: `GET /notifications/:id`
- auth: bearer token
- role: owner

### 6.4 Mark as read
- Endpoint: `PUT /notifications/:id/read`
- auth: bearer token
- role: owner

### 6.5 Mark all read
- Endpoint: `PUT /notifications/read-all`
- auth: bearer token
- role: owner

### 6.6 Delete notification
- Endpoint: `DELETE /notifications/:id`
- auth: bearer token
- role: owner

### 6.7 Delete all notifications
- Endpoint: `DELETE /notifications`
- auth: bearer token
- role: owner

### 6.8 Get preferences
- Endpoint: `GET /notifications/preferences`
- auth: bearer token
- role: owner

### 6.9 Update preferences
- Endpoint: `PUT /notifications/preferences`
- auth: bearer token
- role: owner

### 6.10 Register device
- Endpoint: `POST /notifications/register-device`
- auth: bearer token
- role: owner

### 6.11 Unregister device
- Endpoint: `DELETE /notifications/unregister-device`
- auth: bearer token
- role: owner

---

## 7) AI APIs

### 7.1 Chat
- Endpoint: `POST /ai/chat`
- auth: bearer token
- role: farmer, buyer, or admin
- Body example:

```json
{
	"message": "How do I manage maize pests this season?"
}
```

### 7.2 Analyze image
- Endpoint: `POST /ai/analyze-image`
- auth: bearer token
- role: farmer, buyer, or admin
- Body type: multipart/form-data (`image`)

### 7.3 Get sessions
- Endpoint: `GET /ai/sessions`
- auth: bearer token
- role: farmer, buyer, or admin

### 7.4 Get session by ID
- Endpoint: `GET /ai/sessions/:sessionId`
- auth: bearer token
- role: owner

### 7.5 Delete session
- Endpoint: `DELETE /ai/sessions/:sessionId`
- auth: bearer token
- role: owner

### 7.6 Crop analysis
- Endpoint: `POST /ai/crop-analysis`
- auth: bearer token
- role: farmer, buyer, or admin

### 7.7 Farming tips
- Endpoint: `GET /ai/farming-tips`
- auth: bearer token
- role: farmer, buyer, or admin

### 7.8 Market predictions
- Endpoint: `GET /ai/market-predictions`
- auth: bearer token
- role: farmer, buyer, or admin

### 7.9 Weather recommendations
- Endpoint: `GET /ai/weather-recommendations`
- auth: bearer token
- role: farmer, buyer, or admin

### 7.10 Pest identification
- Endpoint: `POST /ai/pest-identification`
- auth: bearer token
- role: farmer, buyer, or admin
- Body type: multipart/form-data (`image`)

### 7.11 Disease diagnosis
- Endpoint: `POST /ai/disease-diagnosis`
- auth: bearer token
- role: farmer, buyer, or admin
- Body type: multipart/form-data (`image`)

### 7.12 Usage stats
- Endpoint: `GET /ai/usage`
- auth: bearer token
- role: farmer, buyer, or admin

---

## 8) Admin APIs

All endpoints below:
- auth: bearer token
- role: admin

### 8.1 Dashboard
- Endpoint: `GET /admin/dashboard`

### 8.2 User list
- Endpoint: `GET /admin/users`

### 8.3 Get user by ID
- Endpoint: `GET /admin/users/:id`

### 8.4 Update user
- Endpoint: `PUT /admin/users/:id`

### 8.5 Verify user
- Endpoint: `POST /admin/users/:id/verify`

### 8.6 Suspend user
- Endpoint: `POST /admin/users/:id/suspend`

### 8.7 Unsuspend user
- Endpoint: `POST /admin/users/:id/unsuspend`

### 8.8 Delete user
- Endpoint: `DELETE /admin/users/:id`

### 8.9 Product list
- Endpoint: `GET /admin/products`

### 8.10 Update product
- Endpoint: `PUT /admin/products/:id`

### 8.11 Delete product
- Endpoint: `DELETE /admin/products/:id`

### 8.12 Order list
- Endpoint: `GET /admin/orders`

### 8.13 Update order
- Endpoint: `PUT /admin/orders/:id`

### 8.14 Payment list
- Endpoint: `GET /admin/payments`

### 8.15 Refund payment
- Endpoint: `POST /admin/payments/:id/refund`

### 8.16 Sales analytics
- Endpoint: `GET /admin/analytics/sales`

### 8.17 User analytics
- Endpoint: `GET /admin/analytics/users`

### 8.18 Product analytics
- Endpoint: `GET /admin/analytics/products`

### 8.19 Regional analytics
- Endpoint: `GET /admin/analytics/regions`

### 8.20 Broadcast notification
- Endpoint: `POST /admin/notifications/broadcast`

### 8.21 Export reports
- Endpoint: `GET /admin/reports/export`

### 8.22 Get settings
- Endpoint: `GET /admin/settings`

### 8.23 Update settings
- Endpoint: `PUT /admin/settings`

---

## Validation notes
- Most `:id` parameters require UUID format.
- Phone format expects Uganda numbers (`+2567XXXXXXXX` or `07XXXXXXXX`).
- Protected routes require `Authorization: Bearer <JWT>`.
