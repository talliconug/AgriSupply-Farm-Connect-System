const { supabase } = require('../config/supabase');
const logger = require('./logger');

const createInAppNotification = async ({
  userId,
  type,
  title,
  message,
  data = {},
}) => {
  try {
    const { error } = await supabase.from('notifications').insert({
      user_id: userId,
      type,
      title,
      message,
      data,
      is_read: false,
      created_at: new Date().toISOString(),
    });

    if (error) {
      logger.error('Create notification error:', error);
    }
  } catch (error) {
    logger.error('Create notification helper error:', error);
  }
};

const createBulkInAppNotifications = async ({
  userIds,
  type,
  title,
  message,
  data = {},
}) => {
  if (!userIds?.length) return;

  try {
    const now = new Date().toISOString();
    const rows = userIds.map((userId) => ({
      user_id: userId,
      type,
      title,
      message,
      data,
      is_read: false,
      created_at: now,
    }));

    const { error } = await supabase.from('notifications').insert(rows);

    if (error) {
      logger.error('Create bulk notifications error:', error);
    }
  } catch (error) {
    logger.error('Create bulk notifications helper error:', error);
  }
};

module.exports = {
  createInAppNotification,
  createBulkInAppNotifications,
};
