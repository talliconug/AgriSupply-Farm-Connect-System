# AgriSupply Code Architecture and Hierarchy

This document describes what each architecture heading does and how each part communicates with other files and external systems in this repository.

## 1. Top-Level Modules

1. backend/: Node.js Express API runtime.
2. mobile/: Flutter client application.
3. backend/database/: SQL schema, setup, and seed scripts for Supabase/PostgreSQL.
4. docs/: Technical and product documentation.

System communication summary:
1. Mobile app communicates with backend over HTTPS REST for many domain flows.
2. Mobile app also performs direct Supabase reads/writes for selected tables and storage operations.
3. Backend communicates with Supabase (database/auth/storage), MarzPay (payments), Groq (AI), and optional notification providers.
4. Database trigger logic creates/maintains profile state and supporting counters/history.

## 2. Backend Architecture Hierarchy

## 2.1 Entry Layer

Primary file:
1. backend/src/index.js

What it does:
1. Builds Express runtime.
2. Registers middleware and route modules.
3. Exposes /health and starts HTTP listener.

How it communicates:
1. Mounts all route files under /api/{version}/*.
2. Delegates exceptions to middleware/errorMiddleware.js.

## 2.2 Configuration Layer

Files:
1. backend/src/config/supabase.js
2. backend/src/config/constants.js
3. backend/src/utils/validators.js

What it does:
1. Creates reusable integration clients and wrappers.
2. Holds constants, AI prompt/model settings, category lists, and validation rules.
3. Centralizes request schema checks used by route middleware chains.

How it communicates:
1. supabase.js is imported by middleware/controllers/services for DB/auth/storage operations.
2. constants.js is consumed by controllers/services/validators for consistent rules.
3. validators are consumed by route files before controller invocation.

## 2.3 Middleware Layer

Files:
1. backend/src/middleware/authMiddleware.js
2. backend/src/middleware/errorMiddleware.js
3. backend/src/middleware/uploadMiddleware.js
4. backend/src/middleware/optionalUploadMiddleware.js

What it does:
1. Verifies JWT tokens and user profile status.
2. Enforces role constraints (admin/farmer/premium/verified).
3. Handles multipart upload parsing and normalization.
4. Normalizes thrown errors into consistent API responses.

How it communicates:
1. Route files invoke authenticate/optionalAuth/role checks before business handlers.
2. Route files invoke validators then handleValidation before controllers.
3. Any next(error) reaches errorHandler and returns standardized JSON.

## 2.4 Route Layer

Files:
1. backend/src/routes/authRoutes.js
2. backend/src/routes/userRoutes.js
3. backend/src/routes/productRoutes.js
4. backend/src/routes/orderRoutes.js
5. backend/src/routes/paymentRoutes.js
6. backend/src/routes/notificationRoutes.js
7. backend/src/routes/aiRoutes.js
8. backend/src/routes/adminRoutes.js

What it does:
1. Defines endpoint paths and request validation boundaries.
2. Applies auth/role/upload middleware chain.
3. Delegates business logic to controller layer.

How it communicates:
1. Reads/writes database through controller imports that use Supabase client.
2. Exposes public webhook callbacks for payment providers.
3. Serves role-scoped APIs for buyer/farmer/admin/mobile clients.

## 2.5 Controller and Service Layer

Primary files:
1. backend/src/controllers/authController.js
2. backend/src/controllers/userController.js
3. backend/src/controllers/productController.js
4. backend/src/controllers/orderController.js
5. backend/src/controllers/paymentController.js
6. backend/src/controllers/notificationController.js
7. backend/src/controllers/aiController.js
8. backend/src/controllers/adminController.js
9. backend/src/services/marzpayService.js

What it does:
1. Implements auth and profile lifecycle.
2. Implements catalog search, product CRUD, and reviews/favorites.
3. Implements order creation, status transitions, and history.
4. Implements payment initiation, callbacks, verification, and refunds.
5. Implements notification read/update/preferences/device registration.
6. Implements AI chat/image analysis and usage tracking.
7. Implements admin moderation and analytics endpoints.

How it communicates:
1. Controllers query/update Supabase tables and RPC where applicable.
2. paymentController calls marzpayService and provider APIs.
3. aiController calls Groq via OpenAI-compatible client.
4. Controllers write notifications records consumed by mobile providers/screens.

## 3. Mobile App Architecture Hierarchy

## 3.1 App Entry and Route Map

Primary files:
1. mobile/lib/main.dart
2. mobile/lib/config/routes.dart
3. mobile/lib/config/app_config.dart

What it does:
1. Initializes Supabase and app-level providers.
2. Registers route table and startup screen.
3. Defines backend base URL and app constants.

How it communicates:
1. Screens resolve providers from dependency graph.
2. Providers call service methods and push state updates to widgets.

## 3.2 Provider Layer

Files:
1. mobile/lib/providers/auth_provider.dart
2. mobile/lib/providers/product_provider.dart
3. mobile/lib/providers/order_provider.dart
4. mobile/lib/providers/cart_provider.dart
5. mobile/lib/providers/notification_provider.dart
6. mobile/lib/providers/user_provider.dart

What it does:
1. Owns UI state (loading/error/data/selection).
2. Calls service methods and maps results to presentation state.

How it communicates:
1. Provider -> Service layer for network/data I/O.
2. Provider -> Flutter widgets via notifyListeners() updates.

## 3.3 Service Layer

Files:
1. mobile/lib/services/api_service.dart
2. mobile/lib/services/auth_service.dart
3. mobile/lib/services/product_service.dart
4. mobile/lib/services/order_service.dart
5. mobile/lib/services/payment_service.dart
6. mobile/lib/services/notification_service.dart
7. mobile/lib/services/ai_service.dart
8. mobile/lib/services/location_service.dart

What it does:
1. Centralizes HTTP calls and auth header injection.
2. Wraps domain API calls by feature.
3. Performs direct Supabase table/storage operations in selected flows.

How it communicates:
1. Uses HTTPS to backend API (configured by AppConfig.apiBaseUrl).
2. Reads Supabase auth session for Authorization headers.
3. Calls Supabase data and realtime APIs directly where implemented.

## 3.4 Screen Layer

Directories:
1. mobile/lib/screens/auth/
2. mobile/lib/screens/buyer/
3. mobile/lib/screens/farmer/
4. mobile/lib/screens/admin/
5. mobile/lib/screens/common/

What it does:
1. Captures user actions and renders stateful UI.
2. Triggers provider methods for auth/catalog/order/payment/notification actions.

How it communicates:
1. UI events -> provider method calls.
2. Provider state -> rebuilt UI.

## 4. Database Architecture Hierarchy

Files:
1. backend/database/schema.sql
2. backend/database/manual_fix.sql
3. backend/database/setup_storage.sql
4. backend/database/seed.sql

What it does:
1. Stores core entities (users, products, orders, order_items, payments, notifications, reviews, favorites, AI sessions/usage, cart, settings, payouts, refunds).
2. Defines indexes, triggers, and RLS policy baselines.
3. Defines auth.users -> users profile creation trigger logic.
4. Defines storage bucket and storage policy setup scripts.

How it communicates:
1. Backend controllers execute CRUD and occasional RPC via Supabase client.
2. Mobile services may read/write selected tables directly via Supabase.
3. Trigger functions maintain profile and derived metrics behavior during runtime.

## 5. End-to-End Communication Flows

## 5.1 Buyer Commerce Flow
1. Buyer action occurs on Flutter screen.
2. Screen calls provider.
3. Provider calls service.
4. Service calls backend endpoint (or direct Supabase in hybrid paths).
5. Backend route authenticates/authorizes request.
6. Controller invokes Supabase and external providers when required.
7. Backend returns JSON response.
8. Provider updates app state and UI re-renders.

## 5.2 Payment Callback Flow
1. Buyer initiates payment through /api/v1/payments/initiate.
2. paymentController writes payments record and sets order payment_status.
3. Provider webhook hits callback route (marzpay/mtn/airtel/card).
4. Controller maps callback status and updates payments/orders.
5. Notification rows are inserted for user visibility.

## 5.3 AI Assistant Flow
1. User sends question/image from AI screen.
2. Request reaches /api/v1/ai/* endpoint.
3. aiController loads/creates session and calls Groq API.
4. Response and usage metadata are stored in ai_chat_sessions/ai_usage.
5. Mobile displays AI output and session history.

## 6. Current Architecture Characteristics

1. API runtime is centralized under backend/src with versioned routing.
2. Payment rail is MarzPay-primary with MTN/Airtel/card/COD compatibility paths.
3. Authentication is Supabase-backed with role-aware middleware.
4. Notifications are first-class (table, API, preferences, device registration).
5. AI assistant capabilities are integrated into core backend and mobile feature set.
6. Mobile data access is hybrid: backend API plus direct Supabase operations.
7. Admin moderation and analytics endpoints exist in backend and are represented by dedicated admin screens.
