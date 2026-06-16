const { supabase } = require('../config/supabase');
const { ApiError, asyncHandler } = require('../middleware/errorMiddleware');
const { paginate, paginationResponse } = require('../utils/helpers');
const constants = require('../config/constants');
const logger = require('../utils/logger');
const { createInAppNotification } = require('../utils/notificationHelper');

const FARMER_MIN_RATING = parseFloat(process.env.FARMER_VERIFICATION_MIN_RATING || '4.0');
const FARMER_MIN_ORDERS = parseInt(process.env.FARMER_VERIFICATION_MIN_ORDERS || '10', 10);

const evaluateFarmerVerificationCriteria = (user) => {
  const kycComplete = Boolean(user.email_verified) && Boolean(user.phone_verified);
  const rating = Number(user.rating || 0);
  const completedOrders = Number(user.total_orders || 0);
  const performanceQualified = rating >= FARMER_MIN_RATING && completedOrders >= FARMER_MIN_ORDERS;

  return {
    kycComplete,
    performanceQualified,
    rating,
    completedOrders,
    requiredRating: FARMER_MIN_RATING,
    requiredOrders: FARMER_MIN_ORDERS,
    isEligible: kycComplete && performanceQualified,
  };
};

/**
 * @desc    Get admin dashboard statistics
 * @route   GET /api/v1/admin/dashboard
 */
const getDashboard = asyncHandler(async (req, res) => {
  // Get user statistics
  const { data: users } = await supabase
    .from('users')
    .select('id, role, is_verified, is_premium, created_at')
    .order('created_at', { ascending: false });

  const totalUsers = users?.length || 0;
  const farmers = users?.filter(u => u.role === 'farmer').length || 0;
  const buyers = users?.filter(u => u.role === 'buyer').length || 0;
  const verifiedUsers = users?.filter(u => u.is_verified).length || 0;
  const premiumUsers = users?.filter(u => u.is_premium).length || 0;

  // Get product statistics
  const { data: products } = await supabase
    .from('products')
    .select('id, status, category, created_at');

  const totalProducts = products?.length || 0;
  const activeProducts = products?.filter(p => p.status === 'active').length || 0;
  const pendingProducts = products?.filter(p => p.status === 'pending').length || 0;

  // Get order statistics
  const { data: orders } = await supabase
    .from('orders')
    .select('id, status, total_amount, created_at');

  const totalOrders = orders?.length || 0;
  const pendingOrders = orders?.filter(o => o.status === 'pending').length || 0;
  const completedOrders = orders?.filter(o => o.status === 'delivered').length || 0;
  const totalRevenue = orders?.reduce((sum, o) => sum + (o.total_amount || 0), 0) || 0;

  // Get payment statistics
  const { data: payments } = await supabase
    .from('payments')
    .select('id, status, amount, payment_method');

  const totalPayments = payments?.length || 0;
  const successfulPayments = payments?.filter(p => p.status === 'successful').length || 0;
  const paymentVolume = payments
    ?.filter(p => p.status === 'successful')
    .reduce((sum, p) => sum + (p.amount || 0), 0) || 0;

  // Recent activity
  const recentUsers = users?.slice(0, 5) || [];
  const recentOrders = orders?.slice(0, 5) || [];

  // Calculate growth (last 30 days vs previous 30 days)
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const sixtyDaysAgo = new Date(Date.now() - 60 * 24 * 60 * 60 * 1000);

  const newUsersLast30 = users?.filter(u => new Date(u.created_at) >= thirtyDaysAgo).length || 0;
  const newUsersPrev30 = users?.filter(u => 
    new Date(u.created_at) >= sixtyDaysAgo && new Date(u.created_at) < thirtyDaysAgo
  ).length || 0;
  const userGrowth = newUsersPrev30 > 0 
    ? Math.round(((newUsersLast30 - newUsersPrev30) / newUsersPrev30) * 100) 
    : 100;

  res.json({
    success: true,
    data: {
      users: {
        total: totalUsers,
        farmers,
        buyers,
        verified: verifiedUsers,
        premium: premiumUsers,
        growth: userGrowth,
      },
      products: {
        total: totalProducts,
        active: activeProducts,
        pending: pendingProducts,
      },
      orders: {
        total: totalOrders,
        pending: pendingOrders,
        completed: completedOrders,
        revenue: totalRevenue,
      },
      payments: {
        total: totalPayments,
        successful: successfulPayments,
        volume: paymentVolume,
      },
      recentActivity: {
        users: recentUsers,
        orders: recentOrders,
      },
    },
  });
});

/**
 * @desc    Get all users with filters
 * @route   GET /api/v1/admin/users
 */
const getUsers = asyncHandler(async (req, res) => {
  const { role, is_verified, is_premium, is_suspended, search, page = 1, limit = 20 } = req.query;

  let query = supabase
    .from('users')
    .select('*', { count: 'exact' });

  if (role) query = query.eq('role', role);
  if (is_verified !== undefined) query = query.eq('is_verified', is_verified === 'true');
  if (is_premium !== undefined) query = query.eq('is_premium', is_premium === 'true');
  if (is_suspended !== undefined) query = query.eq('is_suspended', is_suspended === 'true');
  if (search) {
    query = query.or(`full_name.ilike.%${search}%,email.ilike.%${search}%,phone.ilike.%${search}%`);
  }

  const { offset, limit: pageSize } = paginate(parseInt(page), parseInt(limit));
  query = query.range(offset, offset + pageSize - 1).order('created_at', { ascending: false });

  const { data, error, count } = await query;

  if (error) {
    logger.error('Get users error:', error);
    throw new ApiError(400, 'Failed to fetch users');
  }

  res.json({
    success: true,
    data,
    pagination: paginationResponse(data, count || 0, parseInt(page, 10) || 1, pageSize),
  });
});

/**
 * @desc    Get user by ID
 * @route   GET /api/v1/admin/users/:id
 */
const getUserById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const { data: user, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', id)
    .single();

  if (error || !user) {
    throw new ApiError(404, 'User not found');
  }

  // Get user's products if farmer
  let products = [];
  if (user.role === 'farmer') {
    const { data } = await supabase
      .from('products')
      .select('*')
      .eq('farmer_id', id)
      .limit(10);
    products = data || [];
  }

  // Get user's orders
  const { data: orders } = await supabase
    .from('orders')
    .select('*')
    .eq('buyer_id', id)
    .limit(10);

  res.json({
    success: true,
    data: {
      ...user,
      products,
      orders: orders || [],
    },
  });
});

/**
 * @desc    Update user
 * @route   PUT /api/v1/admin/users/:id
 */
const updateUser = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { role, is_verified, is_premium, is_suspended } = req.body;

  const updateData = {};
  if (role !== undefined) updateData.role = role;
  if (is_verified !== undefined) updateData.is_verified = is_verified;
  if (is_premium !== undefined) updateData.is_premium = is_premium;
  if (is_suspended !== undefined) updateData.is_suspended = is_suspended;
  updateData.updated_at = new Date().toISOString();

  const { error } = await supabase
    .from('users')
    .update(updateData)
    .eq('id', id);

  if (error) {
    logger.error('Update user error:', error);
      throw new ApiError(400, `Failed to update user: ${error.message || 'Unknown database error'}`);
  }

  const { data } = await supabase
    .from('users')
    .select('*')
    .eq('id', id)
    .maybeSingle();

  res.json({
    success: true,
    data: data || { id, ...updateData },
  });
});

/**
 * @desc    Verify user account
 * @route   POST /api/v1/admin/users/:id/verify
 */
const verifyUser = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { override = false, overrideReason } = req.body || {};

  const { data: user, error: userError } = await supabase
    .from('users')
    .select('id, role, email_verified, phone_verified, rating, total_orders')
    .eq('id', id)
    .single();

  if (userError || !user) {
    throw new ApiError(404, 'User not found');
  }

  const criteria = user.role === 'farmer'
    ? evaluateFarmerVerificationCriteria(user)
    : null;

  if (user.role === 'farmer' && !override && criteria && !criteria.isEligible) {
    throw new ApiError(400, 'Farmer does not meet verification criteria');
  }

  if (user.role === 'farmer' && override && !overrideReason) {
    throw new ApiError(400, 'Override reason is required when override is true');
  }

  const { data, error } = await supabase
    .from('users')
    .update({ 
      is_verified: true, 
      verified_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    logger.error('Verify user error:', error);
    throw new ApiError(400, 'Failed to verify user');
  }

  // Send notification to user
  await createInAppNotification({
    userId: id,
    type: 'system',
    title: 'Account Verified',
    message: 'Congratulations! Your account has been verified.',
    data: {
      role: user.role,
      overrideUsed: Boolean(override),
      overrideReason: override ? overrideReason : null,
      criteria,
    },
  });

  res.json({
    success: true,
    message: 'User verified successfully',
    data: {
      ...data,
      verification: {
        criteria,
        overrideUsed: Boolean(override),
        overrideReason: override ? overrideReason : null,
      },
    },
  });
});

/**
 * @desc    Suspend user
 * @route   POST /api/v1/admin/users/:id/suspend
 */
const suspendUser = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  const { data, error } = await supabase
    .from('users')
    .update({ 
      is_suspended: true, 
      suspension_reason: reason,
      suspended_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    logger.error('Suspend user error:', error);
    throw new ApiError(400, 'Failed to suspend user');
  }

  // Send notification
  await supabase.from('notifications').insert({
    user_id: id,
    type: 'account',
    title: 'Account Suspended',
    message: `Your account has been suspended. Reason: ${reason}`,
    is_read: false,
    created_at: new Date().toISOString(),
  });

  res.json({
    success: true,
    message: 'User suspended',
    data,
  });
});

/**
 * @desc    Unsuspend user
 * @route   POST /api/v1/admin/users/:id/unsuspend
 */
const unsuspendUser = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const { data, error } = await supabase
    .from('users')
    .update({ 
      is_suspended: false, 
      suspension_reason: null,
      suspended_at: null,
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    logger.error('Unsuspend user error:', error);
    throw new ApiError(400, 'Failed to unsuspend user');
  }

  // Send notification
  await supabase.from('notifications').insert({
    user_id: id,
    type: 'account',
    title: 'Account Reactivated',
    message: 'Your account has been reactivated. Welcome back!',
    is_read: false,
    created_at: new Date().toISOString(),
  });

  res.json({
    success: true,
    message: 'User unsuspended',
    data,
  });
});

/**
 * @desc    Delete user
 * @route   DELETE /api/v1/admin/users/:id
 */
const deleteUser = asyncHandler(async (req, res) => {
  const { id } = req.params;

  // Soft delete - mark as deleted
  const { error } = await supabase
    .from('users')
    .update({ 
      is_deleted: true,
      deleted_at: new Date().toISOString(),
    })
    .eq('id', id);

  if (error) {
    logger.error('Delete user error:', error);
    throw new ApiError(400, 'Failed to delete user');
  }

  res.json({
    success: true,
    message: 'User deleted',
  });
});

/**
 * @desc    Get all products with filters
 * @route   GET /api/v1/admin/products
 */
const getProducts = asyncHandler(async (req, res) => {
  const { status, category, farmer_id, search, page = 1, limit = 20 } = req.query;

  let query = supabase
    .from('products')
    .select('*, farmer:users!farmer_id(id, full_name, email)', { count: 'exact' });

  if (status) query = query.eq('status', status);
  if (category) query = query.eq('category', category);
  if (farmer_id) query = query.eq('farmer_id', farmer_id);
  if (search) {
    query = query.or(`name.ilike.%${search}%,description.ilike.%${search}%`);
  }

  const { offset, limit: pageSize } = paginate(parseInt(page), parseInt(limit));
  query = query.range(offset, offset + pageSize - 1).order('created_at', { ascending: false });

  const { data, error, count } = await query;

  if (error) {
    logger.error('Get products error:', error);
    throw new ApiError(400, 'Failed to fetch products');
  }

  res.json({
    success: true,
    data,
    pagination: paginationResponse(data, count || 0, parseInt(page, 10) || 1, pageSize),
  });
});

/**
 * @desc    Update product status
 * @route   PUT /api/v1/admin/products/:id
 */
const updateProduct = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status, is_featured, rejection_reason } = req.body;

  const { data: existingProduct } = await supabase
    .from('products')
    .select('id, farmer_id, name, status')
    .eq('id', id)
    .maybeSingle();

  const updateData = { updated_at: new Date().toISOString() };
  if (status !== undefined) updateData.status = status;
  if (is_featured !== undefined) updateData.is_featured = is_featured;
  if (rejection_reason) updateData.rejection_reason = rejection_reason;

  const { error } = await supabase
    .from('products')
    .update(updateData)
    .eq('id', id);

  if (error) {
    logger.error('Update product error:', error);
      throw new ApiError(400, `Failed to update product: ${error.message || 'Unknown database error'}`);
  }

  const { data } = await supabase
    .from('products')
    .select('*, farmer:users!farmer_id(id, full_name)')
    .eq('id', id)
    .maybeSingle();

  const productForNotify = data || existingProduct;

  // Notify farmer
  if (productForNotify?.farmer_id) {
    await supabase.from('notifications').insert({
      user_id: productForNotify.farmer_id,
      type: 'product',
      title: status === 'active' ? 'Product Approved' : 'Product Update',
      message: status === 'active'
        ? `Your product "${productForNotify.name || 'Product'}" has been approved and is now live.`
        : `Your product "${productForNotify.name || 'Product'}" status has been updated to ${status || productForNotify.status}.`,
      data: { product_id: id },
      is_read: false,
      created_at: new Date().toISOString(),
    });
  }

  res.json({
    success: true,
    data: data || { id, ...updateData },
  });
});

/**
 * @desc    Delete product
 * @route   DELETE /api/v1/admin/products/:id
 */
const deleteProduct = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const { data: product, error: fetchError } = await supabase
    .from('products')
    .select('farmer_id, name')
    .eq('id', id)
    .single();

  if (fetchError) {
    throw new ApiError(404, 'Product not found');
  }

  const { error } = await supabase
    .from('products')
    .delete()
    .eq('id', id);

  if (error) {
    logger.error('Delete product error:', error);
    throw new ApiError(400, 'Failed to delete product');
  }

  // Notify farmer
  await supabase.from('notifications').insert({
    user_id: product.farmer_id,
    type: 'product',
    title: 'Product Removed',
    message: `Your product "${product.name}" has been removed by admin.`,
    is_read: false,
    created_at: new Date().toISOString(),
  });

  res.json({
    success: true,
    message: 'Product deleted',
  });
});

/**
 * @desc    Get all orders with filters
 * @route   GET /api/v1/admin/orders
 */
const getOrders = asyncHandler(async (req, res) => {
  const { status, payment_status, region, date_from, date_to, page = 1, limit = 20 } = req.query;

  let query = supabase
    .from('orders')
    .select(`
      *,
      buyer:users!buyer_id(id, full_name, email, phone),
      order_items(*)
    `, { count: 'exact' });

  if (status) query = query.eq('status', status);
  if (payment_status) query = query.eq('payment_status', payment_status);
  if (region) query = query.eq('delivery_region', region);
  if (date_from) query = query.gte('created_at', date_from);
  if (date_to) query = query.lte('created_at', date_to);

  const { offset, limit: pageSize } = paginate(parseInt(page), parseInt(limit));
  query = query.range(offset, offset + pageSize - 1).order('created_at', { ascending: false });

  const { data, error, count } = await query;

  if (error) {
    logger.error('Get orders error:', error);
    throw new ApiError(400, 'Failed to fetch orders');
  }

  res.json({
    success: true,
    data,
    pagination: paginationResponse(data, count || 0, parseInt(page, 10) || 1, pageSize),
  });
});

/**
 * @desc    Update order status
 * @route   PUT /api/v1/admin/orders/:id
 */
const updateOrder = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status, notes } = req.body;

  if (!status || !constants.orderStatuses.includes(status)) {
    throw new ApiError(400, 'Invalid order status');
  }

  const { data: currentOrder, error: currentOrderError } = await supabase
    .from('orders')
    .select('status')
    .eq('id', id)
    .single();

  if (currentOrderError || !currentOrder) {
    throw new ApiError(404, 'Order not found');
  }

  const currentStatus = currentOrder.status;
  if (['delivered', 'cancelled', 'refunded'].includes(currentStatus) && currentStatus !== status) {
    throw new ApiError(400, `Cannot change order status from ${currentStatus}`);
  }

  const allowedTransitions = {
    pending: ['confirmed', 'processing', 'cancelled'],
    confirmed: ['processing', 'shipped', 'cancelled'],
    processing: ['shipped', 'out_for_delivery', 'cancelled'],
    shipped: ['out_for_delivery', 'delivered'],
    out_for_delivery: ['delivered'],
    delivered: [],
    cancelled: [],
    refunded: [],
  };

  if (currentStatus !== status) {
    const allowed = allowedTransitions[currentStatus] || [];
    if (!allowed.includes(status)) {
      throw new ApiError(400, `Invalid order transition: ${currentStatus} -> ${status}`);
    }
  }

  const { data, error } = await supabase
    .from('orders')
    .update({ 
      status, 
      admin_notes: notes,
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .select('*, buyer:users!buyer_id(id, full_name)')
    .single();

  if (error) {
    logger.error('Update order error:', error);
    throw new ApiError(400, 'Failed to update order');
  }

  // Add to order history
  await supabase.from('order_status_history').insert({
    order_id: id,
    status,
    notes: notes || `Status updated to ${status} by admin`,
    created_at: new Date().toISOString(),
  });

  // Notify buyer
  await supabase.from('notifications').insert({
    user_id: data.buyer_id,
    type: 'order',
    title: 'Order Update',
    message: `Your order #${data.order_number} status has been updated to ${status}.`,
    data: { order_id: id },
    is_read: false,
    created_at: new Date().toISOString(),
  });

  res.json({
    success: true,
    data,
  });
});

/**
 * @desc    Get all payments
 * @route   GET /api/v1/admin/payments
 */
const getPayments = asyncHandler(async (req, res) => {
  const { status, payment_method, date_from, date_to, page = 1, limit = 20 } = req.query;

  let query = supabase
    .from('payments')
    .select(`
      *,
      order:orders(id, order_number, buyer_id),
      user:users!user_id(id, full_name, email)
    `, { count: 'exact' });

  if (status) query = query.eq('status', status);
  if (payment_method) query = query.eq('payment_method', payment_method);
  if (date_from) query = query.gte('created_at', date_from);
  if (date_to) query = query.lte('created_at', date_to);

  const { offset, limit: pageSize } = paginate(parseInt(page), parseInt(limit));
  query = query.range(offset, offset + pageSize - 1).order('created_at', { ascending: false });

  const { data, error, count } = await query;

  if (error) {
    logger.error('Get payments error:', error);
    throw new ApiError(400, 'Failed to fetch payments');
  }

  res.json({
    success: true,
    data,
    pagination: paginationResponse(data, count || 0, parseInt(page, 10) || 1, pageSize),
  });
});

/**
 * @desc    Process refund
 * @route   POST /api/v1/admin/payments/:id/refund
 */
const processRefund = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { amount, reason } = req.body;

  const { data: payment, error: fetchError } = await supabase
    .from('payments')
    .select('*')
    .eq('id', id)
    .single();

  if (fetchError || !payment) {
    throw new ApiError(404, 'Payment not found');
  }

  if (payment.status !== 'successful') {
    throw new ApiError(400, 'Can only refund successful payments');
  }

  const refundAmount = amount || payment.amount;

  // Create refund record
  const { data: refund, error: refundError } = await supabase
    .from('refunds')
    .insert({
      payment_id: id,
      order_id: payment.order_id,
      user_id: payment.user_id,
      amount: refundAmount,
      reason,
      status: 'processed',
      processed_at: new Date().toISOString(),
      created_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (refundError) {
    logger.error('Create refund error:', refundError);
    throw new ApiError(400, 'Failed to process refund');
  }

  // Update payment status
  await supabase
    .from('payments')
    .update({ 
      status: 'refunded',
      updated_at: new Date().toISOString(),
    })
    .eq('id', id);

  // Notify user
  await supabase.from('notifications').insert({
    user_id: payment.user_id,
    type: 'payment',
    title: 'Refund Processed',
    message: `Your refund of UGX ${refundAmount.toLocaleString()} has been processed.`,
    data: { refund_id: refund.id },
    is_read: false,
    created_at: new Date().toISOString(),
  });

  res.json({
    success: true,
    message: 'Refund processed',
    data: refund,
  });
});

/**
 * @desc    Get sales analytics
 * @route   GET /api/v1/admin/analytics/sales
 */
const getSalesAnalytics = asyncHandler(async (req, res) => {
  const { period = '30d' } = req.query;

  let daysAgo = 30;
  if (period === '7d') daysAgo = 7;
  if (period === '90d') daysAgo = 90;
  if (period === '1y') daysAgo = 365;

  const startDate = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000).toISOString();

  const { data: orders } = await supabase
    .from('orders')
    .select('id, total_amount, status, created_at')
    .gte('created_at', startDate)
    .eq('status', 'delivered');

  // Group by date
  const salesByDate = {};
  orders?.forEach(order => {
    const date = order.created_at.split('T')[0];
    if (!salesByDate[date]) {
      salesByDate[date] = { count: 0, amount: 0 };
    }
    salesByDate[date].count++;
    salesByDate[date].amount += order.total_amount || 0;
  });

  const totalSales = orders?.reduce((sum, o) => sum + (o.total_amount || 0), 0) || 0;
  const averageOrderValue = orders?.length > 0 ? totalSales / orders.length : 0;

  res.json({
    success: true,
    data: {
      period,
      totalSales,
      totalOrders: orders?.length || 0,
      averageOrderValue,
      salesByDate,
    },
  });
});

/**
 * @desc    Get user analytics
 * @route   GET /api/v1/admin/analytics/users
 */
const getUserAnalytics = asyncHandler(async (req, res) => {
  const { period = '30d' } = req.query;

  let daysAgo = 30;
  if (period === '7d') daysAgo = 7;
  if (period === '90d') daysAgo = 90;
  if (period === '1y') daysAgo = 365;

  const startDate = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000).toISOString();

  const { data: users } = await supabase
    .from('users')
    .select('id, role, is_verified, is_premium, created_at')
    .gte('created_at', startDate);

  // Group by date
  const usersByDate = {};
  users?.forEach(user => {
    const date = user.created_at.split('T')[0];
    if (!usersByDate[date]) {
      usersByDate[date] = { farmers: 0, buyers: 0 };
    }
    if (user.role === 'farmer') usersByDate[date].farmers++;
    else usersByDate[date].buyers++;
  });

  const farmers = users?.filter(u => u.role === 'farmer').length || 0;
  const buyers = users?.filter(u => u.role === 'buyer').length || 0;

  res.json({
    success: true,
    data: {
      period,
      totalNewUsers: users?.length || 0,
      newFarmers: farmers,
      newBuyers: buyers,
      usersByDate,
    },
  });
});

/**
 * @desc    Get product analytics
 * @route   GET /api/v1/admin/analytics/products
 */
const getProductAnalytics = asyncHandler(async (req, res) => {
  const { data: products } = await supabase
    .from('products')
    .select('id, name, price, category, status, views_count, rating, thumbnail_url, images');

  // Group by category
  const byCategory = {};
  constants.productCategories.forEach(cat => {
    if (cat && cat.id) {
      byCategory[cat.id] = 0;
    }
  });
  
  products?.forEach(product => {
    if (byCategory[product.category] !== undefined) {
      byCategory[product.category]++;
    }
  });

  // Top products by views
  const topByViews = products
    ?.sort((a, b) => (b.views_count || 0) - (a.views_count || 0))
    .slice(0, 10);

  // Top products by rating
  const topByRating = products
    ?.filter(p => p.rating)
    .sort((a, b) => (b.rating || 0) - (a.rating || 0))
    .slice(0, 10);

  res.json({
    success: true,
    data: {
      totalProducts: products?.length || 0,
      activeProducts: products?.filter(p => p.status === 'active').length || 0,
      byCategory,
      topByViews,
      topByRating,
    },
  });
});

/**
 * @desc    Get regional analytics
 * @route   GET /api/v1/admin/analytics/regional
 */
const getRegionalAnalytics = asyncHandler(async (req, res) => {
  const { data: orders } = await supabase
    .from('orders')
    .select('id, total_amount, delivery_region, status')
    .eq('status', 'delivered');

  const { data: users } = await supabase
    .from('users')
    .select('id, region, role');

  // Orders by region
  const ordersByRegion = {};
  orders?.forEach(order => {
    const region = order.delivery_region || 'Unknown';
    if (!ordersByRegion[region]) {
      ordersByRegion[region] = { count: 0, amount: 0 };
    }
    ordersByRegion[region].count++;
    ordersByRegion[region].amount += order.total_amount || 0;
  });

  // Users by region
  const usersByRegion = {};
  users?.forEach(user => {
    const region = user.region || 'Unknown';
    if (!usersByRegion[region]) {
      usersByRegion[region] = { farmers: 0, buyers: 0 };
    }
    if (user.role === 'farmer') usersByRegion[region].farmers++;
    else usersByRegion[region].buyers++;
  });

  res.json({
    success: true,
    data: {
      ordersByRegion,
      usersByRegion,
    },
  });
});

/**
 * @desc    Send broadcast notification
 * @route   POST /api/v1/admin/notifications/broadcast
 */
const sendBroadcastNotification = asyncHandler(async (req, res) => {
  const { title, message, targetRole, targetRegion } = req.body;

  let query = supabase.from('users').select('id');
  if (targetRole) query = query.eq('role', targetRole);
  if (targetRegion) query = query.eq('region', targetRegion);

  const { data: users, error } = await query;

  if (error) {
    logger.error('Get users for broadcast error:', error);
    throw new ApiError(400, 'Failed to get target users');
  }

  // Create notifications for all users
  const notifications = users.map(user => ({
    user_id: user.id,
    type: 'broadcast',
    title,
    message,
    is_read: false,
    created_at: new Date().toISOString(),
  }));

  if (notifications.length > 0) {
    const { error: insertError } = await supabase
      .from('notifications')
      .insert(notifications);

    if (insertError) {
      logger.error('Insert notifications error:', insertError);
      throw new ApiError(400, 'Failed to send notifications');
    }
  }

  res.json({
    success: true,
    message: `Notification sent to ${notifications.length} users`,
    data: { recipientCount: notifications.length },
  });
});

/**
 * @desc    Export reports
 * @route   GET /api/v1/admin/reports/export
 */
const exportReports = asyncHandler(async (req, res) => {
  const { type, format = 'json', date_from, date_to } = req.query;

  let data;
  
  switch (type) {
    case 'users':
      const { data: users } = await supabase
        .from('users')
        .select('id, full_name, email, phone, role, region, is_verified, is_premium, created_at');
      data = users;
      break;
    
    case 'orders':
      let orderQuery = supabase
        .from('orders')
        .select('*');
      if (date_from) orderQuery = orderQuery.gte('created_at', date_from);
      if (date_to) orderQuery = orderQuery.lte('created_at', date_to);
      const { data: orders } = await orderQuery;
      data = orders;
      break;
    
    case 'products':
      const { data: products } = await supabase
        .from('products')
        .select('*');
      data = products;
      break;
    
    case 'payments':
      let paymentQuery = supabase
        .from('payments')
        .select('*');
      if (date_from) paymentQuery = paymentQuery.gte('created_at', date_from);
      if (date_to) paymentQuery = paymentQuery.lte('created_at', date_to);
      const { data: payments } = await paymentQuery;
      data = payments;
      break;
    
    default:
      throw new ApiError(400, 'Invalid report type');
  }

  if (format === 'csv') {
    // Convert to CSV
    if (!data || data.length === 0) {
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename=${type}_report.csv`);
      return res.send('No data');
    }

    const headers = Object.keys(data[0]).join(',');
    const rows = data.map(row => 
      Object.values(row).map(v => `"${String(v).replace(/"/g, '""')}"`).join(',')
    ).join('\n');
    
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename=${type}_report.csv`);
    return res.send(`${headers}\n${rows}`);
  }

  res.json({
    success: true,
    data,
    exportedAt: new Date().toISOString(),
    recordCount: data?.length || 0,
  });
});

/**
 * @desc    Get system settings
 * @route   GET /api/v1/admin/settings
 */
const getSettings = asyncHandler(async (req, res) => {
  const { data, error } = await supabase
    .from('system_settings')
    .select('*')
    .single();

  if (error && error.code !== 'PGRST116') {
    logger.error('Get settings error:', error);
    throw new ApiError(400, 'Failed to fetch settings');
  }

  // Return defaults if no settings found
  const settings = data || {
    maintenance_mode: false,
    registration_enabled: true,
    min_withdrawal_amount: 50000,
    commission_rate: 5,
    delivery_fee_per_km: 500,
    featured_product_fee: 10000,
    premium_monthly_fee: 50000,
    premium_yearly_fee: 500000,
    support_email: 'support@agrisupply.ug',
    support_phone: '+256700000000',
  };

  res.json({
    success: true,
    data: settings,
  });
});

/**
 * @desc    Update system settings
 * @route   PUT /api/v1/admin/settings
 */
const updateSettings = asyncHandler(async (req, res) => {
  const updates = req.body;
  updates.updated_at = new Date().toISOString();

  // Upsert settings
  const { data, error } = await supabase
    .from('system_settings')
    .upsert({
      id: 1, // Single settings row
      ...updates,
    })
    .select()
    .single();

  if (error) {
    logger.error('Update settings error:', error);
    throw new ApiError(400, 'Failed to update settings');
  }

  res.json({
    success: true,
    message: 'Settings updated',
    data,
  });
});

module.exports = {
  getDashboard,
  getUsers,
  getUserById,
  updateUser,
  verifyUser,
  suspendUser,
  unsuspendUser,
  deleteUser,
  getProducts,
  updateProduct,
  deleteProduct,
  getOrders,
  updateOrder,
  getPayments,
  processRefund,
  getSalesAnalytics,
  getUserAnalytics,
  getProductAnalytics,
  getRegionalAnalytics,
  sendBroadcastNotification,
  exportReports,
  getSettings,
  updateSettings,
};
