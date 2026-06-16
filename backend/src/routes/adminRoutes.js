const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticate, requireAdmin } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/errorMiddleware');
const { adminValidators } = require('../utils/validators');

// All routes require admin authentication
router.use(authenticate, requireAdmin);

/**
 * @route   GET /api/v1/admin/dashboard
 * @desc    Get admin dashboard statistics
 * @access  Private (Admin)
 */
router.get('/dashboard', adminController.getDashboard);

/**
 * @route   GET /api/v1/admin/users
 * @desc    Get all users with filters
 * @access  Private (Admin)
 */
router.get(
  '/users',
  adminValidators.userList,
  handleValidation,
  adminController.getUsers
);

/**
 * @route   GET /api/v1/admin/users/:id
 * @desc    Get user by ID
 * @access  Private (Admin)
 */
router.get('/users/:id', adminController.getUserById);

/**
 * @route   PUT /api/v1/admin/users/:id
 * @desc    Update user (role, verification, suspension)
 * @access  Private (Admin)
 */
router.put(
  '/users/:id',
  adminValidators.updateUser,
  handleValidation,
  adminController.updateUser
);

/**
 * @route   POST /api/v1/admin/users/:id/verify
 * @desc    Verify user account
 * @access  Private (Admin)
 */
router.post('/users/:id/verify', adminController.verifyUser);

/**
 * @route   POST /api/v1/admin/users/:id/suspend
 * @desc    Suspend user account
 * @access  Private (Admin)
 */
router.post('/users/:id/suspend', adminController.suspendUser);

/**
 * @route   POST /api/v1/admin/users/:id/unsuspend
 * @desc    Unsuspend user account
 * @access  Private (Admin)
 */
router.post('/users/:id/unsuspend', adminController.unsuspendUser);

/**
 * @route   DELETE /api/v1/admin/users/:id
 * @desc    Delete user account
 * @access  Private (Admin)
 */
router.delete('/users/:id', adminController.deleteUser);

/**
 * @route   GET /api/v1/admin/products
 * @desc    Get all products with filters
 * @access  Private (Admin)
 */
router.get('/products', adminController.getProducts);

/**
 * @route   PUT /api/v1/admin/products/:id
 * @desc    Update product (approve, feature, etc.)
 * @access  Private (Admin)
 */
router.put('/products/:id', adminController.updateProduct);

/**
 * @route   DELETE /api/v1/admin/products/:id
 * @desc    Delete product
 * @access  Private (Admin)
 */
router.delete('/products/:id', adminController.deleteProduct);

/**
 * @route   GET /api/v1/admin/orders
 * @desc    Get all orders with filters
 * @access  Private (Admin)
 */
router.get('/orders', adminController.getOrders);

/**
 * @route   PUT /api/v1/admin/orders/:id
 * @desc    Update order status
 * @access  Private (Admin)
 */
router.put('/orders/:id', adminController.updateOrder);

/**
 * @route   GET /api/v1/admin/payments
 * @desc    Get all payments with filters
 * @access  Private (Admin)
 */
router.get('/payments', adminController.getPayments);

/**
 * @route   POST /api/v1/admin/payments/:id/refund
 * @desc    Process refund for payment
 * @access  Private (Admin)
 */
router.post('/payments/:id/refund', adminController.processRefund);

/**
 * @route   GET /api/v1/admin/analytics/sales
 * @desc    Get sales analytics
 * @access  Private (Admin)
 */
router.get('/analytics/sales', adminController.getSalesAnalytics);

/**
 * @route   GET /api/v1/admin/analytics/users
 * @desc    Get user analytics
 * @access  Private (Admin)
 */
router.get('/analytics/users', adminController.getUserAnalytics);

/**
 * @route   GET /api/v1/admin/analytics/products
 * @desc    Get product analytics
 * @access  Private (Admin)
 */
router.get('/analytics/products', adminController.getProductAnalytics);

/**
 * @route   GET /api/v1/admin/analytics/regions
 * @desc    Get regional analytics
 * @access  Private (Admin)
 */
router.get('/analytics/regions', adminController.getRegionalAnalytics);

/**
 * @route   POST /api/v1/admin/notifications/broadcast
 * @desc    Send broadcast notification to all users
 * @access  Private (Admin)
 */
router.post('/notifications/broadcast', adminController.sendBroadcastNotification);

/**
 * @route   GET /api/v1/admin/reports/export
 * @desc    Export reports
 * @access  Private (Admin)
 */
router.get('/reports/export', adminController.exportReports);

/**
 * @route   GET /api/v1/admin/settings
 * @desc    Get admin settings
 * @access  Private (Admin)
 */
router.get('/settings', adminController.getSettings);

/**
 * @route   PUT /api/v1/admin/settings
 * @desc    Update admin settings
 * @access  Private (Admin)
 */
router.put('/settings', adminController.updateSettings);

module.exports = router;
