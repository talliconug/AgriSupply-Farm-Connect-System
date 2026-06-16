const { supabase } = require('../config/supabase');
const { ApiError, asyncHandler } = require('../middleware/errorMiddleware');
const { paginate, paginationResponse, generateOrderNumber, generateTrackingNumber, calculateDeliveryFee } = require('../utils/helpers');
const logger = require('../utils/logger');
const {
  createInAppNotification,
  createBulkInAppNotifications,
} = require('../utils/notificationHelper');

/**
 * @desc    Get current user's orders (buyer)
 * @route   GET /api/v1/orders
 */
const getMyOrders = asyncHandler(async (req, res) => {
  const { page, limit, status } = req.query;
  const { page: pageNum, limit: limitNum, offset } = paginate(page, limit);
  const userId = req.user.id;

  let query = supabase
    .from('orders')
    .select(`
      *,
      order_items (
        *,
        product:product_id (id, name, images, price, unit)
      )
    `, { count: 'exact' })
    .eq('buyer_id', userId);

  if (status) {
    query = query.eq('status', status);
  }

  const { data, count, error } = await query
    .order('created_at', { ascending: false })
    .range(offset, offset + limitNum - 1);

  if (error) {
    logger.error('Get orders error:', error);
    throw new ApiError(400, 'Failed to fetch orders');
  }

  res.json({
    success: true,
    ...paginationResponse(data, count, pageNum, limitNum),
  });
});

/**
 * @desc    Get orders for farmer's products
 * @route   GET /api/v1/orders/farmer
 */
const getFarmerOrders = asyncHandler(async (req, res) => {
  const { page, limit, status } = req.query;
  const { page: pageNum, limit: limitNum, offset } = paginate(page, limit);
  const farmerId = req.user.id;

  let query = supabase
    .from('orders')
    .select(`
      *,
      buyer:buyer_id (id, full_name, phone, photo_url),
      order_items!inner (
        *,
        product:product_id (id, name, images, price, unit)
      )
    `, { count: 'exact' })
    .eq('order_items.farmer_id', farmerId);

  if (status) {
    query = query.eq('status', status);
  }

  const { data, count, error } = await query
    .order('created_at', { ascending: false })
    .range(offset, offset + limitNum - 1);

  if (error) {
    logger.error('Get farmer orders error:', error);
    throw new ApiError(400, 'Failed to fetch orders');
  }

  res.json({
    success: true,
    ...paginationResponse(data, count, pageNum, limitNum),
  });
});

/**
 * @desc    Get order by ID
 * @route   GET /api/v1/orders/:id
 */
const getOrderById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const { data, error } = await supabase
    .from('orders')
    .select(`
      *,
      buyer:buyer_id (id, full_name, phone, photo_url),
      order_items (
        *,
        product:product_id (id, name, images, price, unit),
        farmer:farmer_id (id, full_name, phone, photo_url, region)
      )
    `)
    .eq('id', id)
    .single();

  if (error || !data) {
    throw new ApiError(404, 'Order not found');
  }

  // Check authorization
  const isBuyer = data.buyer_id === userId;
  const isFarmer = data.order_items.some(item => item.farmer_id === userId);
  const isAdmin = req.user.role === 'admin';

  if (!isBuyer && !isFarmer && !isAdmin) {
    throw new ApiError(403, 'Not authorized to view this order');
  }

  // Get order status history
  const { data: history } = await supabase
    .from('order_status_history')
    .select('*')
    .eq('order_id', id)
    .order('created_at', { ascending: true });

  res.json({
    success: true,
    data: {
      ...data,
      statusHistory: history || [],
    },
  });
});

/**
 * @desc    Create a new order
 * @route   POST /api/v1/orders
 */
const createOrder = asyncHandler(async (req, res) => {
  // Accept both mobile (deliveryAddress) and web (shippingAddress) formats
  const { items, deliveryAddress, shippingAddress, paymentMethod, notes } = req.body;
  const buyerId = req.user.id;

  // Get user's region for delivery calculation
  const { data: buyer } = await supabase
    .from('users')
    .select('region')
    .eq('id', buyerId)
    .single();

  // Normalize address format - accept both string and object
  let normalizedAddress;
  let buyerRegion;
  
  if (shippingAddress) {
    // Web format: object with region
    normalizedAddress = shippingAddress;
    buyerRegion = shippingAddress.region;
  } else if (deliveryAddress) {
    // Mobile format: simple string or object
    if (typeof deliveryAddress === 'string') {
      normalizedAddress = {
        address: deliveryAddress,
        region: buyer?.region || 'Central',
      };
    } else {
      normalizedAddress = deliveryAddress;
    }
    buyerRegion = normalizedAddress.region || buyer?.region || 'Central';
  } else {
    throw new ApiError(400, 'Delivery address is required');
  }

  // Validate and fetch products
  const productIds = items.map(item => item.productId);
  const { data: products, error: productsError } = await supabase
    .from('products')
    .select('*, farmer:farmer_id (id, region)')
    .in('id', productIds);

  if (productsError || products.length !== productIds.length) {
    throw new ApiError(400, 'One or more products not found');
  }

  // Validate quantities and calculate totals
  let subtotal = 0;
  const orderItems = [];

  for (const item of items) {
    const product = products.find(p => p.id === item.productId);
    
    if (product.quantity_available < item.quantity) {
      throw new ApiError(400, `Insufficient quantity for ${product.name}`);
    }

    const itemTotal = product.price * item.quantity;
    subtotal += itemTotal;

    orderItems.push({
      product_id: product.id,
      farmer_id: product.farmer_id,
      product_name: product.name,
      product_image: Array.isArray(product.images) ? (product.images[0] || null) : null,
      unit_price: product.price,
      quantity: item.quantity,
      subtotal: itemTotal,
      price: product.price,
      total: itemTotal,
      status: 'pending',
    });
  }

  // Calculate delivery fee
  const uniqueFarmerRegions = [...new Set(
    products.map(p => p.farmer?.region || buyerRegion),
  )];
  let deliveryFee = 0;
  
  for (const farmerRegion of uniqueFarmerRegions) {
    deliveryFee += calculateDeliveryFee(farmerRegion, buyerRegion);
  }

  const total = subtotal + deliveryFee;

  // Create order
  const orderNumber = generateOrderNumber();
  
  const orderInsertPayload = {
    buyer_id: buyerId,
    order_number: orderNumber,
    status: 'pending',
    payment_status: 'pending',
    payment_method: paymentMethod,
    subtotal,
    delivery_fee: deliveryFee,
    total_amount: total,
    total,
    delivery_address: typeof normalizedAddress.address === 'string'
      ? normalizedAddress.address
      : (typeof deliveryAddress === 'string' ? deliveryAddress : JSON.stringify(normalizedAddress)),
    shipping_address: normalizedAddress,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  let order;
  let orderError;
  const sanitizedInsertPayload = { ...orderInsertPayload };

  // Handle schema drift gracefully by removing unknown columns and retrying.
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const insertResult = await supabase
      .from('orders')
      .insert(sanitizedInsertPayload)
      .select()
      .single();

    order = insertResult.data;
    orderError = insertResult.error;

    if (!orderError) {
      break;
    }

    const missingColumnMatch = /Could not find the '([^']+)' column/i.exec(orderError.message || '');
    if (!missingColumnMatch) {
      break;
    }

    const missingColumn = missingColumnMatch[1];
    if (!(missingColumn in sanitizedInsertPayload)) {
      break;
    }

    delete sanitizedInsertPayload[missingColumn];
    logger.warn(`Order schema mismatch detected. Retrying without column: ${missingColumn}`);
  }

  if (orderError || !order) {
    logger.error('Create order error:', orderError);
    throw new ApiError(400, `Failed to create order: ${orderError.message || JSON.stringify(orderError)}`);
  }

  // Create order items
  const itemsWithOrderId = orderItems.map(item => ({
    ...item,
    order_id: order.id,
    buyer_id: buyerId,
    created_at: new Date().toISOString(),
  }));

  let itemsError;
  let sanitizedItemsPayload = itemsWithOrderId.map(item => ({ ...item }));

  // Handle order_items schema drift similarly to orders by pruning unknown columns and retrying.
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const insertItemsResult = await supabase
      .from('order_items')
      .insert(sanitizedItemsPayload);

    itemsError = insertItemsResult.error;

    if (!itemsError) {
      break;
    }

    const missingColumnMatch = /Could not find the '([^']+)' column/i.exec(itemsError.message || '');
    if (!missingColumnMatch) {
      break;
    }

    const missingColumn = missingColumnMatch[1];
    sanitizedItemsPayload = sanitizedItemsPayload.map((row) => {
      if (missingColumn in row) {
        const next = { ...row };
        delete next[missingColumn];
        return next;
      }
      return row;
    });

    logger.warn(`Order items schema mismatch detected. Retrying without column: ${missingColumn}`);
  }

  if (itemsError) {
    // Rollback order
    await supabase.from('orders').delete().eq('id', order.id);
    logger.error('Create order items error:', itemsError);
    throw new ApiError(400, `Failed to create order items: ${itemsError.message || JSON.stringify(itemsError)}`);
  }

  // Update product quantities
  for (const item of items) {
    const product = products.find(p => p.id === item.productId);
    await supabase
      .from('products')
      .update({ quantity_available: product.quantity_available - item.quantity })
      .eq('id', item.productId);
  }

  // Create initial status history
  await supabase.from('order_status_history').insert({
    order_id: order.id,
    status: 'pending',
    notes: 'Order placed',
    created_at: new Date().toISOString(),
  });

  await createInAppNotification({
    userId: buyerId,
    type: 'order_placed',
    title: 'Order Placed',
    message: `Your order #${orderNumber} was placed successfully`,
    data: { orderId: order.id },
  });

  // Notify farmers
  const farmerIds = [...new Set(orderItems.map(item => item.farmer_id))];
  await createBulkInAppNotifications({
    userIds: farmerIds,
    type: 'order_placed',
    title: 'New Order Received',
    message: `You have a new order #${orderNumber}`,
    data: { orderId: order.id },
  });

  res.status(201).json({
    success: true,
    message: 'Order created successfully',
    data: {
      ...order,
      items: itemsWithOrderId,
    },
  });
});

/**
 * @desc    Update order status
 * @route   PUT /api/v1/orders/:id/status
 */
const updateOrderStatus = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status, note } = req.body;
  const userId = req.user.id;

  const { data: order } = await supabase
    .from('orders')
    .select('*, order_items (farmer_id)')
    .eq('id', id)
    .single();

  if (!order) {
    throw new ApiError(404, 'Order not found');
  }

  // Check authorization
  const isFarmer = order.order_items.some(item => item.farmer_id === userId);
  const isAdmin = req.user.role === 'admin';

  if (!isFarmer && !isAdmin) {
    throw new ApiError(403, 'Not authorized to update this order');
  }

  // Update order status
  const { data, error } = await supabase
    .from('orders')
    .update({
      status,
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    logger.error('Update order status error:', error);
    throw new ApiError(400, 'Failed to update order status');
  }

  // Add to status history
  await supabase.from('order_status_history').insert({
    order_id: id,
    status,
    notes: note,
    changed_by: userId,
    created_at: new Date().toISOString(),
  });

  // Notify buyer
  await createInAppNotification({
    userId: order.buyer_id,
    type: `order_${status}`,
    title: 'Order Update',
    message: `Your order #${order.order_number} is now ${status}`,
    data: { orderId: id },
  });

  res.json({
    success: true,
    message: 'Order status updated successfully',
    data,
  });
});

/**
 * @desc    Confirm order (Farmer)
 * @route   POST /api/v1/orders/:id/confirm
 */
const confirmOrder = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const farmerId = req.user.id;

  // Update farmer's order items status
  const { error: itemsError } = await supabase
    .from('order_items')
    .update({ status: 'confirmed' })
    .eq('order_id', id)
    .eq('farmer_id', farmerId);

  if (itemsError) {
    logger.error('Confirm order items error:', itemsError);
    throw new ApiError(400, 'Failed to confirm order');
  }

  // Check if all items are confirmed
  const { data: items } = await supabase
    .from('order_items')
    .select('status')
    .eq('order_id', id);

  const allConfirmed = items.every(item => item.status !== 'pending');

  if (allConfirmed) {
    await supabase
      .from('orders')
      .update({ status: 'confirmed', updated_at: new Date().toISOString() })
      .eq('id', id);

    // Add to status history
    await supabase.from('order_status_history').insert({
      order_id: id,
      status: 'confirmed',
      notes: 'Order confirmed by all farmers',
      changed_by: farmerId,
      created_at: new Date().toISOString(),
    });
  }

  // Get order for notification
  const { data: order } = await supabase
    .from('orders')
    .select('buyer_id, order_number')
    .eq('id', id)
    .single();

  // Notify buyer
  await supabase.from('notifications').insert({
    user_id: order.buyer_id,
    type: 'order_confirmed',
    title: 'Order Confirmed',
    message: `A farmer has confirmed your order #${order.order_number}`,
    data: { orderId: id },
    created_at: new Date().toISOString(),
  });

  res.json({
    success: true,
    message: 'Order confirmed successfully',
  });
});

/**
 * @desc    Mark order as shipped (Farmer)
 * @route   POST /api/v1/orders/:id/ship
 */
const shipOrder = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { trackingNumber, estimatedDelivery } = req.body;
  const farmerId = req.user.id;

  const tracking = trackingNumber || generateTrackingNumber();

  // Update farmer's order items status
  const { error: itemsError } = await supabase
    .from('order_items')
    .update({
      status: 'shipped',
      tracking_number: tracking,
      estimated_delivery: estimatedDelivery,
    })
    .eq('order_id', id)
    .eq('farmer_id', farmerId);

  if (itemsError) {
    logger.error('Ship order items error:', itemsError);
    throw new ApiError(400, 'Failed to update shipping status');
  }

  // Check if all items are shipped
  const { data: items } = await supabase
    .from('order_items')
    .select('status')
    .eq('order_id', id);

  const allShipped = items.every(item => 
    item.status === 'shipped' || item.status === 'delivered'
  );

  if (allShipped) {
    await supabase
      .from('orders')
      .update({
        status: 'shipped',
        tracking_number: tracking,
        estimated_delivery: estimatedDelivery,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id);

    // Add to status history
    await supabase.from('order_status_history').insert({
      order_id: id,
      status: 'shipped',
      notes: `Tracking: ${tracking}`,
      changed_by: farmerId,
      created_at: new Date().toISOString(),
    });
  }

  // Get order for notification
  const { data: order } = await supabase
    .from('orders')
    .select('buyer_id, order_number')
    .eq('id', id)
    .single();

  // Notify buyer
  await supabase.from('notifications').insert({
    user_id: order.buyer_id,
    type: 'order_shipped',
    title: 'Order Shipped',
    message: `Your order #${order.order_number} has been shipped. Track: ${tracking}`,
    data: { orderId: id, trackingNumber: tracking },
    created_at: new Date().toISOString(),
  });

  res.json({
    success: true,
    message: 'Order marked as shipped',
    data: { trackingNumber: tracking },
  });
});

/**
 * @desc    Mark order as delivered
 * @route   POST /api/v1/orders/:id/deliver
 */
const deliverOrder = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const { data: order } = await supabase
    .from('orders')
    .select('*, order_items (farmer_id)')
    .eq('id', id)
    .single();

  if (!order) {
    throw new ApiError(404, 'Order not found');
  }

  // Update order status
  const { data, error } = await supabase
    .from('orders')
    .update({
      status: 'delivered',
      delivered_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    logger.error('Deliver order error:', error);
    throw new ApiError(400, 'Failed to update delivery status');
  }

  // Update all order items
  await supabase
    .from('order_items')
    .update({ status: 'delivered' })
    .eq('order_id', id);

  // Add to status history
  await supabase.from('order_status_history').insert({
    order_id: id,
    status: 'delivered',
    notes: 'Order delivered successfully',
    changed_by: userId,
    created_at: new Date().toISOString(),
  });

  // Notify buyer
  await supabase.from('notifications').insert({
    user_id: order.buyer_id,
    type: 'order_delivered',
    title: 'Order Delivered',
    message: `Your order #${order.order_number} has been delivered!`,
    data: { orderId: id },
    created_at: new Date().toISOString(),
  });

  res.json({
    success: true,
    message: 'Order marked as delivered',
    data,
  });
});

/**
 * @desc    Cancel order
 * @route   POST /api/v1/orders/:id/cancel
 */
const cancelOrder = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;
  const userId = req.user.id;

  const { data: order } = await supabase
    .from('orders')
    .select('*, order_items (*)')
    .eq('id', id)
    .single();

  if (!order) {
    throw new ApiError(404, 'Order not found');
  }

  // Check authorization
  const isBuyer = order.buyer_id === userId;
  const isFarmer = order.order_items.some(item => item.farmer_id === userId);
  const isAdmin = req.user.role === 'admin';

  if (!isBuyer && !isFarmer && !isAdmin) {
    throw new ApiError(403, 'Not authorized to cancel this order');
  }

  // Check if order can be cancelled
  if (['delivered', 'cancelled', 'refunded'].includes(order.status)) {
    throw new ApiError(400, 'Order cannot be cancelled');
  }

  // Update order status
  const { data, error } = await supabase
    .from('orders')
    .update({
      status: 'cancelled',
      cancelled_at: new Date().toISOString(),
      cancellation_reason: reason,
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    logger.error('Cancel order error:', error);
    throw new ApiError(400, 'Failed to cancel order');
  }

  // Update all order items
  await supabase
    .from('order_items')
    .update({ status: 'cancelled' })
    .eq('order_id', id);

  // Restore product quantities
  for (const item of order.order_items) {
    const { data: product } = await supabase
      .from('products')
      .select('quantity_available')
      .eq('id', item.product_id)
      .single();

    await supabase
      .from('products')
      .update({ quantity_available: product.quantity_available + item.quantity })
      .eq('id', item.product_id);
  }

  // Add to status history
  await supabase.from('order_status_history').insert({
    order_id: id,
    status: 'cancelled',
    notes: reason || 'Order cancelled',
    changed_by: userId,
    created_at: new Date().toISOString(),
  });

  // Notify relevant parties
  const notifyUsers = [order.buyer_id];
  const farmerIds = [...new Set(order.order_items.map(item => item.farmer_id))];
  notifyUsers.push(...farmerIds.filter(fid => fid !== userId));

  for (const notifyUserId of notifyUsers) {
    if (notifyUserId !== userId) {
      await supabase.from('notifications').insert({
        user_id: notifyUserId,
        type: 'order_cancelled',
        title: 'Order Cancelled',
        message: `Order #${order.order_number} has been cancelled`,
        data: { orderId: id },
        created_at: new Date().toISOString(),
      });
    }
  }

  res.json({
    success: true,
    message: 'Order cancelled successfully',
    data,
  });
});

/**
 * @desc    Request refund for order
 * @route   POST /api/v1/orders/:id/refund
 */
const requestRefund = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;
  const userId = req.user.id;

  const { data: order } = await supabase
    .from('orders')
    .select('*')
    .eq('id', id)
    .single();

  if (!order) {
    throw new ApiError(404, 'Order not found');
  }

  if (order.buyer_id !== userId) {
    throw new ApiError(403, 'Not authorized to request refund');
  }

  if (order.payment_status !== 'completed') {
    throw new ApiError(400, 'Cannot request refund for unpaid order');
  }

  // Update order
  const { data, error } = await supabase
    .from('orders')
    .update({
      refund_requested: true,
      refund_reason: reason,
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    logger.error('Request refund error:', error);
    throw new ApiError(400, 'Failed to request refund');
  }

  // Notify admin
  await supabase.from('notifications').insert({
    user_id: null, // Admin notification
    type: 'refund_requested',
    title: 'Refund Requested',
    message: `Refund requested for order #${order.order_number}`,
    data: { orderId: id, reason },
    is_admin: true,
    created_at: new Date().toISOString(),
  });

  res.json({
    success: true,
    message: 'Refund request submitted',
    data,
  });
});

/**
 * @desc    Get order tracking information
 * @route   GET /api/v1/orders/:id/tracking
 */
const getOrderTracking = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const { data: order } = await supabase
    .from('orders')
    .select('id, order_number, status, tracking_number, estimated_delivery, shipped_at, delivered_at')
    .eq('id', id)
    .single();

  if (!order) {
    throw new ApiError(404, 'Order not found');
  }

  const { data: history } = await supabase
    .from('order_status_history')
    .select('*')
    .eq('order_id', id)
    .order('created_at', { ascending: true });

  res.json({
    success: true,
    data: {
      ...order,
      statusHistory: history || [],
    },
  });
});

/**
 * @desc    Get order status history
 * @route   GET /api/v1/orders/:id/history
 */
const getOrderHistory = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const { data, error } = await supabase
    .from('order_status_history')
    .select(`
      *,
      changed_by_user:changed_by (id, full_name, role)
    `)
    .eq('order_id', id)
    .order('created_at', { ascending: false });

  if (error) {
    logger.error('Get order history error:', error);
    throw new ApiError(400, 'Failed to fetch order history');
  }

  res.json({
    success: true,
    data,
  });
});

/**
 * @desc    Get order statistics summary
 * @route   GET /api/v1/orders/statistics/summary
 */
const getOrderStatistics = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const isFarmer = req.user.role === 'farmer';

  let stats = {};

  if (isFarmer) {
    // Farmer order stats
    const statuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
    
    for (const status of statuses) {
      const { count } = await supabase
        .from('order_items')
        .select('*', { count: 'exact', head: true })
        .eq('farmer_id', userId)
        .eq('status', status);
      stats[status] = count;
    }

    // Total revenue
    const { data: revenue } = await supabase
      .from('order_items')
      .select('total')
      .eq('farmer_id', userId)
      .eq('status', 'delivered');

    stats.totalRevenue = revenue?.reduce((sum, item) => sum + item.total, 0) || 0;
  } else {
    // Buyer order stats
    const statuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
    
    for (const status of statuses) {
      const { count } = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true })
        .eq('buyer_id', userId)
        .eq('status', status);
      stats[status] = count;
    }

    // Total spent
    const { data: spent } = await supabase
      .from('orders')
      .select('total')
      .eq('buyer_id', userId)
      .eq('status', 'delivered');

    stats.totalSpent = spent?.reduce((sum, item) => sum + item.total, 0) || 0;
  }

  res.json({
    success: true,
    data: stats,
  });
});

module.exports = {
  getMyOrders,
  getFarmerOrders,
  getOrderById,
  createOrder,
  updateOrderStatus,
  confirmOrder,
  shipOrder,
  deliverOrder,
  cancelOrder,
  requestRefund,
  getOrderTracking,
  getOrderHistory,
  getOrderStatistics,
};
