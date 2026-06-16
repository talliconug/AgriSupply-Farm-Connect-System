import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'config/app_config.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'services/local_notification_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Initialize local popup notifications
  await LocalNotificationService.init();

  runApp(const AgriSupplyApp());
}

class AgriSupplyApp extends StatefulWidget {
  const AgriSupplyApp({super.key});

  @override
  State<AgriSupplyApp> createState() => _AgriSupplyAppState();
}

class _AgriSupplyAppState extends State<AgriSupplyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  Future<void> _initializeDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (_) {}

    _deepLinkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(final Uri uri) {
    final isResetRoute =
        uri.path.contains('reset-password') || uri.host.contains('reset-password');
    if (!isResetRoute) return;

    final phone = uri.queryParameters['phone'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushNamed(
        AppRoutes.forgotPassword,
        arguments: {
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone,
        },
      );
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'AgriSupply Farm Connect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

// Global Supabase client accessor
final supabase = Supabase.instance.client;
