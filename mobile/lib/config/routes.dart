import 'package:flutter/material.dart';

import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/analytics_screen.dart';
import '../screens/admin/order_management_screen.dart';
import '../screens/admin/product_management_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/buyer/about_screen.dart';
import '../screens/buyer/buyer_home_screen.dart';
import '../screens/buyer/buyer_orders_screen.dart';
import '../screens/buyer/buyer_profile_screen.dart';
import '../screens/buyer/cart_screen.dart';
import '../screens/buyer/checkout_screen.dart';
import '../screens/buyer/delivery_addresses_screen.dart';
import '../screens/buyer/order_tracking_screen.dart';
import '../screens/buyer/payment_methods_screen.dart';
import '../screens/buyer/product_detail_screen.dart';
import '../screens/buyer/search_screen.dart';
import '../screens/common/help_support_screen.dart';
import '../screens/common/notifications_screen.dart';
import '../screens/farmer/add_product_screen.dart';
import '../screens/farmer/ai_assistant_screen.dart';
import '../screens/farmer/farmer_analytics_screen.dart';
import '../screens/farmer/farmer_dashboard_screen.dart';
import '../screens/farmer/farmer_orders_screen.dart';
import '../screens/farmer/farmer_products_screen.dart';
import '../screens/farmer/farmer_profile_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';

  // Buyer Routes
  static const String buyerHome = '/buyer/home';
  static const String productDetail = '/buyer/product';
  static const String cart = '/buyer/cart';
  static const String checkout = '/buyer/checkout';
  static const String orderTracking = '/buyer/order-tracking';
  static const String buyerOrders = '/buyer/orders';
  static const String buyerProfile = '/buyer/profile';
  static const String search = '/buyer/search';
  static const String helpSupport = '/buyer/help-support';
  static const String deliveryAddresses = '/buyer/delivery-addresses';
  static const String paymentMethods = '/buyer/payment-methods';
  static const String about = '/about';

  // Farmer Routes
  static const String farmerDashboard = '/farmer/dashboard';
  static const String addProduct = '/farmer/add-product';
  static const String editProduct = '/farmer/edit-product';
  static const String farmerOrders = '/farmer/orders';
  static const String farmerProducts = '/farmer/products';
  static const String farmerProfile = '/farmer/profile';
  static const String aiAssistant = '/farmer/ai-assistant';
  static const String farmerAnalytics = '/farmer/analytics';

  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String userManagement = '/admin/users';
  static const String productManagement = '/admin/products';
  static const String orderManagement = '/admin/orders';
  static const String analytics = '/admin/analytics';

  // Common Routes
  static const String notifications = '/notifications';

  static Route<dynamic> generateRoute(final RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case forgotPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ForgotPasswordScreen(
            initialPhone: args?['phone'] as String?,
          ),
          settings,
        );
      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          OtpVerificationScreen(
            email: (args?['email'] as String?) ?? '',
            phone: (args?['phone'] as String?) ?? '',
            password: args?['password'] as String?,
            fullName: args?['fullName'] as String?,
            role: args?['role'] as String?,
          ),
          settings,
        );

      // Buyer Routes
      case buyerHome:
        return _buildRoute(const BuyerHomeScreen(), settings);
      case productDetail:
        final productId = settings.arguments?.toString() ?? '';
        return _buildRoute(ProductDetailScreen(productId: productId), settings);
      case cart:
        return _buildRoute(const CartScreen(), settings);
      case checkout:
        return _buildRoute(const CheckoutScreen(), settings);
      case orderTracking:
        final orderId = settings.arguments?.toString() ?? '';
        return _buildRoute(OrderTrackingScreen(orderId: orderId), settings);
      case buyerOrders:
        return _buildRoute(const BuyerOrdersScreen(), settings);
      case buyerProfile:
        return _buildRoute(const BuyerProfileScreen(), settings);
      case search:
        return _buildRoute(const SearchScreen(), settings);
      case helpSupport:
        return _buildRoute(const HelpSupportScreen(), settings);
      case deliveryAddresses:
        return _buildRoute(const DeliveryAddressesScreen(), settings);
      case paymentMethods:
        return _buildRoute(const PaymentMethodsScreen(), settings);
      case about:
        return _buildRoute(const AboutScreen(), settings);

      // Farmer Routes
      case farmerDashboard:
        return _buildRoute(const FarmerDashboardScreen(), settings);
      case addProduct:
        return _buildRoute(const AddProductScreen(), settings);
      case editProduct:
        final productId = settings.arguments?.toString() ?? '';
        return _buildRoute(AddProductScreen(productId: productId), settings);
      case farmerOrders:
        return _buildRoute(const FarmerOrdersScreen(), settings);
      case farmerProducts:
        return _buildRoute(const FarmerProductsScreen(), settings);
      case farmerProfile:
        return _buildRoute(const FarmerProfileScreen(), settings);
      case aiAssistant:
        return _buildRoute(const AIAssistantScreen(), settings);
      case farmerAnalytics:
        return _buildRoute(const FarmerAnalyticsScreen(), settings);

      // Admin Routes
      case adminDashboard:
        return _buildRoute(const AdminDashboardScreen(), settings);
      case userManagement:
        return _buildRoute(const UserManagementScreen(), settings);
      case productManagement:
        return _buildRoute(const ProductManagementScreen(), settings);
      case orderManagement:
        return _buildRoute(const OrderManagementScreen(), settings);
      case analytics:
        return _buildRoute(const AnalyticsScreen(), settings);

      // Common Routes
      case notifications:
        return _buildRoute(const NotificationsScreen(), settings);

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(final Widget page, final RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => page,
      settings: settings,
    );
  }
}
