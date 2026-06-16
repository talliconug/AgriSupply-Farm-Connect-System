const axios = require('axios');
const logger = require('../utils/logger');

let sdkInstance;
let sdkLibPromise;

function isSandboxEnabled() {
  return String(process.env.EGO_SMS_USE_SANDBOX || '').toLowerCase() === 'true';
}

function getEgoCredentials() {
  const username =
    process.env.EGO_SMS_API_USERNAME ||
    process.env.EGO_SMS_USERNAME ||
    process.env.EGOSMS_USERNAME;
  const apiKey =
    process.env.EGO_SMS_API_KEY ||
    process.env.EGO_SMS_PASSWORD ||
    process.env.EGO_SMS_API_PASSWORD ||
    process.env.EGOSMS_PASSWORD;
  const senderId =
    process.env.EGO_SMS_SENDER_ID ||
    process.env.EGOSMS_SENDER_ID ||
    'EgoSMS';

  return {
    username: username?.trim(),
    apiKey: apiKey?.trim(),
    senderId,
  };
}

function getEgoApiUrl() {
  return (
    process.env.EGO_SMS_API_URL ||
    process.env.EGOSMS_API_URL ||
    (isSandboxEnabled()
      ? 'https://comms-test.pahappa.net/api/v1/json'
      : 'https://comms.egosms.co/api/v1/json')
  );
}

function normalizePhone(phoneNumber) {
  if (!phoneNumber) return '';

  const raw = String(phoneNumber).trim().replace(/\s+/g, '');

  if (raw.startsWith('+')) {
    return raw;
  }

  if (raw.startsWith('256')) {
    return `+${raw}`;
  }

  if (raw.startsWith('0') && raw.length === 10) {
    return `+256${raw.slice(1)}`;
  }

  return raw;
}

function resolveRecipients(phoneNumber) {
  const target = normalizePhone(phoneNumber);
  const testRecipients = (process.env.EGO_SMS_TEST_NUMBERS || '')
    .split(',')
    .map((n) => n.trim())
    .filter(Boolean)
    .map(normalizePhone);

  if (process.env.EGO_SMS_FORCE_TEST_MODE === 'true' && testRecipients.length > 0) {
    return testRecipients;
  }

  return [target, ...testRecipients].filter(Boolean);
}

async function getSdkLib() {
  if (!sdkLibPromise) {
    sdkLibPromise = import('comms-sdk/v1');
  }

  return sdkLibPromise;
}

async function getSdk() {
  const { username, apiKey } = getEgoCredentials();

  if (!username || !apiKey) {
    return null;
  }

  if (!sdkInstance) {
    try {
      const sdkLib = await getSdkLib();
      const { CommsSDK } = sdkLib;
      if (isSandboxEnabled()) {
        CommsSDK.useSandBox();
      }
      sdkInstance = CommsSDK.authenticate(username, apiKey);
    } catch (error) {
      logger.warn('EGO SDK import failed, using direct API fallback:', error.message);
      return null;
    }
  }

  return sdkInstance;
}

async function sendViaEgoApi(recipients, message, priority = '0') {
  const { username, apiKey, senderId } = getEgoCredentials();

  const payload = {
    method: 'SendSms',
    userdata: {
      username,
      password: apiKey,
    },
    msgdata: recipients.map((number) => ({
      number,
      message,
      senderid: senderId,
      priority,
    })),
  };

  const response = await axios.post(getEgoApiUrl(), payload, {
    timeout: 20000,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
  });

  return response.data;
}

/**
 * Send SMS using configured provider.
 * Supports egosms (preferred) and twilio.
 */
async function sendSms({ phone, message }) {
  const provider = (process.env.SMS_SERVICE || '').toLowerCase();
  const { username, apiKey } = getEgoCredentials();

  if (!provider) {
    if (username && apiKey) {
      return sendViaEgoSms({ phone, message });
    }

    logger.warn('SMS_SERVICE is not configured');
    return { ok: false, reason: 'no_provider' };
  }

  if (provider === 'egosms') {
    return sendViaEgoSms({ phone, message });
  }

  if (provider === 'twilio') {
    return sendViaTwilio({ phone, message });
  }

  logger.warn(`Unsupported SMS_SERVICE provider: ${provider}`);
  return { ok: false, reason: 'unsupported_provider' };
}

async function sendViaEgoSms({ phone, message }) {
  const { username, apiKey } = getEgoCredentials();
  if (!username || !apiKey) {
    logger.warn('EGO SMS env vars missing: EGO_SMS_API_USERNAME/EGO_SMS_API_KEY');
    return { ok: false, reason: 'missing_egosms_config' };
  }

  try {
    const recipients = resolveRecipients(phone);
    if (recipients.length === 0) {
      return { ok: false, reason: 'no_recipients' };
    }

    const sdk = await getSdk();
    if (sdk) {
      const sdkLib = await getSdkLib();
      const { models } = sdkLib;
      const priority = models?.MessagePriority?.HIGHEST;
      const { senderId } = getEgoCredentials();
      await sdk.sendSMS(recipients, message, senderId || undefined, priority);
    } else {
      const apiResult = await sendViaEgoApi(recipients, message, '0');
      if (apiResult?.Status !== 'OK') {
        const isAuthError = /wrong username or password/i.test(String(apiResult?.Message || ''));
        return {
          ok: false,
          reason: isAuthError
            ? 'egosms_auth_failed'
            : 'egosms_error',
          providerResponse: apiResult,
        };
      }
    }

    return { ok: true, recipients };
  } catch (error) {
    logger.error('EgoSMS send failed:', error.response?.data || error.message || error);
    return { ok: false, reason: 'egosms_request_failed' };
  }
}

async function sendViaTwilio({ phone, message }) {
  try {
    const twilio = require('twilio');
    const client = twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );

    await client.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phone,
    });

    return { ok: true };
  } catch (error) {
    logger.error('Twilio send failed:', error.message || error);
    return { ok: false, reason: 'twilio_request_failed' };
  }
}

module.exports = {
  sendSms,
};
