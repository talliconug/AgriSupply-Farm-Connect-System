#!/usr/bin/env node

/**
 * Minimal API smoke test for payment initiation (no farmer/e2e setup).
 * 1) Login buyer
 * 2) Pick active product
 * 3) Create order
 * 4) Initiate MarzPay payment
 */

const axios = require('axios');

const API_BASE_URL = process.env.API_BASE_URL || 'https://agrisupply-farm-connect-system.onrender.com/api/v1';
const BUYER_EMAIL = process.env.BUYER_EMAIL || 'buteramarcel@gmail.com';
const BUYER_PASSWORD = process.env.BUYER_PASSWORD || 'wap7trick';
const BUYER_PHONE = process.env.BUYER_PHONE || '0783858472';

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
    console.log(JSON.stringify(data, null, 2));
  }
}

function extractToken(payload) {
  return payload?.data?.token || payload?.token || payload?.data?.accessToken || payload?.accessToken || null;
}

async function run() {
  logStep('Config', {
    apiBaseUrl: API_BASE_URL,
    buyerEmail: BUYER_EMAIL,
    buyerPhone: BUYER_PHONE,
  });

  const loginRes = await client.post('/auth/login', {
    email: BUYER_EMAIL,
    password: BUYER_PASSWORD,
  });

  const token = extractToken(loginRes.data);
  if (!token) {
    throw new Error('Login succeeded but token is missing');
  }

  logStep('Buyer login', {
    success: true,
    buyerId: loginRes.data?.data?.user?.id || null,
  });

  const authHeaders = { headers: { Authorization: `Bearer ${token}` } };

  const productsRes = await client.get('/products?page=1&limit=20', authHeaders);
  const products = productsRes.data?.data || [];
  const active = products.find((p) => p.status === 'active' && Number(p.price) > 0);

  if (!active) {
    throw new Error('No active product found for smoke test');
  }

  logStep('Selected product', {
    productId: active.id,
    name: active.name,
    price: active.price,
  });

  const orderRes = await client.post(
    '/orders',
    {
      items: [{ productId: active.id, quantity: 1 }],
      deliveryAddress: 'Kampala Road, Kampala',
      paymentMethod: 'marzpay',
      notes: 'API smoke payment-initiation test',
    },
    authHeaders
  );

  const order = orderRes.data?.data;
  if (!order?.id) {
    throw new Error(`Order creation failed: ${JSON.stringify(orderRes.data)}`);
  }

  logStep('Order created', {
    orderId: order.id,
    orderNumber: order.order_number,
    paymentStatus: order.payment_status,
    total: order.total || order.total_amount,
  });

  try {
    const payRes = await client.post(
      '/payments/initiate',
      {
        orderId: order.id,
        method: 'marzpay',
        phone: BUYER_PHONE,
      },
      authHeaders
    );

    logStep('Payment initiate response', payRes.data);
  } catch (error) {
    logStep('Payment initiate error', {
      status: error.response?.status || null,
      data: error.response?.data || error.message,
    });
    process.exit(1);
  }
}

run().catch((error) => {
  logStep('Smoke test failed', {
    message: error.message,
    data: error.response?.data || null,
  });
  process.exit(1);
});
