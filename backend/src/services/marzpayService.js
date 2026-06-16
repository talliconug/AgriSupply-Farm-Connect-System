const axios = require('axios');
const logger = require('../utils/logger');
const { ApiError } = require('../middleware/errorMiddleware');
const { v4: uuidv4 } = require('uuid');

/**
 * MarzPay Payment Gateway Service
 * Handles mobile money payments for MTN & Airtel Uganda via MarzPay API
 */

const MARZPAY_API_URL = process.env.MARZPAY_API_URL || 'https://wallet.wearemarz.com/api/v1';
const MARZPAY_API_KEY = process.env.MARZPAY_API_KEY;
const MARZPAY_API_SECRET = process.env.MARZPAY_API_SECRET;

// Create Basic Auth credentials
const getAuthHeader = () => {
  const credentials = Buffer.from(`${MARZPAY_API_KEY}:${MARZPAY_API_SECRET}`).toString('base64');
  return `Basic ${credentials}`;
};

// Axios instance with default MarzPay headers
const marzpayClient = axios.create({
  baseURL: MARZPAY_API_URL,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  timeout: 30000, // 30 seconds
});

// Add auth header to every request
marzpayClient.interceptors.request.use((config) => {
  config.headers.Authorization = getAuthHeader();
  return config;
});

/**
 * Request payment from mobile money subscriber (Collection)
 * @param {Object} params - Payment parameters
 * @param {string} params.reference - Unique transaction reference (UUID format)
 * @param {string} params.phoneNumber - Phone number (internationally formatted: +256...)
 * @param {string} params.country - Country code (UG)
 * @param {number} params.amount - Amount to charge (500 - 10,000,000)
 * @param {string} params.description - Payment description
 * @param {string} params.callbackUrl - Webhook callback URL (optional)
 */
const collectMoney = async ({ reference, phoneNumber, country = 'UG', amount, description, callbackUrl }) => {
  try {
    // Validate inputs
    if (!reference) {
      reference = uuidv4(); // Generate UUID if not provided
    }

    if (!phoneNumber || !phoneNumber.startsWith('+256')) {
      throw new ApiError(400, 'Invalid phone number format. Use international format: +256...');
    }

    if (!amount || amount < 500 || amount > 10000000) {
      throw new ApiError(400, 'Amount must be between 500 and 10,000,000 UGX');
    }

    logger.info(`MarzPay: Collecting ${amount} UGX from ${phoneNumber}`);

    const requestData = {
      amount: parseFloat(amount),
      phone_number: phoneNumber,
      country: country,
      reference: reference,
      description: description || 'Payment',
    };

    if (callbackUrl) {
      requestData.callback_url = callbackUrl;
    }

    const response = await marzpayClient.post('/collect-money', requestData);

    if (response.data.status === 'success') {
      const data = response.data.data;
      logger.info('MarzPay collection request initiated:', data);
      return {
        success: true,
        message: response.data.message,
        uuid: data.transaction.uuid,
        reference: data.transaction.reference,
        status: data.transaction.status,
        provider: data.collection.provider,
        providerReference: data.transaction.provider_reference,
        amount: data.collection.amount.raw,
        currency: data.collection.amount.currency,
      };
    }

    throw new ApiError(400, response.data.message || 'Collection request failed');
  } catch (error) {
    if (error.response?.status === 422) {
      const errors = error.response.data.errors;
      const errorMessage = errors ? Object.values(errors).flat().join(', ') : 'Validation error';
      throw new ApiError(422, errorMessage);
    }

    logger.error('MarzPay collection error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || error.message || 'Payment collection failed'
    );
  }
};

/**
 * Send payment to mobile money subscriber (Disbursement)
 * @param {Object} params - Payment parameters  
 * @param {string} params.reference - Unique transaction reference (UUID format)
 * @param {string} params.phoneNumber - Recipient phone number
 * @param {string} params.country - Country code (UG)
 * @param {number} params.amount - Amount to send (500 - 10,000,000)
 * @param {string} params.description - Payment description
 * @param {string} params.callbackUrl - Webhook callback URL (optional)
 */
const sendMoney = async ({ reference, phoneNumber, country = 'UG', amount, description, callbackUrl }) => {
  try {
    if (!reference) {
      reference = uuidv4(); // Generate UUID if not provided
    }

    logger.info(`MarzPay: Sending ${amount} UGX to ${phoneNumber}`);

    const requestData = {
      amount: parseFloat(amount),
      phone_number: phoneNumber,
      country: country,
      reference: reference,
      description: description || 'Payout',
    };

    if (callbackUrl) {
      requestData.callback_url = callbackUrl;
    }

    const response = await marzpayClient.post('/send-money', requestData);

    if (response.data.status === 'success') {
      const data = response.data.data;
      logger.info('MarzPay send money initiated:', data);
      return {
        success: true,
        message: response.data.message,
        uuid: data.transaction.uuid,
        reference: data.transaction.reference,
        status: data.transaction.status,
        provider: data.disbursement.provider,
        providerReference: data.transaction.provider_reference,
        amount: data.disbursement.amount.raw,
        currency: data.disbursement.amount.currency,
      };
    }

    throw new ApiError(400, response.data.message || 'Send money request failed');
  } catch (error) {
    logger.error('MarzPay send money error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || error.message || 'Payment send failed'
    );
  }
};

/**
 * Get collection details
 * @param {string} uuid - Transaction UUID
 */
const getCollectionDetails = async (uuid) => {
  try {
    const response = await marzpayClient.get(`/collect-money/${uuid}`);

    if (response.data.status === 'success') {
      const data = response.data.data;
      return {
        success: true,
        uuid: data.transaction.uuid,
        reference: data.transaction.reference,
        status: data.transaction.status,
        provider: data.collection.provider,
        providerReference: data.transaction.provider_reference,
        phoneNumber: data.collection.phone_number,
        amount: data.collection.amount.raw,
        currency: data.collection.amount.currency,
        description: data.collection.description,
        createdAt: data.timeline.created_at,
        updatedAt: data.timeline.updated_at,
      };
    }

    return {
      success: false,
      message: 'Failed to fetch collection details',
    };
  } catch (error) {
    logger.error('MarzPay get collection error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || 'Failed to get collection details'
    );
  }
};

/**
 * Get send money details
 * @param {string} uuid - Transaction UUID
 */
const getSendMoneyDetails = async (uuid) => {
  try {
    const response = await marzpayClient.get(`/send-money/${uuid}`);

    if (response.data.status === 'success') {
      const data = response.data.data;
      return {
        success: true,
        uuid: data.transaction.uuid,
        reference: data.transaction.reference,
        status: data.transaction.status,
        provider: data.disbursement.provider,
        providerReference: data.transaction.provider_reference,
        phoneNumber: data.disbursement.phone_number,
        amount: data.disbursement.amount.raw,
        currency: data.disbursement.amount.currency,
        description: data.disbursement.description,
        createdAt: data.timeline.created_at,
        updatedAt: data.timeline.updated_at,
      };
    }

    return {
      success: false,
      message: 'Failed to fetch send money details',
    };
  } catch (error) {
    logger.error('MarzPay get send money error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || 'Failed to get send money details'
    );
  }
};

/**
 * Check transaction status by UUID
 * @param {string} uuid - Transaction UUID
 */
const checkTransactionStatus = async (uuid) => {
  try {
    const response = await marzpayClient.get(`/transactions/${uuid}`);

    if (response.data) {
      const transaction = response.data.transaction;
      const collection = response.data.collection;
      const disbursement = response.data.disbursement;

      return {
        success: true,
        uuid: transaction.uuid,
        reference: transaction.reference,
        status: transaction.status,
        provider: collection?.provider || disbursement?.provider,
        providerReference: transaction.provider_reference,
        phoneNumber: collection?.phone_number || disbursement?.phone_number,
        amount: collection?.amount.raw || disbursement?.amount.raw,
        currency: collection?.amount.currency || disbursement?.amount.currency,
        description: transaction.description,
        createdAt: transaction.created_at,
        updatedAt: transaction.updated_at,
      };
    }

    return {
      success: false,
      status: 'unknown',
      message: 'Status check failed',
    };
  } catch (error) {
    logger.error('MarzPay status check error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || 'Status check failed'
    );
  }
};

/**
 * Get wallet balance
 */
const getWalletBalance = async () => {
  try {
    const response = await marzpayClient.get('/balance');

    if (response.data.status === 'success') {
      const data = response.data.data;
      return {
        success: true,
        balance: data.account.balance.raw,
        formattedBalance: data.account.balance.formatted,
        currency: data.account.balance.currency,
        businessName: data.account.business_name,
        accountStatus: data.account.status.account_status,
        isFrozen: data.account.status.is_frozen,
      };
    }

    return {
      success: false,
      message: 'Balance check failed',
    };
  } catch (error) {
    logger.error('MarzPay balance check error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || 'Balance check failed'
    );
  }
};

/**
 * Get transaction history
 * @param {Object} params - Query parameters
 * @param {number} params.page - Page number
 * @param {number} params.perPage - Items per page (1-100)
 * @param {string} params.type - Transaction type (collection, withdrawal)
 * @param {string} params.status - Transaction status (pending, processing, successful, failed)
 * @param {string} params.provider - Provider (mtn, airtel)
 * @param {string} params.startDate - Start date (YYYY-MM-DD)
 * @param {string} params.endDate - End date (YYYY-MM-DD)
 */
const getTransactionHistory = async (params = {}) => {
  try {
    const response = await marzpayClient.get('/transactions', { params });

    if (response.data.status === 'success') {
      const data = response.data.data;
      return {
        success: true,
        transactions: data.transactions,
        pagination: data.pagination,
        filters: data.filters,
      };
    }

    return {
      success: false,
      transactions: [],
    };
  } catch (error) {
    logger.error('MarzPay transaction history error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || 'Failed to fetch transaction history'
    );
  }
};

/**
 * Get available collection services
 */
const getCollectionServices = async () => {
  try {
    const response = await marzpayClient.get('/collect-money/services');

    if (response.data.status === 'success') {
      return {
        success: true,
        countries: response.data.data.countries,
        summary: response.data.data.summary,
      };
    }

    return {
      success: false,
      countries: {},
    };
  } catch (error) {
    logger.error('MarzPay collection services error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || 'Failed to fetch collection services'
    );
  }
};

/**
 * Get available send money services
 */
const getSendMoneyServices = async () => {
  try {
    const response = await marzpayClient.get('/send-money/services');

    if (response.data.status === 'success') {
      return {
        success: true,
        countries: response.data.data.countries,
        summary: response.data.data.summary,
      };
    }

    return {
      success: false,
      countries: {},
    };
  } catch (error) {
    logger.error('MarzPay send money services error:', error.response?.data || error.message);
    throw new ApiError(
      error.response?.status || 500,
      error.response?.data?.message || 'Failed to fetch send money services'
    );
  }
};

/**
 * Format phone number to international format (+256...)
 */
const formatPhoneNumber = (phone) => {
  if (!phone) return null;

  // Remove spaces, dashes, parentheses
  let cleaned = phone.replace(/[\s\-()]/g, '');

  // If starts with 0, replace with +256
  if (cleaned.startsWith('0')) {
    cleaned = '+256' + cleaned.substring(1);
  }

  // If starts with 256, add +
  if (cleaned.startsWith('256') && !cleaned.startsWith('+')) {
    cleaned = '+' + cleaned;
  }

  // Validate format
  if (!cleaned.startsWith('+256') || cleaned.length !== 13) {
    return null;
  }

  return cleaned;
};

/**
 * Determine mobile money provider from phone number
 */
const getProvider = (phone) => {
  const formatted = formatPhoneNumber(phone);
  if (!formatted) return null;

  const digits = formatted.substring(4, 6); // Get first 2 digits after +256

  // MTN Uganda: 77, 78, 76
  if (['77', '78', '76'].includes(digits)) {
    return 'MTN';
  }

  // Airtel Uganda: 70, 75, 74
  if (['70', '75', '74'].includes(digits)) {
    return 'AIRTEL';
  }

  return 'UNKNOWN';
};

/**
 * Validate mobile number for MarzPay usage.
 * Performs local validation so payment flows do not fail when explicit
 * network validation is unavailable.
 * @param {string} phone - Phone number in any supported local format
 */
const validateMobileNumber = async (phone) => {
  const formattedPhone = formatPhoneNumber(phone);

  if (!formattedPhone) {
    return {
      valid: false,
      provider: null,
      message: 'Invalid phone number format. Use +256... or 0...',
    };
  }

  const provider = getProvider(formattedPhone);
  if (provider === 'UNKNOWN' || !provider) {
    return {
      valid: false,
      provider,
      message: 'Unsupported network. Use MTN (77/78/76) or Airtel (70/75/74).',
    };
  }

  return {
    valid: true,
    provider,
    customerName: null,
    message: 'Phone number is valid for mobile money payments',
  };
};

module.exports = {
  collectMoney,
  sendMoney,
  getCollectionDetails,
  getSendMoneyDetails,
  checkTransactionStatus,
  getWalletBalance,
  getTransactionHistory,
  getCollectionServices,
  getSendMoneyServices,
  validateMobileNumber,
  formatPhoneNumber,
  getProvider,
};
