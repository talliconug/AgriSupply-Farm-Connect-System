# AgriSupply Deep File Walkthrough

This walkthrough reflects the current implementation in this repository and follows real runtime flow.

## 1. Backend Runtime Entry

## 1.1 backend/src/index.js
Backend bootstrap and route mounting.

What it does:
1. Loads environment variables and creates the Express app.
2. Configures Helmet, CORS, compression, Morgan logging, body parsing, and global rate limiting.
3. Mounts all route groups under /api/{version}/*.
4. Exposes /health and / welcome endpoints.
5. Applies catch-all 404 and global error middleware.
6. Starts the HTTP listener and configures graceful shutdown handlers.

## 1.2 backend/src/middleware/authMiddleware.js
JWT/session middleware and role gates.

What it does:
1. Extracts Bearer token from Authorization header.
2. Verifies token against Supabase auth via getUserFromToken.
3. Loads the user profile from users and blocks suspended users.
4. Attaches req.user and req.token.
5. Restricts route access with requireAdmin, requireFarmer, requirePremium, and requireVerified.

## 1.3 backend/src/middleware/errorMiddleware.js
Central error response middleware.

What it does:
1. Defines ApiError for explicit HTTP failures.
2. Normalizes Supabase, JWT, validation, and multer errors.
3. Returns consistent JSON shape: { success: false, error: { message, ... } }.
4. Exposes asyncHandler and handleValidation helpers used by route files.

## 2. Backend Configuration Layer

## 2.1 backend/src/config/supabase.js
Supabase client initialization and helper wrappers.

What it does:
1. Creates service-role and anon clients.
2. Exposes token-to-user lookup helpers.
3. Exposes role checks (admin/farmer) and storage helpers.

## 2.2 backend/src/config/constants.js
Domain constants and AI model defaults.

What it does:
1. Holds product categories, validation constants, and cache/limit values.
2. Holds Groq model defaults and system prompt configuration used by AI controller.

## 2.3 backend/src/utils/validators.js
Request validation definitions (express-validator).

What it does:
1. Defines auth/product/order/payment/admin/notification validation rules.
2. Works with handleValidation to reject invalid requests before controller execution.

## 3. Auth and User Lifecycle

## 3.1 backend/src/routes/authRoutes.js
Auth endpoint layer.

What it does:
1. Exposes register/login/google/phone OTP/password/reset/refresh/logout/me/account endpoints.
2. Applies validator chains and authenticate where needed.

## 3.2 backend/src/controllers/authController.js
Auth orchestration and profile bootstrap.

What it does:
1. Creates users through Supabase auth admin APIs.
2. Loads/creates users profile rows and notification_preferences.
3. Handles login, token refresh, OTP verification, and password flows.
4. Updates last_login_at and checks suspension status in runtime auth flow.

## 3.3 backend/src/routes/userRoutes.js
User profile and farmer relationship endpoints.

What it does:
1. Exposes profile CRUD-like actions and profile photo upload.
2. Exposes farmer discovery, follow/unfollow, and user statistics endpoints.

## 4. Product and Catalog Lifecycle

## 4.1 backend/src/routes/productRoutes.js
Public and farmer product operations.

What it does:
1. Serves listing/search/featured/category endpoints for buyers.
2. Serves my-products and CRUD endpoints for farmers.
3. Handles product image upload endpoints.
4. Exposes reviews and favorites endpoints.

## 4.2 backend/src/controllers/productController.js
Product business logic and filtering.

What it does:
1. Builds filtered/paginated product queries.
2. Handles farmer-owned product create/update/delete with ownership checks.
3. Manages reviews and rating-related data updates.

## 5. Order Lifecycle

## 5.1 backend/src/routes/orderRoutes.js
Buyer/farmer/admin order endpoint layer.

What it does:
1. Exposes buyer order listing and per-order details.
2. Exposes order creation endpoint.
3. Exposes status transitions (confirm, ship, deliver, cancel, refund request).
4. Exposes tracking/history/statistics reads.

## 5.2 backend/src/controllers/orderController.js
Order orchestration.

What it does:
1. Normalizes mobile and web delivery address formats.
2. Validates stock and computes subtotal plus delivery fee.
3. Creates orders and order_items.
4. Updates product quantities and appends order_status_history.
5. Inserts notifications for farmers/buyers during status transitions.

## 6. Payment Lifecycle (MarzPay Primary)

## 6.1 backend/src/routes/paymentRoutes.js
Payment endpoint layer.

What it does:
1. Exposes initiation/status/verify/retry/history endpoints.
2. Exposes provider callback endpoints (MarzPay, MTN, Airtel, card).
3. Exposes phone validation plus wallet/transaction reads.

## 6.2 backend/src/controllers/paymentController.js
Payment orchestration and callback transitions.

What it does:
1. Validates payment requests and confirms order ownership.
2. Routes initiation by method (marzpay, mtn_mobile, airtel_money, card, cash_on_delivery).
3. Persists payments rows and updates orders.payment_status.
4. Processes webhook callbacks and maps provider statuses to local statuses.
5. Verifies pending transactions and supports refunds.
6. Adds payment success/failure/refund notifications.

## 6.3 backend/src/services/marzpayService.js
MarzPay HTTP client wrapper.

What it does:
1. Builds Basic auth header from API key and secret.
2. Sends collect-money/send-money requests.
3. Provides transaction status, history, and wallet balance methods.
4. Normalizes and validates Uganda MTN/Airtel numbers.

## 7. Notifications Lifecycle

## 7.1 backend/src/routes/notificationRoutes.js
Authenticated notification read/update APIs.

What it does:
1. Lists notifications with pagination and unread counts.
2. Marks single/all notifications as read.
3. Supports delete operations and preference/device registration endpoints.

## 7.2 backend/src/controllers/notificationController.js
Notification persistence and preference management.

What it does:
1. Reads/writes notifications rows.
2. Creates default notification_preferences when missing.
3. Registers user_devices for push routing.
4. Exposes helper functions for single/bulk notification inserts.

## 8. AI Assistant Lifecycle

## 8.1 backend/src/routes/aiRoutes.js
AI endpoint layer.

What it does:
1. Exposes chat, image analysis, crop analysis, market/weather insight endpoints.
2. Exposes AI session CRUD and usage endpoints.

## 8.2 backend/src/controllers/aiController.js
Groq-powered AI orchestration.

What it does:
1. Initializes OpenAI-compatible Groq client.
2. Stores/retrieves ai_chat_sessions.
3. Sends text and multimodal prompts.
4. Tracks ai_usage token consumption.

## 9. Mobile App Runtime

## 9.1 mobile/lib/main.dart
Flutter app entry and provider wiring.

What it does:
1. Initializes Flutter bindings and orientation lock.
2. Initializes Supabase.
3. Registers app providers and route generation.

## 9.2 mobile/lib/services/api_service.dart
Network and Supabase gateway used by mobile services.

What it does:
1. Uses production base URL from AppConfig.apiBaseUrl.
2. Injects Authorization header from Supabase session token.
3. Provides generic REST methods for backend endpoints.
4. Also provides direct Supabase table/storage helpers used by several services.

## 9.3 Mobile Service Layer

Primary files:
1. mobile/lib/services/auth_service.dart
2. mobile/lib/services/product_service.dart
3. mobile/lib/services/order_service.dart
4. mobile/lib/services/payment_service.dart
5. mobile/lib/services/notification_service.dart
6. mobile/lib/services/ai_service.dart

What services do:
1. Wrap backend REST calls for major flows (auth/orders/payments/products).
2. In several places, perform direct Supabase table calls.
3. Normalize payloads and map response JSON into typed models.

## 9.4 Provider Layer

Current providers:
1. mobile/lib/providers/auth_provider.dart
2. mobile/lib/providers/product_provider.dart
3. mobile/lib/providers/order_provider.dart
4. mobile/lib/providers/cart_provider.dart
5. mobile/lib/providers/notification_provider.dart
6. mobile/lib/providers/user_provider.dart

What providers do:
1. Hold screen state (loading/error/data lists/selection).
2. Invoke services and expose updates via notifyListeners().

## 9.5 Screen Layer

Main screen groups:
1. mobile/lib/screens/auth/*
2. mobile/lib/screens/buyer/*
3. mobile/lib/screens/farmer/*
4. mobile/lib/screens/admin/*
5. mobile/lib/screens/common/*
6. mobile/lib/screens/splash_screen.dart

## 10. Database Files and Runtime Effects

## 10.1 backend/database/schema.sql
Core relational model and many triggers/policies.

Runtime effect:
1. Defines core tables (users, products, orders, order_items, payments, notifications, reviews, favorites, AI/session, cart, settings, payouts, refunds).
2. Defines trigger-based profile creation from auth.users insert.
3. Defines ratings/follower counters and RLS policy baselines.

## 10.2 backend/database/manual_fix.sql
Production support patch for profile trigger/policies.

Runtime effect:
1. Rebuilds handle_new_user trigger function and policy conditions.
2. Intended to fix profile creation edge cases during signup.

## 10.3 backend/database/setup_storage.sql
Supabase Storage bucket and policy setup.

Runtime effect:
1. Creates media buckets used by profile/product/review/AI uploads.
2. Defines storage access policies for public/authenticated access paths.

## 10.4 backend/database/seed.sql
Development data seed set.

Runtime effect:
1. Inserts sample admin/farmer/buyer users and sample catalog content.

## 11. End-to-End Runtime Paths

## 11.1 Common Buyer Journey
1. Buyer signs in or registers via /api/v1/auth/*.
2. Buyer browses products via /api/v1/products and /api/v1/products/search.
3. Buyer places order via /api/v1/orders.
4. Buyer initiates payment via /api/v1/payments/initiate.
5. Callback/verification updates payment and order payment_status.
6. Farmers process order state transitions; buyer receives notifications.

## 11.2 Common Farmer Journey
1. Farmer signs in and creates products via /api/v1/products.
2. Farmer receives order notifications and opens /api/v1/orders/farmer.
3. Farmer confirms/ships/delivers via order status endpoints.
4. Buyer-facing notifications and history are updated throughout.

## 12. Current Runtime Notes
1. Backend is versioned under /api/v1.
2. MarzPay is the primary mobile money rail; MTN/Airtel direct flows are still present as legacy paths.
3. Mobile client uses a hybrid access model: backend REST plus direct Supabase table/storage operations.
4. AI assistant is first-class, backed by Groq and persisted session history.
- backend/src/routes/orderRoutes.js
- backend/src/controllers/orderController.js

### Data Impact
- orders
- order_items
- products.quantity_available
- order_status_history
- notifications

### Demo Script
1. Buyer confirms address and payment method.
2. Backend validates stock and creates order + order items.
3. Product quantities are adjusted.
4. Farmers are notified of new order.

### Likely Questions
- How do you prevent overselling stock?
- Is order creation transactional?
- What happens if items insert fails?

---

## Feature 6: Payment Initiation and Callback
### Sequence
Payment initiation + webhook sequence diagram.

### Business Goal
Collect payment and update order payment status reliably.

### What to Show
- Payment method selection
- Backend payment initiation
- Callback/webhook status update

### Files to Open
- mobile/lib/screens/buyer/payment_methods_screen.dart
- mobile/lib/services/payment_service.dart
- backend/src/routes/paymentRoutes.js
- backend/src/controllers/paymentController.js
- backend/src/services/marzpayService.js

### Data Impact
- payments
- orders.payment_status

### Demo Script
1. Buyer triggers payment from app.
2. Backend sends payment request to gateway.
3. Gateway callback confirms success/failure.
4. Backend updates payment and order status.

### Likely Questions
- Why callback is necessary?
- How do you handle pending/failed payments?
- How do you avoid duplicate status updates?

---

## Feature 7: Order Tracking (Buyer)
### Sequence
Order tracking sequence diagram.

### Business Goal
Give buyer transparent fulfillment progress.

### What to Show
- Tracking screen timeline
- API call for order and status history

### Files to Open
- mobile/lib/screens/buyer/order_tracking_screen.dart
- mobile/lib/screens/buyer/buyer_orders_screen.dart
- mobile/lib/services/order_service.dart
- backend/src/routes/orderRoutes.js
- backend/src/controllers/orderController.js

### Data Impact
- orders (read)
- order_status_history (read)

### Demo Script
1. Buyer opens order details.
2. App fetches status timeline.
3. Screen displays latest stage and history.

### Likely Questions
- Who can see a specific order?
- Where does status history come from?

---

## Feature 8: Submit Review
### Sequence
Submit review sequence diagram.

### Business Goal
Allow post-delivery feedback and trust building.

### What to Show
- Rating/comment submission
- Backend review insert and product rating update

### Files to Open
- mobile/lib/screens/buyer/product_detail_screen.dart
- mobile/lib/services/product_service.dart
- backend/src/routes/productRoutes.js
- backend/src/controllers/productController.js

### Data Impact
- product_reviews
- products.rating / total_reviews

### Demo Script
1. Buyer submits rating and comment.
2. Review is saved.
3. Product aggregate rating is updated.

### Likely Questions
- Can user review without purchase?
- How do you recalculate average rating?

---

## Feature 9: Farmer Add/Edit Product
### Sequence
Farmer product listing sequence diagram.

### Business Goal
Enable farmers to publish and maintain product inventory.

### What to Show
- Add/Edit product form
- Optional image upload
- Backend product save/update

### Files to Open
- mobile/lib/screens/farmer/add_product_screen.dart
- mobile/lib/screens/farmer/farmer_products_screen.dart
- mobile/lib/services/product_service.dart
- backend/src/routes/productRoutes.js
- backend/src/controllers/productController.js

### Data Impact
- products
- storage references (images)

### Demo Script
1. Farmer fills product details and submits.
2. App sends payload and media URLs.
3. Product appears in farmer product list by status.

### Likely Questions
- How do you validate product fields?
- How do draft/pending/active states work?

---

## Feature 10: Farmer Order Fulfillment
### Sequence
Farmer order fulfillment sequence diagram.

### Business Goal
Let farmers process buyer orders through lifecycle stages.

### What to Show
- Farmer orders tabs and status actions
- Backend status updates and buyer notifications

### Files to Open
- mobile/lib/screens/farmer/farmer_orders_screen.dart
- mobile/lib/services/order_service.dart
- backend/src/routes/orderRoutes.js
- backend/src/controllers/orderController.js

### Data Impact
- order_items.status
- orders.status
- order_status_history
- notifications

### Demo Script
1. Farmer opens pending orders.
2. Farmer confirms, ships, or marks delivered.
3. Buyer receives updated tracking status.

### Likely Questions
- Can farmer update any order?
- How do partial/multi-farmer orders behave?

---

## Feature 11: Admin Moderation
### Sequence
Admin moderation sequence diagram.

### Business Goal
Maintain quality, trust, and platform compliance.

### What to Show
- Admin dashboard tabs
- User/product/order management screens
- Backend moderation endpoints

### Files to Open
- mobile/lib/screens/admin/admin_dashboard_screen.dart
- mobile/lib/screens/admin/user_management_screen.dart
- mobile/lib/screens/admin/product_management_screen.dart
- mobile/lib/screens/admin/order_management_screen.dart
- backend/src/routes/adminRoutes.js
- backend/src/middleware/authMiddleware.js
- backend/src/controllers/adminController.js

### Data Impact
- users (suspend/verify)
- products (approve/reject)
- orders (admin notes/interventions)

### Demo Script
1. Admin reviews flagged/pending records.
2. Admin takes moderation action.
3. Status changes become visible to users.

### Likely Questions
- How is admin authorization enforced?
- Are admin actions auditable?

---

## Final 10-Minute Code Presentation Order
1. App entry and providers
2. Routes and role-based navigation
3. Register/login feature trace
4. Buyer order pipeline (search -> cart -> checkout -> order)
5. Payment callback reliability
6. Farmer fulfillment flow
7. Admin moderation controls
8. Security/error handling summary

## Closing Line
The project is structured as Screen -> Provider -> Service -> API Controller -> Database/External Service, and each sequence diagram maps directly to one feature path in code.