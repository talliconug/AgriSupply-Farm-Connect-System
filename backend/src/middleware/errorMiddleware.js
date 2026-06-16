const logger = require('../utils/logger');

/**
 * Custom API Error class
 */
class ApiError extends Error {
  constructor(statusCode, message, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
    this.isOperational = true;
    
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Not found middleware
 */
const notFound = (req, res, next) => {
  const error = new ApiError(404, `Not Found - ${req.originalUrl}`);
  next(error);
};

/**
 * Error handler middleware
 */
const errorHandler = (err, req, res, next) => {
  // Log the error
  logger.logError(err, req);
  
  // Handle specific error types
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';
  let details = err.details || null;
  
  // Handle Supabase errors
  if (err.code) {
    switch (err.code) {
      case 'PGRST116':
        statusCode = 404;
        message = 'Resource not found';
        break;
      case '23505':
        statusCode = 409;
        message = 'Duplicate entry';
        break;
      case '23503':
        statusCode = 400;
        message = 'Invalid reference';
        break;
      case '42501':
        statusCode = 403;
        message = 'Insufficient permissions';
        break;
      case 'PGRST301':
        statusCode = 400;
        message = 'Invalid query parameters';
        break;
      default:
        if (err.code.startsWith('22')) {
          statusCode = 400;
          message = 'Invalid input data';
        }
    }
  }
  
  // Handle validation errors
  if (err.name === 'ValidationError') {
    statusCode = 400;
    message = 'Validation Error';
    details = err.errors;
  }
  
  // Handle JWT errors
  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Invalid token';
  }
  
  if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Token expired';
  }
  
  // Handle multer errors
  if (err.name === 'MulterError') {
    statusCode = 400;
    switch (err.code) {
      case 'LIMIT_FILE_SIZE':
        message = 'File too large';
        break;
      case 'LIMIT_FILE_COUNT':
        message = 'Too many files';
        break;
      case 'LIMIT_UNEXPECTED_FILE':
        message = 'Unexpected file field';
        break;
      default:
        message = 'File upload error';
    }
  }
  
  // Don't expose error details in production
  const response = {
    success: false,
    error: {
      message,
      ...(process.env.NODE_ENV === 'development' && {
        details,
        stack: err.stack,
      }),
    },
  };
  
  res.status(statusCode).json(response);
};

/**
 * Async handler wrapper
 * Wraps async route handlers to catch errors and pass to error middleware
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

/**
 * Validation error handler
 * Handles express-validator validation results
 */
const { validationResult } = require('express-validator');

const handleValidation = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(err => ({
      field: err.path,
      message: err.msg,
      value: err.value,
    }));
    
    return res.status(400).json({
      success: false,
      error: {
        message: 'Validation Error',
        details: formattedErrors,
      },
    });
  }
  
  next();
};

module.exports = {
  ApiError,
  notFound,
  errorHandler,
  asyncHandler,
  handleValidation,
};
