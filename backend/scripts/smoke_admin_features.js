#!/usr/bin/env node

const axios = require('axios');

const API_BASE_URL = process.env.API_BASE_URL || 'https://agrisupply-farm-connect-system.onrender.com/api/v1';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@agrisupply.ug';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'wap7trick';

const client = axios.create({
  baseURL: API_BASE_URL,
  timeout: 60000,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
});

function extractToken(payload) {
  return payload?.data?.token || payload?.token || payload?.data?.accessToken || payload?.accessToken || null;
}

function ok(name, details) {
  console.log(`PASS | ${name} | ${details}`);
}

function fail(name, details) {
  console.log(`FAIL | ${name} | ${details}`);
}

async function test() {
  console.log(`Testing API: ${API_BASE_URL}`);
  console.log(`Admin: ${ADMIN_EMAIL}`);

  let token;
  let authHeaders;

  try {
    const loginRes = await client.post('/auth/login', {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
    });

    token = extractToken(loginRes.data);
    const user = loginRes.data?.data?.user || {};
    const role = user.role || user.user_type || 'unknown';

    if (!token) {
      fail('Login', 'No token returned');
      process.exit(1);
    }

    ok('Login', `role=${role}, userId=${user.id || 'n/a'}`);
    authHeaders = { headers: { Authorization: `Bearer ${token}` } };
  } catch (e) {
    fail('Login', `status=${e.response?.status || 'n/a'} message=${e.response?.data?.error?.message || e.response?.data?.message || e.message}`);
    process.exit(1);
  }

  // Dashboard cards source
  try {
    const res = await client.get('/admin/dashboard', authHeaders);
    const data = res.data?.data || {};
    const usersTotal = data?.users?.total;
    const productsTotal = data?.products?.total;
    const ordersTotal = data?.orders?.total;
    const revenue = data?.orders?.revenue;
    ok('Dashboard', `users.total=${usersTotal}, products.total=${productsTotal}, orders.total=${ordersTotal}, orders.revenue=${revenue}`);
  } catch (e) {
    fail('Dashboard', `status=${e.response?.status || 'n/a'} message=${e.response?.data?.error?.message || e.response?.data?.message || e.message}`);
  }

  let users = [];
  try {
    const res = await client.get('/admin/users?limit=10', authHeaders);
    users = Array.isArray(res.data?.data) ? res.data.data : [];
    ok('User Management List', `count=${users.length}`);
  } catch (e) {
    fail('User Management List', `status=${e.response?.status || 'n/a'} message=${e.response?.data?.error?.message || e.response?.data?.message || e.message}`);
  }

  // Test update user with no-op payload
  try {
    const targetUser = users.find((u) => u && u.id && u.role !== 'admin') || users.find((u) => u && u.id);
    if (!targetUser) {
      fail('User Update', 'No user found to test');
    } else {
      const payload = {
        role: targetUser.role,
        is_verified: Boolean(targetUser.is_verified),
        is_premium: Boolean(targetUser.is_premium),
        is_suspended: Boolean(targetUser.is_suspended),
      };
      const res = await client.put(`/admin/users/${targetUser.id}`, payload, authHeaders);
      const updated = res.data?.data || {};
      ok('User Update', `id=${updated.id || targetUser.id}, role=${updated.role || targetUser.role}`);
    }
  } catch (e) {
    fail('User Update', `status=${e.response?.status || 'n/a'} message=${e.response?.data?.error?.message || e.response?.data?.message || e.message}`);
  }

  let products = [];
  try {
    const res = await client.get('/admin/products?limit=10', authHeaders);
    products = Array.isArray(res.data?.data) ? res.data.data : [];
    ok('Product Management List', `count=${products.length}`);
  } catch (e) {
    fail('Product Management List', `status=${e.response?.status || 'n/a'} message=${e.response?.data?.error?.message || e.response?.data?.message || e.message}`);
  }

  // Test product update with no-op status
  try {
    const targetProduct = products.find((p) => p && p.id && p.status) || products.find((p) => p && p.id);
    if (!targetProduct) {
      fail('Product Update', 'No product found to test');
    } else {
      const status = targetProduct.status || 'active';
      await client.put(`/admin/products/${targetProduct.id}`, { status }, authHeaders);
      ok('Product Update', `id=${targetProduct.id}, status=${status}`);
    }
  } catch (e) {
    fail('Product Update', `status=${e.response?.status || 'n/a'} message=${e.response?.data?.error?.message || e.response?.data?.message || e.message}`);
  }

  let orders = [];
  try {
    const res = await client.get('/admin/orders?limit=10', authHeaders);
    orders = Array.isArray(res.data?.data) ? res.data.data : [];
    ok('Order Management List', `count=${orders.length}`);
  } catch (e) {
    fail('Order Management List', `status=${e.response?.status || 'n/a'} message=${e.response?.data?.error?.message || e.response?.data?.message || e.message}`);
  }

  // Test order update with same status (functional route check)
  try {
    const targetOrder = orders.find((o) => o && o.id && o.status) || orders.find((o) => o && o.id);
    if (!targetOrder) {
      fail('Order Update', 'No order found to test');
    } else {
      const status = targetOrder.status || 'pending';
      await client.put(`/admin/orders/${targetOrder.id}`, { status, notes: 'Automated admin smoke check' }, authHeaders);
      ok('Order Update', `id=${targetOrder.id}, status=${status}`);
    }
  } catch (e) {
    fail('Order Update', `status=${e.response?.status || 'n/a'} message=${e.response?.data?.error?.message || e.response?.data?.message || e.message}`);
  }

  // Analytics endpoints
  const analyticsRoutes = [
    '/admin/analytics/sales?period=30d',
    '/admin/analytics/users?period=30d',
    '/admin/analytics/products',
    '/admin/analytics/regions',
  ];

  for (const route of analyticsRoutes) {
    try {
      const res = await client.get(route, authHeaders);
      const data = res.data?.data;
      const summary = data && typeof data === 'object' ? Object.keys(data).slice(0, 8).join(',') : typeof data;
      ok(`Analytics ${route}`, `keys=${summary}`);
    } catch (e) {
      fail(`Analytics ${route}`, `status=${e.response?.status || 'n/a'} message=${e.response?.data?.error?.message || e.response?.data?.message || e.message}`);
    }
  }

  // Settings management
  try {
    const getRes = await client.get('/admin/settings', authHeaders);
    const settings = getRes.data?.data || {};
    const maintenanceMode = Boolean(settings.maintenance_mode);
    ok('Settings Get', `maintenance_mode=${maintenanceMode}`);

    await client.put('/admin/settings', { maintenance_mode: maintenanceMode }, authHeaders);
    ok('Settings Update (no-op)', `maintenance_mode=${maintenanceMode}`);
  } catch (e) {
    fail('Settings', `status=${e.response?.status || 'n/a'} message=${e.response?.data?.error?.message || e.response?.data?.message || e.message}`);
  }

  // Broadcast notifications
  try {
    await client.post(
      '/admin/notifications/broadcast',
      {
        title: 'Admin Smoke Test',
        message: 'Automated admin broadcast functionality check.',
        targetRole: 'admin',
      },
      authHeaders
    );
    ok('Broadcast Notification', 'sent to role=admin');
  } catch (e) {
    fail('Broadcast Notification', `status=${e.response?.status || 'n/a'} message=${e.response?.data?.error?.message || e.response?.data?.message || e.message}`);
  }

  console.log('DONE');
}

test().catch((e) => {
  console.error('Unexpected failure:', e.message);
  process.exit(1);
});
