# MarzPay Payment Gateway - Complete Implementation Guide

## Overview

MarzPay is a unified mobile money payment gateway for MTN and Airtel Uganda. This guide provides everything needed to implement MarzPay payment integration in any Node.js/Express backend project.

---

## Features

- ✅ Unified API for MTN & Airtel Uganda mobile money
- ✅ Payment collection (request payment from customers)
- ✅ Payment disbursement (send money to users)
- ✅ Real-time transaction status checking
- ✅ Wallet balance monitoring
- ✅ Transaction history with advanced filtering
- ✅ Multi-currency support (UGX, KES, TZS)
- ✅ Webhook callback support
- ✅ Automatic provider detection from phone numbers
- ✅ Sandbox mode for testing
- ✅ UUID-based reference system

---

## Prerequisites

### 1. NPM Dependencies
```json
{
  "axios": "^1.6.2",
  "express": "^4.18.2",
  "express-validator": "^7.0.1",
  "winston": "^3.11.0",
  "uuid": "^9.0.1"
}
```

### 2. MarzPay Account
- API Key: Get from MarzPay dashboard
- API Secret: Provided during registration
- API URL: `https://wallet.wearemarz.com/api/v1`

---

## API Overview

### Base URL
```
https://wallet.wearemarz.com/api/v1
```

### Authentication
All API requests require Basic Authentication:
```javascript
Authorization: Basic base64_encode("your_api_key:your_api_secret")
```

### Content Type
```
Content-Type: application/json
```

---

## Step 1: Service Layer Implementation

Create `backend/src/services/marzpayService.js`:

```javascript
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
  formatPhoneNumber,
  getProvider,
};
```

---

## Step 2: Controller Implementation

Create payment controller functions (add to your `paymentController.js`):

```javascript
const marzpayService = require('../services/marzpayService');
const { v4: uuidv4 } = require('uuid');

/**
 * Initiate MarzPay mobile money payment
 */
const initiatePayment = async (req, res, next) => {
  try {
    const { orderId, phone } = req.body;
    const userId = req.user.id;

    // Format and validate phone number
    const formattedPhone = marzpayService.formatPhoneNumber(phone);
    if (!formattedPhone) {
      return res.status(400).json({
        success: false,
        message: 'Invalid phone number format. Use format: +256771234567 or 0771234567',
      });
    }

    // Detect provider
    const provider = marzpayService.getProvider(phone);
    if (provider === 'UNKNOWN') {
      return res.status(400).json({
        success: false,
        message: 'Unsupported mobile money provider. Use MTN or Airtel Uganda numbers.',
      });
    }

    // Get order details from database
    const order = await getOrderById(orderId); // Implement this based on your DB
    if (!order || order.user_id !== userId) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    // Generate unique UUID reference
    const transactionRef = uuidv4();

    // Request payment from customer
    const result = await marzpayService.collectMoney({
      reference: transactionRef,
      phoneNumber: formattedPhone,
      country: 'UG',
      amount: order.total_amount,
      description: `Payment for Order ${orderId.substring(0, 8)}`,
      callbackUrl: `${process.env.APP_URL}/api/v1/payments/marzpay/callback`,
    });

    // Save payment record to database
    const payment = await createPayment({
      orderId: orderId,
      userId: userId,
      amount: order.total_amount,
      currency: 'UGX',
      method: 'marzpay_mobile',
      status: 'pending',
      transactionRef: transactionRef,
      transactionUuid: result.uuid,
      providerRef: result.providerReference,
      phoneNumber: formattedPhone,
      provider: provider,
    });

    return res.status(200).json({
      success: true,
      message: 'Payment request sent. Please approve on your phone.',
      data: {
        transactionRef: transactionRef,
        transactionUuid: result.uuid,
        status: 'pending',
        providerRef: result.providerReference,
        provider: result.provider,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Verify payment status
 */
const verifyPayment = async (req, res, next) => {
  try {
    const { transactionId } = req.params;

    // Get payment from database
    const payment = await getPaymentByTransactionRef(transactionId);
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found',
      });
    }

    // Check status with MarzPay
    const statusData = await marzpayService.checkTransactionStatus(
      payment.transaction_uuid || transactionId
    );

    // Update payment status in database
    if (statusData.status === 'successful' || statusData.status === 'completed') {
      await updatePaymentStatus(payment.id, 'completed', {
        providerTransactionId: statusData.providerReference,
        completedAt: statusData.updatedAt,
      });
    } else if (statusData.status === 'failed' || statusData.status === 'cancelled') {
      await updatePaymentStatus(payment.id, 'failed');
    }

    return res.status(200).json({
      success: true,
      data: {
        status: statusData.status,
        amount: statusData.amount,
        currency: statusData.currency,
        provider: statusData.provider,
        provider_transaction_id: statusData.providerReference,
        updated_at: statusData.updatedAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Check wallet balance (Admin only)
 */
const checkWalletBalance = async (req, res, next) => {
  try {
    const balance = await marzpayService.getWalletBalance();

    return res.status(200).json({
      success: true,
      data: balance,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get transaction history (Admin only)
 */
const getMarzPayTransactions = async (req, res, next) => {
  try {
    const { page, per_page, type, status, provider, start_date, end_date } = req.query;

    const params = {};
    if (page) params.page = parseInt(page);
    if (per_page) params.per_page = parseInt(per_page);
    if (type) params.type = type;
    if (status) params.status = status;
    if (provider) params.provider = provider;
    if (start_date) params.start_date = start_date;
    if (end_date) params.end_date = end_date;

    const history = await marzpayService.getTransactionHistory(params);

    return res.status(200).json({
      success: true,
      data: history.transactions || [],
      pagination: history.pagination,
      filters: history.filters,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * MarzPay webhook callback
 */
const marzpayCallback = async (req, res, next) => {
  try {
    const { event_type, transaction, collection, disbursement } = req.body;

    logger.info('MarzPay webhook received:', req.body);

    // Find payment by reference or UUID
    const payment = await getPaymentByTransactionRef(transaction.reference) ||
                     await getPaymentByUuid(transaction.uuid);

    if (payment) {
      // Update payment status based on event
      if (event_type === 'collection.completed' && transaction.status === 'completed') {
        await updatePaymentStatus(payment.id, 'completed', {
          providerTransactionId: collection.provider_transaction_id,
          completedAt: transaction.updated_at,
        });
      } else if (transaction.status === 'failed') {
        await updatePaymentStatus(payment.id, 'failed');
      }
    }

    return res.status(200).json({ success: true });
  } catch (error) {
    logger.error('MarzPay callback error:', error);
    return res.status(200).json({ success: true }); // Always return 200 to MarzPay
  }
};

module.exports = {
  initiatePayment,
  verifyPayment,
  checkWalletBalance,
  getMarzPayTransactions,
  marzpayCallback,
};
```

---

## Step 3: Routes Configuration

Create/update `paymentRoutes.js`:

```javascript
const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticate, isAdmin } = require('../middleware/authMiddleware');

// Initiate payment
router.post('/initiate', authenticate, paymentController.initiatePayment);

// Verify payment status
router.get('/verify/:transactionId', authenticate, paymentController.verifyPayment);

// MarzPay webhook callback
router.post('/marzpay/callback', paymentController.marzpayCallback);

// Admin: Check wallet balance
router.get('/wallet-balance', authenticate, isAdmin, paymentController.checkWalletBalance);

// Admin: Get transaction history
router.get('/marzpay-transactions', authenticate, isAdmin, paymentController.getMarzPayTransactions);

module.exports = router;
```

Register routes in your main app file:
```javascript
const paymentRoutes = require('./routes/paymentRoutes');
app.use('/api/v1/payments', paymentRoutes);
```

---

## Step 4: Database Schema

Create payments table:

```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  order_id UUID REFERENCES orders(id),
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'UGX',
  method VARCHAR(50) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  transaction_ref VARCHAR(255) UNIQUE NOT NULL,
  transaction_uuid VARCHAR(255),
  provider_reference VARCHAR(255),
  provider_transaction_id VARCHAR(255),
  phone_number VARCHAR(20),
  provider VARCHAR(50),
  metadata JSONB,
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_transaction_ref ON payments(transaction_ref);
CREATE INDEX idx_payments_transaction_uuid ON payments(transaction_uuid);
CREATE INDEX idx_payments_status ON payments(status);
```

---

## Step 5: Environment Variables

Add to `.env`:

```env
# MarzPay Payment Gateway
MARZPAY_API_KEY=your-api-key-here
MARZPAY_API_SECRET=your-api-secret-here
MARZPAY_API_URL=https://wallet.wearemarz.com/api/v1
MARZPAY_CALLBACK_URL=https://yourdomain.com/api/v1/payments/marzpay/callback
APP_URL=https://yourdomain.com
```

---

## API Usage Examples

### 1. Initiate Payment

```bash
POST /api/v1/payments/initiate
Authorization: Bearer <user-token>
Content-Type: application/json

{
  "orderId": "uuid-here",
  "phone": "+256771234567"
}
```

### 2. Verify Payment

```bash
GET /api/v1/payments/verify/TXN-UUID-HERE
Authorization: Bearer <user-token>
```

### 3. Check Wallet Balance (Admin)

```bash
GET /api/v1/payments/wallet-balance
Authorization: Bearer <admin-token>
```

### 4. Get Transaction History (Admin)

```bash
GET /api/v1/payments/marzpay-transactions?per_page=10&type=collection&status=successful
Authorization: Bearer <admin-token>
```

---

## Testing

### Test Phone Numbers

**MTN Uganda:**
- +256771234567 (Format: +25677...)
- +256781234567 (Format: +25678...)
- +256761234567 (Format: +25676...)

**Airtel Uganda:**
- +256701234567 (Format: +25670...)
- +256751234567 (Format: +25675...)
- +256741234567 (Format: +25674...)

### Payment Flow

1. Customer initiates payment
2. System sends payment request to MarzPay
3. Customer receives prompt on phone
4. Customer approves payment
5. MarzPay processes transaction
6. System receives webhook notification
7. System updates payment status

### Status Values

- `pending` - Payment initiated, waiting for approval
- `processing` - Customer approved, processing
- `successful`/`completed` - Payment successful
- `failed` - Payment failed
- `cancelled` - Payment cancelled

---

## Error Handling

### Common Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 400 | Bad request | Check phone format, amount, reference |
| 401 | Unauthorized | Verify API credentials |
| 404 | Not found | Check transaction reference |
| 422 | Validation error | Check input validation |
| 500 | Server error | Check logs, retry |

---

## Production Checklist

- [ ] Update `MARZPAY_CALLBACK_URL` to production domain
- [ ] Set up webhook endpoint (accessible publicly)
- [ ] Configure SSL/TLS for webhook security
- [ ] Set up proper logging and monitoring
- [ ] Test with real phone numbers
- [ ] Implement payment retry logic
- [ ] Set up payment reconciliation process
- [ ] Monitor wallet balance regularly
- [ ] Set up alerts for failed payments
- [ ] Document payment flow for team

---

## Security Best Practices

1. **Never expose API keys** in client-side code
2. **Validate all inputs** before sending to MarzPay
3. **Use HTTPS** for all API calls
4. **Verify webhook authenticity** (implement signature verification if available)
5. **Store sensitive data encrypted** in database
6. **Implement rate limiting** on your endpoints
7. **Log all transactions** for audit trail

---

## Support & Documentation

- **MarzPay API Docs:** https://marzpay.wearemarz.com/api-docs
- **Support Email:** support@wearemarz.com
- **Support Phone:** (+256) 759983853 / (+256) 781230949
- **Supported Countries:** Uganda (MTN, Airtel)
- **Supported Currencies:** UGX, KES, TZS
- **Transaction Limits:** 500 - 10,000,000 UGX

---

## Webhook Events

MarzPay sends webhook notifications for the following events:

### Collection Events
- `collection.initiated` - Collection request created
- `collection.processing` - Customer approved, processing
- `collection.completed` - Collection successful
- `collection.failed` - Collection failed

### Disbursement Events
- `disbursement.initiated` - Send money request created
- `disbursement.processing` - Processing payout
- `disbursement.completed` - Payout successful
- `disbursement.failed` - Payout failed

### Webhook Payload Example

```json
{
  "event_type": "collection.completed",
  "transaction": {
    "uuid": "5cbe2960-971e-46b0-ac32-2c32ad0c496f",
    "reference": "COL001",
    "status": "completed",
    "amount": {
      "formatted": "1,000.00",
      "raw": 1000,
      "currency": "UGX"
    },
    "provider": "mtn",
    "phone_number": "+256781230949",
    "description": "Payment received from customer",
    "created_at": "2024-01-20T14:30:00.000000Z",
    "updated_at": "2024-01-20T14:35:00.000000Z"
  },
  "collection": {
    "provider": "mtn",
    "phone_number": "+256781230949",
    "amount": {
      "formatted": "1,000.00",
      "raw": 1000,
      "currency": "UGX"
    },
    "mode": "mtnuganda",
    "provider_transaction_id": "MTN_20240120_001"
  }
}
```

---

## Complete Implementation Checklist

- [ ] Install required NPM packages
- [ ] Create `marzpayService.js` service file
- [ ] Implement controller functions
- [ ] Set up routes
- [ ] Create database schema
- [ ] Configure environment variables
- [ ] Set up logger and error handling
- [ ] Implement database helper functions
- [ ] Test with sandbox credentials
- [ ] Configure webhook endpoint
- [ ] Test complete payment flow
- [ ] Implement error handling
- [ ] Add payment retry logic
- [ ] Set up monitoring and alerts
- [ ] Deploy to production
- [ ] Update callback URL for production

---

This guide provides everything needed to implement MarzPay payment integration. Follow the steps sequentially for a complete, production-ready implementation.
