import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/input_validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedUserType = 'buyer';
  bool _agreeToTerms = false;

  final List<Map<String, dynamic>> _userTypes = [
    {
      'value': 'buyer',
      'label': 'Buyer',
      'icon': Icons.shopping_bag_outlined,
      'description': 'I want to buy fresh produce',
    },
    {
      'value': 'farmer',
      'label': 'Farmer',
      'icon': Icons.agriculture_outlined,
      'description': 'I want to sell my produce',
    },
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showError('Please agree to the Terms & Conditions');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Sign up directly without email verification
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedUserType,
      );

      if (!mounted) return;

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to appropriate home screen based on role
        if (_selectedUserType == 'farmer') {
          Navigator.pushReplacementNamed(context, AppRoutes.farmerDashboard);
        } else if (_selectedUserType == 'admin') {
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.buyerHome);
        }
      } else {
        _showError(authProvider.errorMessage ?? 'Registration failed. Please try again.');
      }
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.grey900),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join AgriSupply to connect with farmers and buyers',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // User Type Selection
                  Text(
                    'I am a...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _userTypes.map((final type) {
                      final isSelected = _selectedUserType == (type['value'] as String);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedUserType = type['value'] as String);
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                              right: (type['value'] as String) == 'buyer' ? 8 : 0,
                              left: (type['value'] as String) == 'farmer' ? 8 : 0,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryGreen.withOpacity(0.1)
                                  : AppColors.grey100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  type['icon'] as IconData,
                                  size: 32,
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : AppColors.grey600,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  type['label'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : AppColors.grey800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type['description'] as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.grey500,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Full Name Field
                  CustomTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    prefixIcon: Icons.person_outlined,
                    validator: (final value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

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

                  // Phone Field
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'e.g., +256 700 123 456',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: InputValidators.ugandaPhone,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Create a password',
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
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Confirm your password',
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.grey500,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    validator: (final value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Terms Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (final value) {
                          setState(() => _agreeToTerms = value ?? false);
                        },
                        activeColor: AppColors.primaryGreen,
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodySmall,
                            children: const [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  CustomButton(
                    text: 'Create Account',
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Sign In'),
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
