# AgriSupply UML Explanation Guide (Updated to Current System)

## Purpose

This guide explains how each UML artifact maps to current code and runtime behavior.

## UML Artifacts Covered
- Use Case Diagram
- Context/DFD Level 0
- ERD
- Post-login Flowchart
- Login Wireframe
- Sequence Diagrams:
  - Register
  - Login
  - Browse/Search Products
  - Add to Cart
  - Checkout and Place Order
  - Payment (initiation + callbacks)
  - Order Tracking
  - Submit Review
  - Farmer Product Management
  - Farmer Fulfillment
  - Admin Moderation

---

## 1) Use Case Diagram

### What it should explain
- Who interacts with the system (Buyer, Farmer, Admin)
- Which features each actor can access

### Code mapping
- Role screens:
  - `mobile/lib/screens/buyer/`
  - `mobile/lib/screens/farmer/`
  - `mobile/lib/screens/admin/`
- Role checks on backend:
  - `backend/src/middleware/authMiddleware.js`
  - `requireFarmer`
  - `requireAdmin`
- Role-protected route groups:
  - `backend/src/routes/productRoutes.js`
  - `backend/src/routes/orderRoutes.js`
  - `backend/src/routes/adminRoutes.js`

### Success and failure path to mention
- Success: authenticated farmer calls `GET /products/my-products` and receives own inventory
- Failure: buyer calls farmer-only endpoint and receives authorization error

---

## 2) Context / DFD Level 0

### What it should explain
- External systems interacting with AgriSupply
- Top-level data movement between mobile app, backend, database, and third parties

### Code mapping
- System entry point: `backend/src/index.js`
- Domain processing: `backend/src/controllers/*.js`
- External integrations:
  - Supabase: auth + DB + storage clients
  - Payments: MarzPay, MTN, Airtel, Flutterwave callback handlers
  - AI: Groq-backed assistant and image analysis routes

### Key integration files
- `backend/src/routes/paymentRoutes.js`
- `backend/src/controllers/paymentController.js`
- `backend/src/services/marzpayService.js`
- `backend/src/routes/aiRoutes.js`
- `backend/src/controllers/aiController.js`

---

## 3) ERD (Entity Relationship Diagram)

### What it should explain
- Core tables/entities and their relationships for marketplace workflows

### Primary entities represented in current flows
- `users`
- `products`
- `orders`
- `order_items`
- `payments`
- `product_reviews`
- `notifications`
- `notification_preferences`
- `ai_chat_sessions`

### Source of truth
- `backend/database/schema.sql`

### Runtime usage mapping
- Order lifecycle and history logic: `backend/src/controllers/orderController.js`
- Product and reviews logic: `backend/src/controllers/productController.js`
- Payment transaction lifecycle: `backend/src/controllers/paymentController.js`
- Notification persistence and preferences: `backend/src/controllers/notificationController.js`
- AI session persistence: `backend/src/controllers/aiController.js`

---

## 4) Post-login Flowchart

### What it should explain
- Decision branch immediately after auth state resolves
- Role-based path to buyer/farmer/admin experiences

### Code mapping
- Auth/session bootstrap: `mobile/lib/providers/auth_provider.dart`
- Initial branching point: `mobile/lib/screens/splash_screen.dart`
- Route definitions: `mobile/lib/config/routes.dart`

### Path examples
- Buyer: home -> search -> product details -> cart -> checkout -> tracking
- Farmer: dashboard -> add/manage products -> process orders -> analytics
- Admin: dashboard -> user/product/order moderation -> reports

---

## 5) Login Wireframe

### What it should explain
- User input fields, auth actions, and transition points

### Frontend files
- `mobile/lib/screens/auth/login_screen.dart`
- `mobile/lib/screens/auth/register_screen.dart`
- `mobile/lib/screens/auth/forgot_password_screen.dart`
- `mobile/lib/screens/auth/otp_verification_screen.dart`

### State and service files
- `mobile/lib/providers/auth_provider.dart`
- `mobile/lib/services/auth_service.dart`

### Backend mapping
- `backend/src/routes/authRoutes.js`
- `backend/src/controllers/authController.js`

---

## 6) Sequence Diagram Explanations (Current)

Use this same explanation pattern for each sequence:
1. Trigger in UI
2. Provider/state action
3. Service/API call
4. Backend route + middleware chain
5. Controller business logic
6. Data updates
7. Response and UI refresh

### 6.1 Register sequence
- UI: `register_screen.dart`
- State/service: `auth_provider.dart`, `auth_service.dart`
- Backend: `POST /auth/register` in `authRoutes.js`
- Logic: `authController.register`

### 6.2 Login sequence
- UI: `login_screen.dart`
- State/service: `auth_provider.dart`, `auth_service.dart`
- Backend: `POST /auth/login`
- Logic: token/session + profile resolution and role-based navigation

### 6.3 Browse/search products sequence
- UI: `search_screen.dart`, `buyer_home_screen.dart`
- State/service: `product_provider.dart`, `product_service.dart`
- Backend: `GET /products`, `GET /products/search`
- Logic: filter/sort/pagination in product controller

### 6.4 Add to cart sequence
- UI: `product_detail_screen.dart`, `cart_screen.dart`
- State: `cart_provider.dart`
- Data: cart model updates and UI totals refresh

### 6.5 Checkout and place order sequence
- UI: `checkout_screen.dart`
- State/service: `order_provider.dart`, `order_service.dart`
- Backend: `POST /orders` (`authenticate + validators + controller`)
- Data effects: orders and order items records created

### 6.6 Payment sequence (initiation + callback)
- UI: `payment_methods_screen.dart`
- Service: `payment_service.dart`
- Backend initiation: `POST /payments/initiate`
- Callbacks: `/payments/mtn/callback`, `/payments/airtel/callback`, `/payments/marzpay/callback`, `/payments/card/callback`
- Integration: `paymentController.js` + `marzpayService.js`

### 6.7 Order tracking sequence
- UI: `order_tracking_screen.dart`
- Service: `order_service.dart`
- Backend: `GET /orders/:id/tracking`, `GET /orders/:id/history`

### 6.8 Submit review sequence
- UI: `product_detail_screen.dart`
- Service: `product_service.dart`
- Backend: `POST /products/:id/reviews`, update/delete review variants

### 6.9 Farmer product management sequence
- UI: `add_product_screen.dart`, `farmer_products_screen.dart`
- Service: `product_service.dart`
- Backend: `POST /products`, `PUT /products/:id`, image upload/delete routes

### 6.10 Farmer fulfillment sequence
- UI: `farmer_orders_screen.dart`
- Service: `order_service.dart`
- Backend: `POST /orders/:id/confirm`, `POST /orders/:id/ship`, `POST /orders/:id/deliver`, `PUT /orders/:id/status`

### 6.11 Admin moderation sequence
- UI: admin screens under `mobile/lib/screens/admin/`
- Backend: `backend/src/routes/adminRoutes.js`
- Examples: user moderation, product moderation, order updates, analytics, reports, broadcasts

---

## 7) Recommended explanation order in presentation/defense

1. Context/DFD Level 0
2. Use Case Diagram
3. ERD
4. Sequence diagrams (auth -> catalog -> order -> payment -> fulfillment -> admin)
5. Post-login Flowchart
6. Login Wireframe

---

## 8) Defense tips (high scoring format)

For each UML, always include:
- What question the UML answers
- Which concrete files implement it
- One happy-path runtime example
- One validation/error-path runtime example

This makes diagrams clearly tied to deployed code, not just theory.
