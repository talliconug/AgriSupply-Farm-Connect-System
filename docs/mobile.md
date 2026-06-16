# AgriSupply Mobile App Guide (Current Implementation)

## 1) What this app is

The mobile app in `mobile/` is a Flutter client for buyers, farmers, and admins.

It uses:
- `provider` for state management
- Supabase for authentication/session bootstrap
- REST calls to backend API (`/api/v1/...`) for marketplace operations

## 2) Startup flow and key files

### `mobile/lib/main.dart`
Responsibilities:
- Initializes Flutter bindings and forces portrait orientation
- Initializes Supabase using values from `AppConfig`
- Registers root providers (`AuthProvider`, `CartProvider`, `ProductProvider`, `OrderProvider`, `NotificationProvider`)
- Starts the app at `SplashScreen`

### `mobile/lib/screens/splash_screen.dart`
Responsibilities:
- Shows splash animation
- Checks current auth session
- Routes users into role-specific destinations

## 3) Configuration files and what each does

### `mobile/lib/config/app_config.dart`
Responsibilities:
- Holds app constants and endpoint values
- Defines `supabaseUrl`, `supabaseAnonKey`, and `apiBaseUrl`
- Contains API timeout and upload limits used by services

### `mobile/lib/config/routes.dart`
Responsibilities:
- Central source of route-name constants
- Maps route names to screen widgets in `generateRoute`
- Organizes role routes: auth, buyer, farmer, admin, and shared routes

### `mobile/lib/config/theme.dart`
Responsibilities:
- App color system and typography
- Light/dark theme definitions used by `MaterialApp`

## 4) Localization files

### `mobile/lib/l10n/app_en.arb`
English strings and metadata.

### `mobile/lib/l10n/app_lg.arb`
Luganda strings.

### Generated localization files
Generated classes used by widgets for translated text lookup.

## 5) Models: data contracts in app code

Folder: `mobile/lib/models/`

- `user_model.dart`: user profile, role, identity, and account flags
- `product_model.dart`: product catalog records, media, pricing, availability
- `order_model.dart`: order summary/details and fulfillment status
- `cart_model.dart`: cart items and totals
- `review_model.dart`: ratings and text feedback
- `notification_model.dart`: in-app notification payload and read state

## 6) Providers: screen state and orchestration

Folder: `mobile/lib/providers/`

- `auth_provider.dart`: auth state machine (`initial/loading/authenticated/...`), session listening, role checks
- `product_provider.dart`: product list/detail/search state
- `cart_provider.dart`: cart add/remove/update and totals
- `order_provider.dart`: checkout, order history, tracking updates
- `notification_provider.dart`: list, unread count, grouped notification view
- `user_provider.dart`: profile and user-related interactions beyond auth state

## 7) Services: API and integrations

Folder: `mobile/lib/services/`

- `api_service.dart`: base HTTP wrapper, token header attachment, GET/POST/PUT/DELETE helpers
- `auth_service.dart`: sign-in/up, Google sign-in path, profile retrieval
- `product_service.dart`: product browsing, details, review actions, favorites
- `order_service.dart`: create order, list orders, tracking/history actions
- `payment_service.dart`: initiate and monitor payment flows
- `notification_service.dart`: notification API actions
- `ai_service.dart`: AI chat/image and related AI endpoints
- `user_service.dart`: user profile and relationship actions (follow/follower style features)
- `location_service.dart`: geolocation and address support for delivery/location features
- `storage_service.dart`: local persistence helpers for cached app data
- `location_service_integration_example.dart`: integration sample/reference implementation

## 8) Screens by role and module

### Auth screens (`mobile/lib/screens/auth/`)
- `login_screen.dart`: email/password login form and auth entry
- `register_screen.dart`: account creation flow
- `otp_verification_screen.dart`: OTP verification step
- `forgot_password_screen.dart`: reset-start flow

### Buyer screens (`mobile/lib/screens/buyer/`)
- `buyer_home_screen.dart`: catalog landing and discovery
- `search_screen.dart`: product search and filtering
- `product_detail_screen.dart`: product view, quantity, reviews, cart entry point
- `cart_screen.dart`: cart management and totals
- `checkout_screen.dart`: address/payment selection and place-order action
- `buyer_orders_screen.dart`: past/current buyer orders
- `order_tracking_screen.dart`: order timeline/status checks
- `payment_methods_screen.dart`: method selection UI
- `buyer_profile_screen.dart`: buyer profile management
- `delivery_addresses_screen.dart`: delivery address management
- `about_screen.dart`: informational page
- `help_support_screen.dart`: support/help content

### Farmer screens (`mobile/lib/screens/farmer/`)
- `farmer_dashboard_screen.dart`: farmer KPIs and entry points
- `add_product_screen.dart`: create/edit product flow UI
- `farmer_products_screen.dart`: farmer product list management
- `farmer_orders_screen.dart`: incoming orders and fulfillment actions
- `farmer_analytics_screen.dart`: sales/performance analytics
- `farmer_profile_screen.dart`: farmer profile and farm details
- `ai_assistant_screen.dart`: AI assistant interactions
- `premium_screen.dart`: premium/subscription UX

### Admin screens (`mobile/lib/screens/admin/`)
- `admin_dashboard_screen.dart`: admin overview metrics
- `user_management_screen.dart`: user moderation and account operations
- `product_management_screen.dart`: product moderation and curation
- `order_management_screen.dart`: system-wide order operations
- `analytics_screen.dart`: aggregate admin analytics

### Shared screens (`mobile/lib/screens/common/`)
- `notifications_screen.dart`: user notification center
- `help_support_screen.dart`: reusable support UI in common module

## 9) Reusable UI widgets

Folder: `mobile/lib/widgets/`

- `custom_button.dart`: branded action button abstraction
- `custom_text_field.dart`: shared form input widget
- `product_card.dart`: reusable product list/tile card
- `search_bar_widget.dart`: common search UI
- `quantity_selector.dart`: increment/decrement quantity control
- `rating_stars.dart`: rating display/input component
- `order_status_badge.dart`: visual order status indicator
- `loading_overlay.dart`: generic loading mask
- `category_chip.dart`: category filter chip

## 10) End-to-end request flow (how code executes)

1. A screen handles a user action (tap/submit).
2. Provider method is called and marks local state as loading.
3. Provider delegates IO to a service.
4. Service calls backend via `ApiService`.
5. `ApiService` adds bearer token from active Supabase session.
6. Backend returns JSON.
7. Provider updates state and notifies listeners.
8. Widgets rebuild from the new provider state.

## 11) Authentication and role routing logic

- Session source: `Supabase.instance.client.auth.currentSession`
- Auth listener: `auth_provider.dart` subscribes to auth state changes
- Role checks: exposed in provider (`isBuyer`, `isFarmer`, `isAdmin`)
- Route switching: managed by route constants and navigation logic in auth/splash flows

## 12) Build and run commands

From `mobile/`:

```bash
flutter pub get
flutter run
flutter build apk --release
```

## 13) Important implementation notes

- `app_config.dart` currently stores concrete endpoint/keys in code constants.
- Compile-time defines (`--dart-define`) are documented but not yet the primary config source in `lib/` runtime code.
- Keep route names synchronized with screens in `config/routes.dart` to avoid navigation runtime errors.
