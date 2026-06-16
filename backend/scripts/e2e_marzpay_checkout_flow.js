#!/usr/bin/env node

/**
 * E2E flow script:
 * 1) Farmer login/register
 * 2) Farmer adds product
 * 3) Buyer login/register (using provided phone)
 * 4) Buyer fetches products (simulates browsing)
 * 5) Buyer adds product to local cart (simulated)
 * 6) Buyer creates order (checkout)
 * 7) Buyer initiates MarzPay payment
 *
 * Usage:
 *   node scripts/e2e_marzpay_checkout_flow.js
 *
 * Optional env vars:
 *   API_BASE_URL=https://agrisupply-farm-connect-system.onrender.com/api/v1
 *   BUYER_PHONE=0783858472
 *   BUYER_EMAIL=you@example.com
 *   BUYER_PASSWORD=yourpassword
 *   FARMER_EMAIL=farmer@example.com
 *   FARMER_PASSWORD=yourpassword
 */

const axios = require('axios');

const API_BASE_URL = process.env.API_BASE_URL || 'https://agrisupply-farm-connect-system.onrender.com/api/v1';
const BUYER_PAYMENT_PHONE = process.env.BUYER_PHONE || '0783858472';
const BUYER_ACCOUNT_PHONE = process.env.BUYER_ACCOUNT_PHONE || `0776${String(Date.now()).slice(-6)}`;
const VERIFY_ATTEMPTS = Number(process.env.VERIFY_ATTEMPTS || 4);
const VERIFY_INTERVAL_MS = Number(process.env.VERIFY_INTERVAL_MS || 5000);

const BUYER_EMAIL = process.env.BUYER_EMAIL || `buyer.${Date.now()}@agrisupply.test`;
const BUYER_PASSWORD = process.env.BUYER_PASSWORD || 'Buyer1234';

const FARMER_EMAIL = process.env.FARMER_EMAIL || `farmer.${Date.now()}@agrisupply.test`;
const FARMER_PASSWORD = process.env.FARMER_PASSWORD || 'Farmer1234';
const FARMER_PHONE = process.env.FARMER_PHONE || `0777${String(Date.now()).slice(-6)}`;

const client = axios.create({
  baseURL: API_BASE_URL,
  timeout: 60000,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
});

function logStep(title, data) {
  console.log(`\n=== ${title} ===`);
  if (data !== undefined) {
    if (typeof data === 'string') {
      console.log(data);
    } else {
      console.log(JSON.stringify(data, null, 2));
    }
  }
}

function extractToken(payload) {
  return (
    payload?.data?.token
    || payload?.token
    || payload?.data?.accessToken
    || payload?.accessToken
    || null
  );
}

async function registerAccount({ email, password, fullName, phone, role }) {
  const payload = { email, password, fullName, phone, role };
  return client.post('/auth/register', payload);
}

async function loginAccount({ email, password }) {
  return client.post('/auth/login', { email, password });
}

async function ensureLogin({ email, password, fullName, phone, role }) {
  try {
    const loginRes = await loginAccount({ email, password });
    const token = extractToken(loginRes.data);
    if (!token) {
      throw new Error('Login succeeded but token missing');
    }
    return { token, user: loginRes.data?.data?.user || null, mode: 'login' };
  } catch (loginError) {
    try {
      await registerAccount({ email, password, fullName, phone, role });
      const loginRes = await loginAccount({ email, password });
      const token = extractToken(loginRes.data);
      if (!token) {
        throw new Error('Post-register login succeeded but token missing');
      }
      return { token, user: loginRes.data?.data?.user || null, mode: 'register+login' };
    } catch (registerError) {
      throw new Error(
        `Failed to ensure ${role} account. Login error: ${loginError.response?.data?.message || loginError.message}. `
        + `Register error: ${registerError.response?.data?.message || registerError.message}`
      );
    }
  }
}

function withAuth(token) {
  return {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  };
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function verifyPaymentWithRetries({ token, transactionRef }) {
  let lastResponse = null;

  for (let attempt = 1; attempt <= VERIFY_ATTEMPTS; attempt += 1) {
    const verifyRes = await client.get(`/payments/verify/${transactionRef}`, withAuth(token));
    const paymentData = verifyRes.data?.data;
    const paymentStatus = paymentData?.status || 'unknown';

    lastResponse = {
      attempt,
      status: paymentStatus,
      providerReference: paymentData?.provider_reference,
      method: paymentData?.method,
      amount: paymentData?.amount,
      raw: paymentData,
    };

    logStep(`Payment verify attempt ${attempt}/${VERIFY_ATTEMPTS}`, {
      status: paymentStatus,
      providerReference: paymentData?.provider_reference || null,
      transactionRef,
    });

    if (['completed', 'failed', 'cancelled', 'refunded'].includes(paymentStatus)) {
      return lastResponse;
    }

    if (attempt < VERIFY_ATTEMPTS) {
      await sleep(VERIFY_INTERVAL_MS);
    }
  }

  return lastResponse;
}

async function run() {
  logStep('Config', {
    apiBaseUrl: API_BASE_URL,
    buyerPaymentPhone: BUYER_PAYMENT_PHONE,
    buyerAccountPhone: BUYER_ACCOUNT_PHONE,
    buyerEmail: BUYER_EMAIL,
    farmerEmail: FARMER_EMAIL,
    farmerPhone: FARMER_PHONE,
  });

  // 1) Farmer auth
  const farmerAuth = await ensureLogin({
    email: FARMER_EMAIL,
    password: FARMER_PASSWORD,
    fullName: 'E2E Farmer',
    phone: FARMER_PHONE,
    role: 'farmer',
  });
  logStep('Farmer auth', { mode: farmerAuth.mode, farmerId: farmerAuth.user?.id || 'unknown' });

  // 2) Farmer adds product
  const productPayload = {
    name: `E2E Matooke ${Date.now()}`,
    description: 'E2E test product for checkout + payment flow',
    category: 'vegetables',
    price: 15000,
    unit: 'kg',
    quantity: 20,
    isOrganic: 'false',
  };

  const productRes = await client.post('/products', productPayload, withAuth(farmerAuth.token));
  const product = productRes.data?.data;
  if (!product?.id) {
    throw new Error(`Product creation failed: ${JSON.stringify(productRes.data)}`);
  }
  logStep('Product created by farmer', {
    productId: product.id,
    name: product.name,
    status: product.status,
    price: product.price,
  });

  // 3) Buyer auth
  const buyerAuth = await ensureLogin({
    email: BUYER_EMAIL,
    password: BUYER_PASSWORD,
    fullName: 'E2E Buyer',
    phone: BUYER_ACCOUNT_PHONE,
    role: 'buyer',
  });
  logStep('Buyer auth', { mode: buyerAuth.mode, buyerId: buyerAuth.user?.id || 'unknown' });

  // 4) Buyer browses products (global)
  const productsRes = await client.get('/products?page=1&limit=20', withAuth(buyerAuth.token));
  const products = productsRes.data?.data || [];
  const found = products.find((p) => p.id === product.id);
  logStep('Buyer product browse', {
    listedCount: products.length,
    createdProductVisible: Boolean(found),
  });

  if (!found) {
    throw new Error('Created farmer product not visible to buyer in global listing');
  }

  // 5) Buyer add-to-cart (simulated in script)
  const cartItems = [
    {
      productId: product.id,
      quantity: 1,
      price: Number(product.price || 0),
      name: product.name,
    },
  ];
  logStep('Cart (simulated)', cartItems);

  // 6) Checkout -> create order
  const orderPayload = {
    items: cartItems.map((i) => ({ productId: i.productId, quantity: i.quantity })),
    deliveryAddress: 'Kampala Road, Kampala',
    paymentMethod: 'marzpay',
    notes: 'E2E checkout flow test',
  };

  const orderRes = await client.post('/orders', orderPayload, withAuth(buyerAuth.token));
  const order = orderRes.data?.data;
  if (!order?.id) {
    throw new Error(`Order creation failed: ${JSON.stringify(orderRes.data)}`);
  }
  logStep('Order created (checkout)', {
    orderId: order.id,
    orderNumber: order.order_number,
    total: order.total,
    paymentMethod: order.payment_method,
  });

  // 7) Pay -> MarzPay initiation
  const payPayload = {
    orderId: order.id,
    method: 'marzpay',
    phone: BUYER_PAYMENT_PHONE,
  };

  const payRes = await client.post('/payments/initiate', payPayload, withAuth(buyerAuth.token));
  logStep('MarzPay initiation response', payRes.data);

  const ok = payRes.data?.success === true;
  if (!ok) {
    throw new Error('Payment initiation did not return success=true');
  }

  const transactionRef = payRes.data?.data?.transactionRef;
  if (!transactionRef) {
    throw new Error('Payment initiation succeeded but transactionRef missing in response');
  }

  const verification = await verifyPaymentWithRetries({
    token: buyerAuth.token,
    transactionRef,
  });

  logStep('Final payment verification summary', {
    attempts: VERIFY_ATTEMPTS,
    intervalMs: VERIFY_INTERVAL_MS,
    status: verification?.status || 'unknown',
    transactionRef,
    providerReference: verification?.providerReference || null,
  });

  console.log('\nSUCCESS: Flow completed. If MarzPay is configured correctly, approve prompt should appear on phone:', BUYER_PAYMENT_PHONE);
}

run().catch((error) => {
  console.error('\nE2E FLOW FAILED');
  if (error.response?.data) {
    console.error('HTTP:', error.response.status, JSON.stringify(error.response.data, null, 2));
  } else {
    console.error(error.message || error);
  }
  process.exit(1);
});
