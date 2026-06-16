const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/errorMiddleware');
const { authValidators } = require('../utils/validators');

/**
 * @route   POST /api/v1/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post(
  '/register',
  authValidators.register,
  handleValidation,
  authController.register
);

/**
 * @route   POST /api/v1/auth/login
 * @desc    Login user with email and password
 * @access  Public
 */
router.post(
  '/login',
  authValidators.login,
  handleValidation,
  authController.login
);

/**
 * @route   POST /api/v1/auth/google
 * @desc    Login/Register with Google
 * @access  Public
 */
router.post('/google', authController.googleAuth);

/**
 * @route   POST /api/v1/auth/phone/send-otp
 * @desc    Send OTP to phone number
 * @access  Public
 */
router.post(
  '/phone/send-otp',
  authValidators.phoneOtp,
  handleValidation,
  authController.sendPhoneOTP
);

/**
 * @route   POST /api/v1/auth/phone/verify-otp
 * @desc    Verify phone OTP
 * @access  Public
 */
router.post(
  '/phone/verify-otp',
  authValidators.verifyOtp,
  handleValidation,
  authController.verifyPhoneOTP
);

/**
 * @route   POST /api/v1/auth/forgot-password
 * @desc    Send password reset email
 * @access  Public
 */
router.post(
  '/forgot-password',
  authValidators.resetPassword,
  handleValidation,
  authController.forgotPassword
);

/**
 * @route   POST /api/v1/auth/password-reset/send-otp
 * @desc    Send password reset OTP to phone
 * @access  Public
 */
router.post(
  '/password-reset/send-otp',
  authValidators.passwordResetSendOtp,
  handleValidation,
  authController.sendPasswordResetOtp
);

/**
 * @route   POST /api/v1/auth/password-reset/verify-otp
 * @desc    Verify password reset OTP
 * @access  Public
 */
router.post(
  '/password-reset/verify-otp',
  authValidators.passwordResetVerifyOtp,
  handleValidation,
  authController.verifyPasswordResetOtp
);

/**
 * @route   POST /api/v1/auth/password-reset/confirm
 * @desc    Confirm password reset using verified reset token
 * @access  Public
 */
router.post(
  '/password-reset/confirm',
  authValidators.passwordResetConfirm,
  handleValidation,
  authController.confirmPasswordResetWithOtp
);

/**
 * @route   POST /api/v1/auth/reset-password
 * @desc    Reset password with token
 * @access  Public
 */
router.post('/reset-password', authController.resetPassword);

/**
 * @route   POST /api/v1/auth/refresh-token
 * @desc    Refresh access token
 * @access  Public
 */
router.post('/refresh-token', authController.refreshToken);

/**
 * @route   POST /api/v1/auth/logout
 * @desc    Logout user
 * @access  Private
 */
router.post('/logout', authenticate, authController.logout);

/**
 * @route   PUT /api/v1/auth/password
 * @desc    Update password
 * @access  Private
 */
router.put(
  '/password',
  authenticate,
  authValidators.updatePassword,
  handleValidation,
  authController.updatePassword
);

/**
 * @route   GET /api/v1/auth/me
 * @desc    Get current user
 * @access  Private
 */
router.get('/me', authenticate, authController.getCurrentUser);

/**
 * @route   DELETE /api/v1/auth/account
 * @desc    Delete user account
 * @access  Private
 */
router.delete('/account', authenticate, authController.deleteAccount);

module.exports = router;
