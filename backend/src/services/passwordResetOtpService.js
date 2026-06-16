const crypto = require('crypto');
const { generateOTP } = require('../utils/helpers');

const OTP_EXPIRY_MS = 5 * 60 * 1000;
const RESEND_COOLDOWN_MS = 45 * 1000;
const MAX_VERIFY_ATTEMPTS = 5;
const TOKEN_EXPIRY_MS = 10 * 60 * 1000;

const otpStore = new Map();
const tokenStore = new Map();

function hashOtp(phone, otp) {
  return crypto
    .createHash('sha256')
    .update(`${phone}:${otp}`)
    .digest('hex');
}

function issueOtp(phone, userId) {
  const now = Date.now();
  const existing = otpStore.get(phone);

  if (existing && now - existing.sentAt < RESEND_COOLDOWN_MS) {
    return {
      ok: false,
      reason: 'cooldown',
      retryAfterSeconds: Math.ceil((RESEND_COOLDOWN_MS - (now - existing.sentAt)) / 1000),
    };
  }

  const otp = generateOTP(6).padEnd(6, '0').slice(0, 6);
  otpStore.set(phone, {
    userId,
    otpHash: hashOtp(phone, otp),
    sentAt: now,
    expiresAt: now + OTP_EXPIRY_MS,
    attempts: 0,
    verified: false,
  });

  return { ok: true, otp };
}

function verifyOtp(phone, otp) {
  const record = otpStore.get(phone);
  if (!record) return { ok: false, reason: 'not_found' };

  const now = Date.now();
  if (record.expiresAt < now) {
    otpStore.delete(phone);
    return { ok: false, reason: 'expired' };
  }

  if (record.attempts >= MAX_VERIFY_ATTEMPTS) {
    otpStore.delete(phone);
    return { ok: false, reason: 'too_many_attempts' };
  }

  if (record.otpHash !== hashOtp(phone, otp)) {
    record.attempts += 1;
    otpStore.set(phone, record);
    return { ok: false, reason: 'invalid_otp' };
  }

  record.verified = true;
  otpStore.set(phone, record);

  const resetToken = crypto.randomBytes(24).toString('hex');
  tokenStore.set(resetToken, {
    phone,
    userId: record.userId,
    expiresAt: now + TOKEN_EXPIRY_MS,
  });

  return { ok: true, resetToken };
}

function consumeResetToken(phone, token) {
  const record = tokenStore.get(token);
  if (!record) return { ok: false, reason: 'invalid_token' };

  if (record.phone !== phone) {
    return { ok: false, reason: 'invalid_token' };
  }

  if (record.expiresAt < Date.now()) {
    tokenStore.delete(token);
    return { ok: false, reason: 'expired_token' };
  }

  tokenStore.delete(token);
  otpStore.delete(phone);
  return { ok: true, userId: record.userId };
}

module.exports = {
  issueOtp,
  verifyOtp,
  consumeResetToken,
};
