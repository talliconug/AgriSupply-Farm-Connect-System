const { supabase, supabaseAnon } = require('../config/supabase');
const { ApiError, asyncHandler } = require('../middleware/errorMiddleware');
const { formatPhoneNumber, sanitizeUser } = require('../utils/helpers');
const logger = require('../utils/logger');
const { sendSms } = require('../services/smsProviderService');
const {
  issueOtp,
  verifyOtp: verifyResetOtpCode,
  consumeResetToken,
} = require('../services/passwordResetOtpService');

const DEFAULT_ADMIN_EMAIL = process.env.DEFAULT_ADMIN_EMAIL || 'admin@agrisupply.ug';
const DEFAULT_ADMIN_PASSWORD = process.env.DEFAULT_ADMIN_PASSWORD || 'admin1234';

const buildProfileFromAuthUser = async ({ user, fallback = {} }) => {
  const metadata = user?.user_metadata || {};
  const fullName = metadata.full_name || fallback.fullName || user?.email?.split('@')[0] || 'User';
  const role = metadata.role || fallback.role || 'buyer';
  const rawPhone = metadata.phone || fallback.phone || null;
  const formattedPhone = rawPhone ? formatPhoneNumber(rawPhone) : null;

  const payload = {
    id: user.id,
    email: user.email,
    full_name: fullName,
    role,
    region: fallback.region || null,
    district: fallback.district || null,
    farm_name: fallback.farmName || null,
    is_verified: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  if (formattedPhone) {
    payload.phone = formattedPhone;
  }

  const { data, error } = await supabase
    .from('users')
    .upsert(payload, { onConflict: 'id' })
    .select('*')
    .single();

  if (error || !data) {
    logger.error('Failed to build profile from auth user:', error);
    throw new ApiError(500, 'Failed to create user profile');
  }

  return data;
};

/**
 * @desc    Register a new user
 * @route   POST /api/v1/auth/register
 */
const register = asyncHandler(async (req, res) => {
  const { email, password, fullName, role = 'buyer', phone } = req.body;

  // Create user in Supabase Auth (trigger will create profile automatically)
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      full_name: fullName,
      role,
      phone: formatPhoneNumber(phone),
    },
  });

  if (authError) {
    logger.error('Auth registration error:', authError);
    throw new ApiError(400, authError.message);
  }

  // Wait briefly for trigger to create profile (2s for Supabase trigger execution)
  await new Promise(resolve => setTimeout(resolve, 2000));

  // Fetch the profile created by the database trigger
  const { data: profile, error: profileError } = await supabase
    .from('users')
    .select('*')
    .eq('id', authData.user.id)
    .single();

  if (profileError || !profile) {
    logger.warn('Profile missing after registration trigger; attempting fallback profile creation');
    profile = await buildProfileFromAuthUser({
      user: authData.user,
      fallback: {
        fullName,
        role,
        phone,
      },
    });
  }

  // Create default notification preferences
  await supabase.from('notification_preferences').insert({
    user_id: authData.user.id,
    order_updates: true,
    promotions: true,
    farming_tips: role === 'farmer',
    price_alerts: true,
  });

  // Generate session
  const { data: sessionData, error: sessionError } = await supabase.auth.admin.generateLink({
    type: 'magiclink',
    email,
  });

  res.status(201).json({
    success: true,
    message: 'Registration successful',
    data: {
      user: sanitizeUser(profile),
      token: authData.user?.access_token,
    },
  });
});

/**
 * @desc    Login user
 * @route   POST /api/v1/auth/login
 */
const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  const { data, error } = await supabaseAnon.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    logger.error('Login error:', error);
    throw new ApiError(401, 'Invalid email or password');
  }

  // Get user profile
  const { data: profile, error: profileError } = await supabase
    .from('users')
    .select('*')
    .eq('id', data.user.id)
    .single();

  if (profileError || !profile) {
    logger.warn(`Profile missing at login for user ${data.user.id}; attempting fallback profile creation`);
    profile = await buildProfileFromAuthUser({ user: data.user });
  }

  // Check if user is suspended
  if (profile.is_suspended) {
    throw new ApiError(403, 'Your account has been suspended. Please contact support.');
  }

  // Update last login
  await supabase
    .from('users')
    .update({ last_login_at: new Date().toISOString() })
    .eq('id', data.user.id);

  const mustChangePassword =
    profile.role === 'admin'
    && email.toLowerCase() === DEFAULT_ADMIN_EMAIL.toLowerCase()
    && password === DEFAULT_ADMIN_PASSWORD;

  res.json({
    success: true,
    message: 'Login successful',
    data: {
      user: sanitizeUser(profile),
      token: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresAt: data.session.expires_at,
      mustChangePassword,
    },
  });
});

/**
 * @desc    Google authentication
 * @route   POST /api/v1/auth/google
 */
const googleAuth = asyncHandler(async (req, res) => {
  const { idToken, role = 'buyer' } = req.body;

  if (!idToken) {
    throw new ApiError(400, 'Google ID token is required');
  }

  // Verify Google token with Supabase
  const { data, error } = await supabase.auth.signInWithIdToken({
    provider: 'google',
    token: idToken,
  });

  if (error) {
    logger.error('Google auth error:', error);
    throw new ApiError(401, 'Google authentication failed');
  }

  // Check if user profile exists
  let { data: profile, error: profileError } = await supabase
    .from('users')
    .select('*')
    .eq('id', data.user.id)
    .single();

  // Create profile if it doesn't exist
  if (profileError || !profile) {
    const { data: newProfile, error: createError } = await supabase
      .from('users')
      .insert({
        id: data.user.id,
        email: data.user.email,
        full_name: data.user.user_metadata.full_name || data.user.email.split('@')[0],
        photo_url: data.user.user_metadata.avatar_url,
        role,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (createError) {
      logger.error('Profile creation error:', createError);
      throw new ApiError(400, 'Failed to create user profile');
    }

    profile = newProfile;

    // Create default notification preferences
    await supabase.from('notification_preferences').insert({
      user_id: data.user.id,
      order_updates: true,
      promotions: true,
      farming_tips: role === 'farmer',
      price_alerts: true,
    });
  }

  res.json({
    success: true,
    message: 'Google authentication successful',
    data: {
      user: sanitizeUser(profile),
      token: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresAt: data.session.expires_at,
      isNewUser: !profileError,
    },
  });
});

/**
 * @desc    Send OTP to phone
 * @route   POST /api/v1/auth/phone/send-otp
 */
const sendPhoneOTP = asyncHandler(async (req, res) => {
  const { phone } = req.body;
  const formattedPhone = formatPhoneNumber(phone);

  if (!formattedPhone) {
    throw new ApiError(400, 'Invalid phone number');
  }

  const { error } = await supabase.auth.signInWithOtp({
    phone: formattedPhone,
  });

  if (error) {
    logger.error('Send OTP error:', error);
    throw new ApiError(400, 'Failed to send OTP');
  }

  res.json({
    success: true,
    message: 'OTP sent successfully',
    data: {
      phone: formattedPhone,
    },
  });
});

/**
 * @desc    Verify phone OTP
 * @route   POST /api/v1/auth/phone/verify-otp
 */
const verifyPhoneOTP = asyncHandler(async (req, res) => {
  const { phone, otp, role = 'buyer' } = req.body;
  const formattedPhone = formatPhoneNumber(phone);

  if (!formattedPhone) {
    throw new ApiError(400, 'Invalid phone number');
  }

  const { data, error } = await supabase.auth.verifyOtp({
    phone: formattedPhone,
    token: otp,
    type: 'sms',
  });

  if (error) {
    logger.error('Verify OTP error:', error);
    throw new ApiError(400, 'Invalid or expired OTP');
  }

  // Check if user profile exists
  let { data: profile } = await supabase
    .from('users')
    .select('*')
    .eq('id', data.user.id)
    .single();

  // Create profile if it doesn't exist
  if (!profile) {
    const { data: newProfile, error: createError } = await supabase
      .from('users')
      .insert({
        id: data.user.id,
        phone: formattedPhone,
        role,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (createError) {
      logger.error('Profile creation error:', createError);
      throw new ApiError(400, 'Failed to create user profile');
    }

    profile = newProfile;
  }

  res.json({
    success: true,
    message: 'Phone verified successfully',
    data: {
      user: sanitizeUser(profile),
      token: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresAt: data.session.expires_at,
    },
  });
});

/**
 * @desc    Forgot password
 * @route   POST /api/v1/auth/forgot-password
 */
const forgotPassword = asyncHandler(async (req, res) => {
  const { email } = req.body;

  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${process.env.FRONTEND_URL}/reset-password`,
  });

  if (error) {
    logger.error('Forgot password error:', error);
    // Don't reveal if email exists
  }

  res.json({
    success: true,
    message: 'If an account exists with this email, a password reset link has been sent.',
  });
});

/**
 * @desc    Send password reset OTP via SMS
 * @route   POST /api/v1/auth/password-reset/send-otp
 */
const sendPasswordResetOtp = asyncHandler(async (req, res) => {
  const { phone } = req.body;
  const formattedPhone = formatPhoneNumber(phone);

  if (!formattedPhone) {
    throw new ApiError(400, 'Invalid phone number');
  }

  const { data: user } = await supabase
    .from('users')
    .select('id, phone')
    .eq('phone', formattedPhone)
    .eq('is_deleted', false)
    .maybeSingle();

  // Avoid account enumeration by always returning success-like response.
  if (!user) {
    return res.json({
      success: true,
      message: 'If this phone is registered, an OTP has been sent.',
    });
  }

  const issued = issueOtp(formattedPhone, user.id);
  if (!issued.ok) {
    if (issued.reason === 'cooldown') {
      throw new ApiError(429, `Please wait ${issued.retryAfterSeconds}s before requesting another OTP`);
    }
    throw new ApiError(400, 'Could not generate OTP');
  }

  const smsMessage = `AgriSupply password reset code: ${issued.otp}. Expires in 5 minutes.`;
  const smsResult = await sendSms({
    phone: formattedPhone,
    message: smsMessage,
  });

  if (!smsResult.ok) {
    logger.error('Failed to send password reset OTP:', smsResult);
    throw new ApiError(500, 'Failed to send OTP. Please try again.');
  }

  const responseData = {};
  if (process.env.NODE_ENV !== 'production') {
    responseData.devOtp = issued.otp;
  }

  res.json({
    success: true,
    message: 'If this phone is registered, an OTP has been sent.',
    data: responseData,
  });
});

/**
 * @desc    Verify password reset OTP
 * @route   POST /api/v1/auth/password-reset/verify-otp
 */
const verifyPasswordResetOtp = asyncHandler(async (req, res) => {
  const { phone, otp } = req.body;
  const formattedPhone = formatPhoneNumber(phone);

  if (!formattedPhone) {
    throw new ApiError(400, 'Invalid phone number');
  }

  const verification = verifyResetOtpCode(formattedPhone, otp);
  if (!verification.ok) {
    throw new ApiError(400, 'Invalid or expired OTP');
  }

  res.json({
    success: true,
    message: 'OTP verified successfully',
    data: {
      resetToken: verification.resetToken,
    },
  });
});

/**
 * @desc    Complete password reset using verified OTP token
 * @route   POST /api/v1/auth/password-reset/confirm
 */
const confirmPasswordResetWithOtp = asyncHandler(async (req, res) => {
  const { phone, resetToken, newPassword } = req.body;
  const formattedPhone = formatPhoneNumber(phone);

  if (!formattedPhone) {
    throw new ApiError(400, 'Invalid phone number');
  }

  if (!resetToken || !newPassword) {
    throw new ApiError(400, 'Phone, reset token, and new password are required');
  }

  const consumed = consumeResetToken(formattedPhone, resetToken);
  if (!consumed.ok) {
    throw new ApiError(400, 'Invalid or expired reset session');
  }

  const { error } = await supabase.auth.admin.updateUserById(consumed.userId, {
    password: newPassword,
  });

  if (error) {
    logger.error('Password reset by OTP failed:', error);
    throw new ApiError(400, 'Failed to reset password');
  }

  res.json({
    success: true,
    message: 'Password reset successful. You can now log in with your new password.',
  });
});

/**
 * @desc    Reset password
 * @route   POST /api/v1/auth/reset-password
 */
const resetPassword = asyncHandler(async (req, res) => {
  const { token, password } = req.body;

  if (!token || !password) {
    throw new ApiError(400, 'Token and password are required');
  }

  const { error } = await supabase.auth.updateUser({
    password,
  });

  if (error) {
    logger.error('Reset password error:', error);
    throw new ApiError(400, 'Failed to reset password');
  }

  res.json({
    success: true,
    message: 'Password reset successful',
  });
});

/**
 * @desc    Refresh token
 * @route   POST /api/v1/auth/refresh-token
 */
const refreshToken = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    throw new ApiError(400, 'Refresh token is required');
  }

  const { data, error } = await supabase.auth.refreshSession({
    refresh_token: refreshToken,
  });

  if (error) {
    logger.error('Refresh token error:', error);
    throw new ApiError(401, 'Invalid or expired refresh token');
  }

  res.json({
    success: true,
    data: {
      token: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresAt: data.session.expires_at,
    },
  });
});

/**
 * @desc    Logout user
 * @route   POST /api/v1/auth/logout
 */
const logout = asyncHandler(async (req, res) => {
  const { error } = await supabase.auth.signOut();

  if (error) {
    logger.error('Logout error:', error);
  }

  res.json({
    success: true,
    message: 'Logged out successfully',
  });
});

/**
 * @desc    Update password
 * @route   PUT /api/v1/auth/password
 */
const updatePassword = asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.body;

  // Verify current password by re-authenticating
  const { error: verifyError } = await supabase.auth.signInWithPassword({
    email: req.user.email,
    password: currentPassword,
  });

  if (verifyError) {
    throw new ApiError(401, 'Current password is incorrect');
  }

  // Update password
  const { error } = await supabase.auth.updateUser({
    password: newPassword,
  });

  if (error) {
    logger.error('Update password error:', error);
    throw new ApiError(400, 'Failed to update password');
  }

  res.json({
    success: true,
    message: 'Password updated successfully',
  });
});

/**
 * @desc    Get current user
 * @route   GET /api/v1/auth/me
 */
const getCurrentUser = asyncHandler(async (req, res) => {
  res.json({
    success: true,
    data: {
      user: sanitizeUser(req.user),
    },
  });
});

/**
 * @desc    Delete user account
 * @route   DELETE /api/v1/auth/account
 */
const deleteAccount = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  // Delete user profile and related data
  await supabase.from('notification_preferences').delete().eq('user_id', userId);
  await supabase.from('notifications').delete().eq('user_id', userId);
  await supabase.from('users').delete().eq('id', userId);

  // Delete auth user
  const { error } = await supabase.auth.admin.deleteUser(userId);

  if (error) {
    logger.error('Delete account error:', error);
    throw new ApiError(400, 'Failed to delete account');
  }

  res.json({
    success: true,
    message: 'Account deleted successfully',
  });
});

module.exports = {
  register,
  login,
  googleAuth,
  sendPhoneOTP,
  verifyPhoneOTP,
  forgotPassword,
  sendPasswordResetOtp,
  verifyPasswordResetOtp,
  confirmPasswordResetWithOtp,
  resetPassword,
  refreshToken,
  logout,
  updatePassword,
  getCurrentUser,
  deleteAccount,
};
