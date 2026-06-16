# AgriSupply Mobile Application

Comprehensive guide for the AgriSupply Flutter mobile application.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Features](#features)
5. [State Management](#state-management)
6. [Localization](#localization)
7. [Testing](#testing)
8. [Building & Deployment](#building--deployment)

---

## Getting Started

### Prerequisites

- Flutter SDK 3.16+
- Dart SDK 3.2+
- Android Studio / Xcode
- VS Code with Flutter extension

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/agrisupply.git
cd agrisupply/mobile

# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run on device/emulator
flutter run
```

### Environment Setup

Create environment configuration:

```dart
// lib/config/env.dart
class Env {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );
  
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
}
```

Run with environment:
```bash
flutter run --dart-define=API_URL=https://api.agrisupply.ug --dart-define=ENVIRONMENT=production
```

---

## Architecture

AgriSupply follows a clean architecture pattern with Provider for state management:

```
┌─────────────────────────────────────────────────────┐
│                    Presentation                      │
│   ┌─────────┐  ┌─────────┐  ┌─────────────────┐    │
│   │ Screens │  │ Widgets │  │ State (Provider)│    │
│   └────┬────┘  └────┬────┘  └────────┬────────┘    │
└────────┼────────────┼────────────────┼──────────────┘
         │            │                │
┌────────┴────────────┴────────────────┴──────────────┐
│                    Domain Layer                      │
│   ┌─────────┐  ┌───────────┐  ┌───────────────┐    │
│   │ Models  │  │ Providers │  │ Business Logic│    │
│   └────┬────┘  └─────┬─────┘  └───────┬───────┘    │
└────────┼─────────────┼────────────────┼─────────────┘
         │             │                │
┌────────┴─────────────┴────────────────┴─────────────┐
│                     Data Layer                       │
│   ┌───────────┐  ┌──────────────┐  ┌────────────┐  │
│   │ Services  │  │ API Clients  │  │ Local DB   │  │
│   └───────────┘  └──────────────┘  └────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   ├── app_config.dart       # App configuration
│   ├── routes.dart           # Navigation routes
│   └── theme.dart            # App theme
├── l10n/
│   ├── app_en.arb            # English translations
│   └── app_lg.arb            # Luganda translations
├── models/
│   ├── user_model.dart       # User data model
│   ├── product_model.dart    # Product data model
│   ├── order_model.dart      # Order data model
│   ├── cart_model.dart       # Cart data model
│   ├── review_model.dart     # Review data model
│   └── notification_model.dart
├── providers/
│   ├── auth_provider.dart    # Authentication state
│   ├── user_provider.dart    # User profile state
│   ├── product_provider.dart # Products state
│   ├── cart_provider.dart    # Shopping cart state
│   ├── order_provider.dart   # Orders state
│   └── notification_provider.dart
├── services/
│   ├── api_service.dart      # HTTP client
│   ├── auth_service.dart     # Auth API calls
│   ├── product_service.dart  # Product API calls
│   ├── order_service.dart    # Order API calls
│   ├── payment_service.dart  # Payment processing
│   ├── ai_service.dart       # AI assistant
│   └── notification_service.dart
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── buyer/
│   │   ├── buyer_home_screen.dart
│   │   ├── product_detail_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── checkout_screen.dart
│   │   └── ...
│   ├── farmer/
│   │   ├── farmer_dashboard_screen.dart
│   │   ├── add_product_screen.dart
│   │   ├── ai_assistant_screen.dart
│   │   └── ...
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart
│   │   └── ...
│   └── common/
│       ├── notifications_screen.dart
│       └── settings_screen.dart
└── widgets/
    ├── custom_button.dart
    ├── custom_text_field.dart
    ├── product_card.dart
    ├── loading_overlay.dart
    └── ...
```

---

## Features

### Authentication
- Email/Password registration and login
- Phone number verification (OTP)
- Password reset via email
- Session management with JWT
- Role-based access (Buyer, Farmer, Admin)

### Buyer Features
- Browse products by category
- Search with filters (price, location, rating)
- Product details with farmer info
- Shopping cart management
- Checkout with address selection
- Multiple payment options (MTN MoMo, Airtel Money, Card)
- Order tracking with real-time status
- Review and rate products
- Push notifications

### Farmer Features
- Dashboard with sales analytics
- Product listing management (CRUD)
- Order management
- AI-powered farming assistant
- Crop analysis from images
- Premium subscription for visibility
- Earnings and payout tracking

### Admin Features
- User management
- Content moderation
- Analytics dashboard
- System health monitoring

---

## State Management

Using Provider for state management:

### Provider Setup

```dart
// main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => ProductProvider()),
    ChangeNotifierProvider(create: (_) => CartProvider()),
    ChangeNotifierProvider(create: (_) => OrderProvider()),
    ChangeNotifierProvider(create: (_) => NotificationProvider()),
  ],
  child: MyApp(),
)
```

### Using Providers

```dart
// Access provider
final authProvider = context.read<AuthProvider>();

// Listen to changes
Consumer<CartProvider>(
  builder: (context, cart, child) {
    return Text('Items: ${cart.itemCount}');
  },
)

// Watch for changes
final products = context.watch<ProductProvider>().products;
```

### Provider Pattern

```dart
class ExampleProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<Item> _items = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Item> get items => _items;

  // Methods
  Future<void> fetchItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _service.getItems();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## Localization

AgriSupply supports English and Luganda:

### Adding Translations

1. Edit ARB files in `lib/l10n/`
2. Run `flutter gen-l10n`
3. Use in widgets:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// In widget
Text(AppLocalizations.of(context)!.welcomeMessage)
```

### Switching Languages

```dart
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  
  Locale get locale => _locale;
  
  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
```

---

## Testing

### Unit Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Specific test file
flutter test test/providers/auth_provider_test.dart
```

### Widget Tests

```dart
testWidgets('ProductCard displays correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProductCard(product: mockProduct),
    ),
  );

  expect(find.text('Fresh Tomatoes'), findsOneWidget);
  expect(find.byType(Image), findsOneWidget);
});
```

### Integration Tests

```bash
flutter test integration_test
```

---

## Building & Deployment

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release
```

### With Environment

```bash
flutter build apk --release \
  --dart-define=API_URL=https://api.agrisupply.ug \
  --dart-define=ENVIRONMENT=production
```

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

## License

MIT License - see [LICENSE](../LICENSE) for details.
