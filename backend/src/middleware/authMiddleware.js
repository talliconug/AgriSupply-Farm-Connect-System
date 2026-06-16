const { supabase, getUserFromToken, getUserProfile, verifyAdminAccess, verifyFarmerAccess } = require('../config/supabase');
const { ApiError } = require('./errorMiddleware');
const logger = require('../utils/logger');

/**
 * Authentication middleware
 * Verifies JWT token and attaches user to request
 */
const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new ApiError(401, 'Access denied. No token provided.');
    }
    
    const token = authHeader.substring(7);
    
    // Verify token with Supabase
    const user = await getUserFromToken(token);
    
    if (!user) {
      throw new ApiError(401, 'Invalid or expired token');
    }
    
    // Get user profile
    const profile = await getUserProfile(user.id);
    
    if (!profile) {
      throw new ApiError(401, 'User profile not found');
    }
    
    // Check if user is suspended
    if (profile.is_suspended) {
      throw new ApiError(403, 'Your account has been suspended. Please contact support.');
    }
    
    // Attach user to request
    req.user = {
      ...user,
      ...profile,
    };
    req.token = token;
    
    next();
  } catch (error) {
    if (error instanceof ApiError) {
      return res.status(error.statusCode).json({
        success: false,
        error: { message: error.message },
      });
    }
    
    logger.error('Authentication error:', error);
    return res.status(401).json({
      success: false,
      error: { message: 'Authentication failed' },
    });
  }
};

/**
 * Optional authentication middleware
 * Attaches user to request if token is valid, but doesn't require it
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const user = await getUserFromToken(token);
      
      if (user) {
        const profile = await getUserProfile(user.id);
        if (profile && !profile.is_suspended) {
          req.user = { ...user, ...profile };
          req.token = token;
        }
      }
    }
    
    next();
  } catch (error) {
    // Ignore errors and continue without user
    next();
  }
};

/**
 * Admin authorization middleware
 * Requires user to be an admin
 */
const requireAdmin = async (req, res, next) => {
  try {
    if (!req.user) {
      throw new ApiError(401, 'Authentication required');
    }
    
    const isAdmin = await verifyAdminAccess(req.user.id);
    
    if (!isAdmin) {
      throw new ApiError(403, 'Admin access required');
    }
    
    next();
  } catch (error) {
    if (error instanceof ApiError) {
      return res.status(error.statusCode).json({
        success: false,
        error: { message: error.message },
      });
    }
    
    logger.error('Admin authorization error:', error);
    return res.status(403).json({
      success: false,
      error: { message: 'Access denied' },
    });
  }
};

/**
 * Farmer authorization middleware
 * Requires user to be a farmer or admin
 */
const requireFarmer = async (req, res, next) => {
  try {
    if (!req.user) {
      throw new ApiError(401, 'Authentication required');
    }
    
    const isFarmer = await verifyFarmerAccess(req.user.id);
    
    if (!isFarmer) {
      throw new ApiError(403, 'Farmer access required');
    }
    
    next();
  } catch (error) {
    if (error instanceof ApiError) {
      return res.status(error.statusCode).json({
        success: false,
        error: { message: error.message },
      });
    }
    
    logger.error('Farmer authorization error:', error);
    return res.status(403).json({
      success: false,
      error: { message: 'Access denied' },
    });
  }
};

/**
 * Premium user middleware
 * Requires user to have premium subscription
 */
const requirePremium = async (req, res, next) => {
  try {
    if (!req.user) {
      throw new ApiError(401, 'Authentication required');
    }
    
    if (!req.user.is_premium) {
      throw new ApiError(403, 'Premium subscription required');
    }
    
    // Check if premium is still valid
    if (req.user.premium_expires_at) {
      const expiresAt = new Date(req.user.premium_expires_at);
      if (expiresAt < new Date()) {
        throw new ApiError(403, 'Premium subscription has expired');
      }
    }
    
    next();
  } catch (error) {
    if (error instanceof ApiError) {
      return res.status(error.statusCode).json({
        success: false,
        error: { message: error.message },
      });
    }
    
    logger.error('Premium authorization error:', error);
    return res.status(403).json({
      success: false,
      error: { message: 'Access denied' },
    });
  }
};

/**
 * Verified user middleware
 * Requires user to be verified
 */
const requireVerified = async (req, res, next) => {
  try {
    if (!req.user) {
      throw new ApiError(401, 'Authentication required');
    }
    
    if (!req.user.is_verified) {
      throw new ApiError(403, 'Account verification required');
    }
    
    next();
  } catch (error) {
    if (error instanceof ApiError) {
      return res.status(error.statusCode).json({
        success: false,
        error: { message: error.message },
      });
    }
    
    logger.error('Verification check error:', error);
    return res.status(403).json({
      success: false,
      error: { message: 'Access denied' },
    });
  }
};

/**
 * Resource ownership middleware factory
 * Checks if user owns the resource or is admin
 */
const requireOwnership = (getResourceUserId) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        throw new ApiError(401, 'Authentication required');
      }
      
      // Admins can access any resource
      if (req.user.role === 'admin') {
        return next();
      }
      
      // Get resource owner ID
      const resourceUserId = await getResourceUserId(req);
      
      if (!resourceUserId) {
        throw new ApiError(404, 'Resource not found');
      }
      
      if (resourceUserId !== req.user.id) {
        throw new ApiError(403, 'You do not have permission to access this resource');
      }
      
      next();
    } catch (error) {
      if (error instanceof ApiError) {
        return res.status(error.statusCode).json({
          success: false,
          error: { message: error.message },
        });
      }
      
      logger.error('Ownership check error:', error);
      return res.status(403).json({
        success: false,
        error: { message: 'Access denied' },
      });
    }
  };
};

module.exports = {
  authenticate,
  optionalAuth,
  requireAdmin,
  requireFarmer,
  requirePremium,
  requireVerified,
  requireOwnership,
};
