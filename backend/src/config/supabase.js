const { createClient } = require('@supabase/supabase-js');
const logger = require('../utils/logger');

const requiredEnvVars = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'SUPABASE_ANON_KEY'];
const missingEnvVars = requiredEnvVars.filter((name) => !process.env[name]);

if (missingEnvVars.length > 0) {
  const message = `Missing required Supabase environment variables: ${missingEnvVars.join(', ')}`;
  logger.error(message);
  throw new Error(message);
}

const decodeJwtPayload = (token) => {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const pad = base64.length % 4;
    const padded = base64 + (pad ? '='.repeat(4 - pad) : '');
    const payload = Buffer.from(padded, 'base64').toString('utf8');
    return JSON.parse(payload);
  } catch (error) {
    return null;
  }
};

const serviceKeyPayload = decodeJwtPayload(process.env.SUPABASE_SERVICE_ROLE_KEY);
if (!serviceKeyPayload || serviceKeyPayload.role !== 'service_role') {
  const message = 'SUPABASE_SERVICE_ROLE_KEY is invalid or does not have role=service_role';
  logger.error(message);
  throw new Error(message);
}

const anonKeyPayload = decodeJwtPayload(process.env.SUPABASE_ANON_KEY);
if (!anonKeyPayload || anonKeyPayload.role !== 'anon') {
  const message = 'SUPABASE_ANON_KEY is invalid or does not have role=anon';
  logger.error(message);
  throw new Error(message);
}

// Create Supabase client with service role key for backend operations
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

// Create Supabase client with anon key for user-authenticated operations
const supabaseAnon = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY,
  {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
    },
  }
);

/**
 * Get user from access token
 * @param {string} accessToken - JWT access token
 * @returns {Promise<Object|null>} User object or null
 */
const getUserFromToken = async (accessToken) => {
  try {
    const { data: { user }, error } = await supabaseAnon.auth.getUser(accessToken);
    
    if (error) {
      logger.error('Error getting user from token:', error);
      return null;
    }
    
    return user;
  } catch (error) {
    logger.error('Error in getUserFromToken:', error);
    return null;
  }
};

/**
 * Get user profile from database
 * @param {string} userId - User ID
 * @returns {Promise<Object|null>} User profile or null
 */
const getUserProfile = async (userId) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();
    
    if (error) {
      logger.error('Error getting user profile:', error);
      return null;
    }
    
    return data;
  } catch (error) {
    logger.error('Error in getUserProfile:', error);
    return null;
  }
};

/**
 * Verify admin access
 * @param {string} userId - User ID
 * @returns {Promise<boolean>} True if user is admin
 */
const verifyAdminAccess = async (userId) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('role')
      .eq('id', userId)
      .single();
    
    if (error || !data) {
      return false;
    }
    
    return data.role === 'admin';
  } catch (error) {
    logger.error('Error verifying admin access:', error);
    return false;
  }
};

/**
 * Verify farmer access
 * @param {string} userId - User ID
 * @returns {Promise<boolean>} True if user is farmer
 */
const verifyFarmerAccess = async (userId) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('role')
      .eq('id', userId)
      .single();
    
    if (error || !data) {
      return false;
    }
    
    return data.role === 'farmer' || data.role === 'admin';
  } catch (error) {
    logger.error('Error verifying farmer access:', error);
    return false;
  }
};

/**
 * Upload file to Supabase Storage
 * @param {Buffer} fileBuffer - File buffer
 * @param {string} bucket - Storage bucket name
 * @param {string} filePath - Path within bucket
 * @param {string} contentType - File content type
 * @returns {Promise<Object>} Upload result
 */
const uploadFile = async (fileBuffer, bucket, filePath, contentType) => {
  try {
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(filePath, fileBuffer, {
        contentType,
        upsert: true,
      });
    
    if (error) {
      throw error;
    }
    
    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from(bucket)
      .getPublicUrl(filePath);
    
    return {
      success: true,
      path: data.path,
      publicUrl,
    };
  } catch (error) {
    logger.error('Error uploading file:', error);
    return {
      success: false,
      error: error.message,
    };
  }
};

/**
 * Delete file from Supabase Storage
 * @param {string} bucket - Storage bucket name
 * @param {string} filePath - Path within bucket
 * @returns {Promise<boolean>} True if deleted successfully
 */
const deleteFile = async (bucket, filePath) => {
  try {
    const { error } = await supabase.storage
      .from(bucket)
      .remove([filePath]);
    
    if (error) {
      throw error;
    }
    
    return true;
  } catch (error) {
    logger.error('Error deleting file:', error);
    return false;
  }
};

/**
 * Send real-time notification
 * @param {string} channel - Channel name
 * @param {string} event - Event name
 * @param {Object} payload - Notification payload
 */
const sendRealtimeNotification = async (channel, event, payload) => {
  try {
    // This is handled by Supabase's real-time subscriptions
    // Client-side will subscribe to the notifications table changes
    logger.info(`Real-time notification sent: ${channel}/${event}`);
  } catch (error) {
    logger.error('Error sending real-time notification:', error);
  }
};

module.exports = {
  supabase,
  supabaseAnon,
  getUserFromToken,
  getUserProfile,
  verifyAdminAccess,
  verifyFarmerAccess,
  uploadFile,
  deleteFile,
  sendRealtimeNotification,
};
