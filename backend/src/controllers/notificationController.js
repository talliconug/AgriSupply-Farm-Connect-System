const { supabase } = require('../config/supabase');
const { ApiError, asyncHandler } = require('../middleware/errorMiddleware');
const { paginate, paginationResponse } = require('../utils/helpers');
const logger = require('../utils/logger');

/**
 * @desc    Get all notifications for current user
 * @route   GET /api/v1/notifications
 */
const getNotifications = asyncHandler(async (req, res) => {
  const { page, limit, isRead, type } = req.query;
  const { page: pageNum, limit: limitNum, offset } = paginate(page, limit);
  const userId = req.user.id;

  let query = supabase
    .from('notifications')
    .select('*', { count: 'exact' })
    .eq('user_id', userId);

  if (isRead !== undefined) {
    query = query.eq('is_read', isRead === 'true');
  }

  if (type) {
    query = query.eq('type', type);
  }

  const { data, count, error } = await query
    .order('created_at', { ascending: false })
    .range(offset, offset + limitNum - 1);

  if (error) {
    logger.error('Get notifications error:', error);
    throw new ApiError(400, 'Failed to fetch notifications');
  }

  res.json({
    success: true,
    ...paginationResponse(data, count, pageNum, limitNum),
  });
});

/**
 * @desc    Get unread notification count
 * @route   GET /api/v1/notifications/unread-count
 */
const getUnreadCount = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const { count, error } = await supabase
    .from('notifications')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('is_read', false);

  if (error) {
    logger.error('Get unread count error:', error);
    throw new ApiError(400, 'Failed to fetch unread count');
  }

  res.json({
    success: true,
    data: { unreadCount: count },
  });
});

/**
 * @desc    Get notification by ID
 * @route   GET /api/v1/notifications/:id
 */
const getNotificationById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const { data, error } = await supabase
    .from('notifications')
    .select('*')
    .eq('id', id)
    .eq('user_id', userId)
    .single();

  if (error || !data) {
    throw new ApiError(404, 'Notification not found');
  }

  res.json({
    success: true,
    data,
  });
});

/**
 * @desc    Mark notification as read
 * @route   PUT /api/v1/notifications/:id/read
 */
const markAsRead = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const { data, error } = await supabase
    .from('notifications')
    .update({
      is_read: true,
      read_at: new Date().toISOString(),
    })
    .eq('id', id)
    .eq('user_id', userId)
    .select()
    .single();

  if (error) {
    logger.error('Mark as read error:', error);
    throw new ApiError(400, 'Failed to mark notification as read');
  }

  res.json({
    success: true,
    message: 'Notification marked as read',
    data,
  });
});

/**
 * @desc    Mark all notifications as read
 * @route   PUT /api/v1/notifications/read-all
 */
const markAllAsRead = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const { error } = await supabase
    .from('notifications')
    .update({
      is_read: true,
      read_at: new Date().toISOString(),
    })
    .eq('user_id', userId)
    .eq('is_read', false);

  if (error) {
    logger.error('Mark all as read error:', error);
    throw new ApiError(400, 'Failed to mark notifications as read');
  }

  res.json({
    success: true,
    message: 'All notifications marked as read',
  });
});

/**
 * @desc    Delete notification
 * @route   DELETE /api/v1/notifications/:id
 */
const deleteNotification = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const { error } = await supabase
    .from('notifications')
    .delete()
    .eq('id', id)
    .eq('user_id', userId);

  if (error) {
    logger.error('Delete notification error:', error);
    throw new ApiError(400, 'Failed to delete notification');
  }

  res.json({
    success: true,
    message: 'Notification deleted',
  });
});

/**
 * @desc    Delete all notifications
 * @route   DELETE /api/v1/notifications
 */
const deleteAllNotifications = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const { error } = await supabase
    .from('notifications')
    .delete()
    .eq('user_id', userId);

  if (error) {
    logger.error('Delete all notifications error:', error);
    throw new ApiError(400, 'Failed to delete notifications');
  }

  res.json({
    success: true,
    message: 'All notifications deleted',
  });
});

/**
 * @desc    Get notification preferences
 * @route   GET /api/v1/notifications/preferences
 */
const getPreferences = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  let { data, error } = await supabase
    .from('notification_preferences')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (error || !data) {
    // Create default preferences if not exist
    const { data: newPrefs, error: createError } = await supabase
      .from('notification_preferences')
      .insert({
        user_id: userId,
        order_updates: true,
        promotions: true,
        farming_tips: req.user.role === 'farmer',
        price_alerts: true,
        push_enabled: true,
        email_enabled: true,
        sms_enabled: false,
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (createError) {
      logger.error('Create preferences error:', createError);
      throw new ApiError(400, 'Failed to get preferences');
    }

    data = newPrefs;
  }

  res.json({
    success: true,
    data,
  });
});

/**
 * @desc    Update notification preferences
 * @route   PUT /api/v1/notifications/preferences
 */
const updatePreferences = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const updates = req.body;

  const allowedFields = [
    'order_updates',
    'promotions',
    'farming_tips',
    'price_alerts',
    'push_enabled',
    'email_enabled',
    'sms_enabled',
  ];

  const filteredUpdates = {};
  for (const field of allowedFields) {
    if (updates[field] !== undefined) {
      filteredUpdates[field] = updates[field];
    }
  }

  filteredUpdates.updated_at = new Date().toISOString();

  const { data, error } = await supabase
    .from('notification_preferences')
    .update(filteredUpdates)
    .eq('user_id', userId)
    .select()
    .single();

  if (error) {
    logger.error('Update preferences error:', error);
    throw new ApiError(400, 'Failed to update preferences');
  }

  res.json({
    success: true,
    message: 'Preferences updated',
    data,
  });
});

/**
 * @desc    Register device for push notifications
 * @route   POST /api/v1/notifications/register-device
 */
const registerDevice = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { deviceToken, platform } = req.body;

  if (!deviceToken || !platform) {
    throw new ApiError(400, 'Device token and platform are required');
  }

  // Check if device already registered
  const { data: existing } = await supabase
    .from('user_devices')
    .select('id')
    .eq('user_id', userId)
    .eq('device_token', deviceToken)
    .single();

  if (existing) {
    // Update existing device
    await supabase
      .from('user_devices')
      .update({
        platform,
        updated_at: new Date().toISOString(),
      })
      .eq('id', existing.id);
  } else {
    // Register new device
    await supabase.from('user_devices').insert({
      user_id: userId,
      device_token: deviceToken,
      platform,
      created_at: new Date().toISOString(),
    });
  }

  res.json({
    success: true,
    message: 'Device registered for push notifications',
  });
});

/**
 * @desc    Unregister device from push notifications
 * @route   DELETE /api/v1/notifications/unregister-device
 */
const unregisterDevice = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { deviceToken } = req.body;

  if (!deviceToken) {
    throw new ApiError(400, 'Device token is required');
  }

  const { error } = await supabase
    .from('user_devices')
    .delete()
    .eq('user_id', userId)
    .eq('device_token', deviceToken);

  if (error) {
    logger.error('Unregister device error:', error);
    throw new ApiError(400, 'Failed to unregister device');
  }

  res.json({
    success: true,
    message: 'Device unregistered from push notifications',
  });
});

/**
 * Helper function to send notification
 */
const sendNotification = async (userId, notification) => {
  try {
    const { error } = await supabase.from('notifications').insert({
      user_id: userId,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      data: notification.data || {},
      created_at: new Date().toISOString(),
    });

    if (error) {
      logger.error('Send notification error:', error);
    }

// Send actual notifications
  try {
    await notificationService.sendNotificationToUser(userId, {
      title: notification.title,
      body: notification.message,
      type: notification.type,
      referenceId: notification.reference_id,
      data: notification.data || {},
    });
  } catch (error) {
    logger.error('Failed to send notification:', error);
    // Don't fail the request if external notification fails
  }

  } catch (error) {
    logger.error('Send notification error:', error);
  }
};

/**
 * Helper function to send bulk notifications
 */
const sendBulkNotifications = async (userIds, notification) => {
  try {
    const notifications = userIds.map(userId => ({
      user_id: userId,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      data: notification.data || {},
      created_at: new Date().toISOString(),
    }));

    const { error } = await supabase.from('notifications').insert(notifications);

    if (error) {
      logger.error('Send bulk notifications error:', error);
    }
  } catch (error) {
    logger.error('Send bulk notifications error:', error);
  }
};

module.exports = {
  getNotifications,
  getUnreadCount,
  getNotificationById,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  deleteAllNotifications,
  getPreferences,
  updatePreferences,
  registerDevice,
  unregisterDevice,
  sendNotification,
  sendBulkNotifications,
};
