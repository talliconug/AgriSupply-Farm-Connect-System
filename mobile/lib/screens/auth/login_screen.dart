import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/input_validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result) {
        final userType = authProvider.currentUser?.userType ?? 'buyer';

        if (userType == 'admin' &&
            _emailController.text.trim().toLowerCase() == 'admin@agrisupply.ug' &&
            _passwordController.text == 'admin1234') {
          final changed = await _forceAdminPasswordChange(authProvider);
          if (!changed) {
            return;
          }
        }

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
      } else {
        _showError('Login failed. Please try again.');
      }
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _forceAdminPasswordChange(final AuthProvider authProvider) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (final context) => AlertDialog(
        title: const Text('Change Default Admin Password'),
        content: Form(
          key: formKey,
          child: CustomTextField(
            controller: controller,
            label: 'New Password',
            hint: 'Create a secure password',
            obscureText: true,
            validator: (final value) =>
                InputValidators.password(value, label: 'a new password'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = await authProvider.updatePassword(
                newPassword: controller.text.trim(),
              );
              if (!mounted) return;
              if (ok) {
                Navigator.pop(context, true);
              } else {
                _showError(authProvider.errorMessage ?? 'Failed to update password');
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
    controller.dispose();
    return changed ?? false;
  }

  void _showError(final String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo and Title
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.eco,
                        size: 40,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome Back!',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue to AgriSupply',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: InputValidators.email,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.grey500,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: InputValidators.password,
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.forgotPassword);
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  CustomButton(
                    text: 'Sign In',
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
