import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class OtpVerificationScreen extends StatefulWidget {

  const OtpVerificationScreen({
    required this.email, 
    required this.phone, 
    this.password,
    this.fullName,
    this.role,
    super.key,
  });
  final String email;
  final String phone;
  final String? password;
  final String? fullName;
  final String? role;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _otp => _controllers.map((final c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      _showError('Please enter the complete verification code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Verify email OTP and complete registration
      final success = await authProvider.verifyEmailOtp(
        email: widget.email,
        otp: _otp,
        password: widget.password ?? '',
        fullName: widget.fullName ?? '',
        phone: widget.phone,
        role: widget.role ?? 'buyer',
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

        // Navigate based on user role
        final user = authProvider.user;
        if (user?.userType == 'farmer') {
          Navigator.pushReplacementNamed(context, AppRoutes.farmerDashboard);
        } else if (user?.userType == 'admin') {
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.buyerHome);
        }
      } else {
        _showError(authProvider.errorMessage ?? 'Invalid verification code. Please try again.');
      }
    } catch (e) {
      _showError('Failed to verify code. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.resendEmailOtp(
        email: widget.email,
      );

      if (!mounted) return;

      if (success) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError('Failed to resend code. Please try again.');
      }
    } catch (e) {
      _showError('Failed to resend code. Please try again.');
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      size: 40,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Verification',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to\n${widget.email}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (final index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.grey100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryGreen,
                              width: 2,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (final value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          if (_otp.length == 6) {
                            _verifyOtp();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Verify Button
                CustomButton(
                  text: 'Verify',
                  onPressed: _verifyOtp,
                ),
                const SizedBox(height: 24),

                // Resend Code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _resendSeconds == 0 ? _resendOtp : null,
                      child: Text(
                        _resendSeconds > 0
                            ? 'Resend in ${_resendSeconds}s'
                            : 'Resend',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
