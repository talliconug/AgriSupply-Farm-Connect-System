require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const { errorHandler, notFound } = require('./middleware/errorMiddleware');
const logger = require('./utils/logger');

// Import routes
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const productRoutes = require('./routes/productRoutes');
const orderRoutes = require('./routes/orderRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const aiRoutes = require('./routes/aiRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();

// Trust proxy for rate limiting behind reverse proxy
app.set('trust proxy', 1);

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    success: false,
    error: 'Too many requests, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Compression
app.use(compression());

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined', {
    stream: {
      write: (message) => logger.info(message.trim()),
    },
  }));
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'AgriSupply API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
    version: process.env.API_VERSION || 'v1',
  });
});

// API routes
const apiVersion = process.env.API_VERSION || 'v1';
app.use(`/api/${apiVersion}/auth`, authRoutes);
app.use(`/api/${apiVersion}/users`, userRoutes);
app.use(`/api/${apiVersion}/products`, productRoutes);
app.use(`/api/${apiVersion}/orders`, orderRoutes);
app.use(`/api/${apiVersion}/payments`, paymentRoutes);
app.use(`/api/${apiVersion}/notifications`, notificationRoutes);
app.use(`/api/${apiVersion}/ai`, aiRoutes);
app.use(`/api/${apiVersion}/admin`, adminRoutes);

// Welcome route
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to AgriSupply Farm Connect API',
    version: apiVersion,
    documentation: `/api/${apiVersion}/docs`,
    endpoints: {
      auth: `/api/${apiVersion}/auth`,
      users: `/api/${apiVersion}/users`,
      products: `/api/${apiVersion}/products`,
      orders: `/api/${apiVersion}/orders`,
      payments: `/api/${apiVersion}/payments`,
      notifications: `/api/${apiVersion}/notifications`,
      ai: `/api/${apiVersion}/ai`,
      admin: `/api/${apiVersion}/admin`,
    },
  });
});

// 404 handler
app.use(notFound);

// Error handler
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  logger.info(`🚀 AgriSupply API server running on port ${PORT}`);
  logger.info(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`📌 API Version: ${apiVersion}`);
});

// Graceful shutdown
const gracefulShutdown = (signal) => {
  logger.info(`${signal} received. Shutting down gracefully...`);
  server.close(() => {
    logger.info('Server closed. Process terminated.');
    process.exit(0);
  });
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

module.exports = app;
