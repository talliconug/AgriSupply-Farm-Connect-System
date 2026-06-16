const winston = require('winston');
const path = require('path');

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ timestamp, level, message, stack }) => {
    return `${timestamp} [${level.toUpperCase()}]: ${stack || message}`;
  })
);

// Define log format for console (with colors)
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(({ timestamp, level, message }) => {
    return `${timestamp} ${level}: ${message}`;
  })
);

// Create transports array
const transports = [
  // Console transport
  new winston.transports.Console({
    format: consoleFormat,
    level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  }),
];

// Add file transports in production
if (process.env.NODE_ENV === 'production') {
  // Error log
  transports.push(
    new winston.transports.File({
      filename: path.join('logs', 'error.log'),
      level: 'error',
      format: logFormat,
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    })
  );

  // Combined log
  transports.push(
    new winston.transports.File({
      filename: path.join('logs', 'combined.log'),
      format: logFormat,
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    })
  );
}

// Create logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  transports,
  exitOnError: false,
});

// Add request logging helper
logger.logRequest = (req, message = '') => {
  const info = {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userId: req.user?.id,
  };
  logger.info(`${message} ${JSON.stringify(info)}`);
};

// Add error logging helper
logger.logError = (error, req = null) => {
  const errorInfo = {
    message: error.message,
    stack: error.stack,
    code: error.code,
  };
  
  if (req) {
    errorInfo.method = req.method;
    errorInfo.url = req.originalUrl;
    errorInfo.userId = req.user?.id;
  }
  
  logger.error(JSON.stringify(errorInfo));
};

module.exports = logger;
