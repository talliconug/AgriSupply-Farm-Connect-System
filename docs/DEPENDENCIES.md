# AgriSupply Dependency Reference (Use, Where, How)

This file documents dependencies declared in:
1. mobile/pubspec.yaml
2. backend/package.json

It also explains:
1. What each dependency does.
2. How it is used in this system.
3. Where it is used (representative files).

Status legend:
1. Active: direct imports/usages observed in source.
2. Declared: listed in manifest but no direct import found in main source scan.

## 1. Mobile Dependencies (Flutter)

Source: mobile/pubspec.yaml

## 1.1 SDK Dependencies

1. flutter (sdk)
- Functionality: Core Flutter framework and widgets.
- How used: App UI, routing, state rendering, widgets.
- Where used: mobile/lib/main.dart, mobile/lib/screens/**, mobile/lib/widgets/**.
- Status: Active.

2. flutter_localizations (sdk)
- Functionality: Built-in localization delegates and locale support.
- How used: App localization setup.
- Where used: mobile/lib/l10n/app_localizations.dart.
- Status: Active.

## 1.2 Application Dependencies

1. provider
- Functionality: State management using ChangeNotifier.
- How used: App-level providers for auth, products, orders, cart, notifications.
- Where used: mobile/lib/main.dart, mobile/lib/providers/**, many screens in mobile/lib/screens/**.
- Status: Active.

2. http
- Functionality: REST client for HTTP requests.
- How used: API calls from mobile service layer and multipart upload support.
- Where used: mobile/lib/services/api_service.dart, mobile/lib/services/product_service.dart.
- Status: Active.

3. http_parser
- Functionality: MIME type helpers for multipart uploads.
- How used: Sets multipart image content-type.
- Where used: mobile/lib/services/product_service.dart.
- Status: Active.

4. dio
- Functionality: Advanced HTTP client.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

5. shared_preferences
- Functionality: Lightweight key-value local persistence.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

6. flutter_secure_storage
- Functionality: Encrypted secure local storage.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

7. cupertino_icons
- Functionality: iOS-style icon pack.
- How used: Available to widgets/themes when using Cupertino icons.
- Where used: No direct import required in source.
- Status: Declared.

8. google_fonts
- Functionality: Dynamic Google Fonts loading.
- How used: Typography in app theme.
- Where used: mobile/lib/config/theme.dart.
- Status: Active.

9. flutter_svg
- Functionality: SVG rendering in Flutter.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

10. cached_network_image
- Functionality: Network image loading with cache and placeholders.
- How used: Product and admin/buyer image rendering.
- Where used: mobile/lib/widgets/product_card.dart, mobile/lib/screens/buyer/cart_screen.dart, mobile/lib/screens/buyer/product_detail_screen.dart, mobile/lib/screens/admin/product_management_screen.dart.
- Status: Active.

11. shimmer
- Functionality: Shimmer loading animation widgets.
- How used: Current loading skeletons are custom widgets; no direct shimmer import found.
- Where used: No direct import found.
- Status: Declared.

12. flutter_spinkit
- Functionality: Animated loading spinners.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

13. badges
- Functionality: Badge widgets for counts/status.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

14. smooth_page_indicator
- Functionality: Page indicators for carousels/onboarding.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

15. flutter_form_builder
- Functionality: Advanced forms and field widgets.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

16. form_builder_validators
- Functionality: Validator helpers for form_builder fields.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

17. image_picker
- Functionality: Camera/gallery image selection.
- How used: User/farmer profile and product image picking.
- Where used: mobile/lib/screens/farmer/add_product_screen.dart, mobile/lib/screens/farmer/farmer_profile_screen.dart, mobile/lib/screens/buyer/buyer_profile_screen.dart.
- Status: Active.

18. go_router
- Functionality: Declarative routing and deep links.
- How used: Current app uses MaterialApp with onGenerateRoute; go_router not directly imported.
- Where used: No direct import found.
- Status: Declared.

19. flutter_local_notifications
- Functionality: Local notifications on device.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

20. url_launcher
- Functionality: Launch external links and intents.
- How used: Opens support/contact links from help/about screens.
- Where used: mobile/lib/screens/common/help_support_screen.dart, mobile/lib/screens/buyer/help_support_screen.dart, mobile/lib/screens/buyer/about_screen.dart.
- Status: Active.

21. webview_flutter
- Functionality: Embedded webview.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

22. geolocator
- Functionality: GPS/location permission and coordinates.
- How used: Device location retrieval logic.
- Where used: mobile/lib/services/location_service.dart.
- Status: Active.

23. geocoding
- Functionality: Coordinate/address reverse geocoding.
- How used: Current location service comments mention future reverse geocoding; no direct import found.
- Where used: No direct import found.
- Status: Declared.

24. fl_chart
- Functionality: Chart rendering for analytics.
- How used: Dashboard/analytics visualizations.
- Where used: mobile/lib/screens/admin/admin_dashboard_screen.dart, mobile/lib/screens/admin/analytics_screen.dart, mobile/lib/screens/farmer/farmer_dashboard_screen.dart, mobile/lib/screens/farmer/farmer_analytics_screen.dart.
- Status: Active.

25. supabase_flutter
- Functionality: Supabase auth/database/storage/realtime client.
- How used: App initialization, auth session handling, direct data/storage operations, realtime notifications.
- Where used: mobile/lib/main.dart, mobile/lib/services/api_service.dart, mobile/lib/services/auth_service.dart, mobile/lib/services/storage_service.dart, mobile/lib/services/notification_service.dart, mobile/lib/providers/auth_provider.dart.
- Status: Active.

26. google_sign_in
- Functionality: Google OAuth sign-in integration.
- How used: Auth service integration point.
- Where used: mobile/lib/services/auth_service.dart.
- Status: Active.

27. intl
- Functionality: Date, number, currency, localization formatting.
- How used: UI date/number formatting and l10n generation.
- Where used: mobile/lib/l10n/**, multiple screens (admin/farmer/buyer), mobile/lib/widgets/product_card.dart.
- Status: Active.

28. uuid
- Functionality: UUID generation.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

29. connectivity_plus
- Functionality: Network connectivity status detection.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

30. package_info_plus
- Functionality: App metadata (version/build) lookup.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

31. permission_handler
- Functionality: Runtime permissions helper.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

32. path_provider
- Functionality: Local filesystem path helpers.
- How used: Not directly imported in current mobile/lib source.
- Where used: No direct import found.
- Status: Declared.

## 1.3 Mobile Dev Dependencies

1. flutter_test
- Functionality: Widget/unit testing framework.
- How used: Flutter test support in test and integration flows.
- Where used: mobile/test/**, mobile/integration_test/**.

2. flutter_lints
- Functionality: Recommended lint rules.
- How used: Static analysis policy via analysis options.
- Where used: mobile/analysis_options.yaml.

3. mockito
- Functionality: Mock generation for tests.
- How used: Test mocking support.
- Where used: Intended for test suites.

4. build_runner
- Functionality: Code generation runner.
- How used: Required by generators such as mockito.
- Where used: Dev tooling.

5. flutter_launcher_icons
- Functionality: App icon generation.
- How used: Generates platform launcher icons from config.
- Where used: mobile/flutter_launcher_icons.yaml.

6. integration_test
- Functionality: Flutter integration test framework.
- How used: End-to-end test harness.
- Where used: mobile/integration_test/app_test.dart.

## 2. Backend Dependencies (Node.js)

Source: backend/package.json

## 2.1 Runtime Dependencies

1. @supabase/supabase-js
- Functionality: Supabase auth/database/storage client SDK.
- How used: Creates service and anon clients for backend operations.
- Where used: backend/src/config/supabase.js.
- Status: Active.

2. axios
- Functionality: HTTP client for external API calls.
- How used: Calls MarzPay, MTN, Airtel, and Flutterwave endpoints.
- Where used: backend/src/controllers/paymentController.js, backend/src/services/marzpayService.js.
- Status: Active.

3. bcryptjs
- Functionality: Password hashing/comparison.
- How used: No direct import found in backend/src (Supabase auth handles core credential flow).
- Where used: No direct import found.
- Status: Declared.

4. compression
- Functionality: Gzip/Brotli HTTP response compression.
- How used: Registered as global Express middleware.
- Where used: backend/src/index.js.
- Status: Active.

5. cors
- Functionality: Cross-origin request policy middleware.
- How used: Configured with allowed origins/headers/methods.
- Where used: backend/src/index.js.
- Status: Active.

6. dotenv
- Functionality: Loads environment variables from .env.
- How used: Bootstraps config before app initialization.
- Where used: backend/src/index.js.
- Status: Active.

7. express
- Functionality: Web server and routing framework.
- How used: App creation and route modules.
- Where used: backend/src/index.js, backend/src/routes/**.
- Status: Active.

8. express-rate-limit
- Functionality: Request throttling middleware.
- How used: Global API rate limiter.
- Where used: backend/src/index.js.
- Status: Active.

9. express-validator
- Functionality: Request validation and sanitization.
- How used: Validator chains for auth/order/product/payment/admin routes.
- Where used: backend/src/utils/validators.js, backend/src/middleware/errorMiddleware.js.
- Status: Active.

10. helmet
- Functionality: Security headers hardening.
- How used: Global security middleware.
- Where used: backend/src/index.js.
- Status: Active.

11. jsonwebtoken
- Functionality: JWT sign/verify primitives.
- How used: No direct import found in backend/src (token handling is Supabase-based).
- Where used: No direct import found.
- Status: Declared.

12. morgan
- Functionality: HTTP access logging middleware.
- How used: Dev and production request logging.
- Where used: backend/src/index.js.
- Status: Active.

13. multer
- Functionality: Multipart/form-data parsing for uploads.
- How used: In-memory file parsing for product/profile/AI image uploads.
- Where used: backend/src/middleware/uploadMiddleware.js, backend/src/middleware/optionalUploadMiddleware.js.
- Status: Active.

14. openai
- Functionality: OpenAI-compatible SDK used against Groq endpoint.
- How used: Chat and vision completions for farming assistant features.
- Where used: backend/src/controllers/aiController.js.
- Status: Active.

15. uuid
- Functionality: UUID generation helper.
- How used: Generates references in MarzPay service.
- Where used: backend/src/services/marzpayService.js.
- Status: Active.

16. winston
- Functionality: Structured, multi-transport logging.
- How used: Central logger utility for console and file logs.
- Where used: backend/src/utils/logger.js.
- Status: Active.

## 2.2 Backend Dev Dependencies

1. eslint
- Functionality: JavaScript linting.
- How used: npm run lint.

2. eslint-config-prettier
- Functionality: Disables lint rules that conflict with Prettier.
- How used: ESLint config integration.

3. eslint-plugin-node
- Functionality: Node.js-specific lint rules.
- How used: ESLint plugin set.

4. eslint-plugin-prettier
- Functionality: Runs Prettier as ESLint rule.
- How used: Unified style checks.

5. eslint-plugin-security
- Functionality: Security-focused lint checks.
- How used: Detects common unsafe JS patterns.

6. jest
- Functionality: Test runner and assertion framework.
- How used: Unit/integration test execution.
- Where used: backend/tests/**.

7. nodemon
- Functionality: Auto-restart server in development.
- How used: npm run dev.

8. prettier
- Functionality: Code formatter.
- How used: Formatting in dev workflow.

9. supertest
- Functionality: HTTP API testing utilities.
- How used: Backend endpoint tests.
- Where used: backend/tests/controllers/**, backend/tests/middleware/**.

## 3. Toolchain Requirements

From backend/package.json engines:
1. Node.js >=20.0.0
2. npm >=10.0.0

From mobile/pubspec.yaml environment:
1. Dart SDK ^3.7.1

## 4. Notes on Declared vs Active

1. Several mobile packages are declared for planned or optional features but are not directly imported in current mobile/lib source.
2. Some backend packages (for example bcryptjs, jsonwebtoken) are declared but not directly imported in backend/src, likely due migration to Supabase-managed auth/session flows.
3. Re-run this dependency audit whenever routes/services are refactored.

## 5. Refresh Commands

Backend:
```bash
cd backend
npm install
```

Mobile:
```bash
cd mobile
flutter pub get
```
