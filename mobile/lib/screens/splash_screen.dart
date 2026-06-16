import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../main.dart';
import '../providers/notification_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future<void>.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final session = supabase.auth.currentSession;

    if (session != null) {
      // User is logged in, fetch user data and navigate accordingly
      try {
        final userData = await supabase
            .from('users')
            .select()
            .eq('id', session.user.id)
            .single();

        final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.fetchNotifications(session.user.id);
        notificationProvider.subscribeToNotifications(session.user.id);

        if (!mounted) return;

        final userType =
          (userData['user_type'] ?? userData['role'] ?? 'buyer') as String;

        switch (userType) {
          case 'farmer':
            Navigator.pushReplacementNamed(context, AppRoutes.farmerDashboard);
            break;
          case 'admin':
            Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
            break;
          default:
            Navigator.pushReplacementNamed(context, AppRoutes.buyerHome);
        }
      } catch (e) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (final context, final child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco,
                        size: 60,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'AgriSupply',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Farm Connect System',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
