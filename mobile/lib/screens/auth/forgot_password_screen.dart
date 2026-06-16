import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/input_validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _resetToken;
  String? _devOtp;
  bool _isLoading = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null && widget.initialPhone!.trim().isNotEmpty) {
      _phoneController.text = widget.initialPhone!.trim();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (InputValidators.ugandaPhone(_phoneController.text) != null) {
      _showError(InputValidators.ugandaPhone(_phoneController.text)!);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final devOtp = await authProvider.sendPasswordResetOtp(
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _otpSent = true;
        _devOtp = devOtp;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent if this phone is registered.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      _showError('Failed to send OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      _showError('Enter a valid 6-digit OTP.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final resetToken = await authProvider.verifyPasswordResetOtp(
        phone: _phoneController.text.trim(),
        otp: _otpController.text.trim(),
      );

      if (!mounted) return;

      if (resetToken != null && resetToken.isNotEmpty) {
        setState(() {
          _otpVerified = true;
          _resetToken = resetToken;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified. Set your new password.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError(authProvider.errorMessage ?? 'Invalid or expired OTP.');
      }
    } catch (_) {
      _showError('An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_resetToken == null) {
      _showError('Verify OTP first.');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ok = await authProvider.confirmPasswordResetWithOtp(
        phone: _phoneController.text.trim(),
        resetToken: _resetToken!,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful. Please sign in.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        _showError(authProvider.errorMessage ?? 'Failed to reset password');
      }
    } catch (_) {
      _showError('An unexpected error occurred');
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
                        Icons.mark_email_read_outlined,
                        size: 40,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Forgot Password?',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reset with phone OTP. We send a 6-digit code via SMS.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'e.g. 0772123456',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: InputValidators.ugandaPhone,
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _otpController,
                      label: 'OTP Code',
                      hint: 'Enter 6-digit OTP',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.verified_user_outlined,
                      maxLength: 6,
                    ),
                    if (_devOtp != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Dev OTP: $_devOtp',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey600,
                            ),
                      ),
                    ],
                  ],
                  if (_otpVerified) ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _newPasswordController,
                      label: 'New Password',
                      hint: 'Enter new password',
                      obscureText: _obscureNewPassword,
                      prefixIcon: Icons.lock_outline,
                      validator: InputValidators.password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureNewPassword = !_obscureNewPassword);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter new password',
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: Icons.lock_reset_outlined,
                      validator: InputValidators.password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (!_otpSent)
                    CustomButton(
                      text: 'Send OTP',
                      onPressed: _handleSendOtp,
                    )
                  else if (!_otpVerified)
                    CustomButton(
                      text: 'Verify OTP',
                      onPressed: _handleVerifyOtp,
                    )
                  else
                    CustomButton(
                      text: 'Reset Password',
                      onPressed: _handleResetPassword,
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
