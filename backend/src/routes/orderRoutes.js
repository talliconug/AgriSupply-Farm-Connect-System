const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { authenticate, requireFarmer, requireAdmin } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/errorMiddleware');
const { orderValidators } = require('../utils/validators');

/**
 * @route   GET /api/v1/orders
 * @desc    Get current user's orders (buyer)
 * @access  Private
 */
router.get('/', authenticate, orderController.getMyOrders);

/**
 * @route   GET /api/v1/orders/farmer
 * @desc    Get orders for farmer's products
 * @access  Private (Farmer)
 */
router.get('/farmer', authenticate, requireFarmer, orderController.getFarmerOrders);

/**
 * @route   GET /api/v1/orders/:id
 * @desc    Get order by ID
 * @access  Private (Order Owner/Farmer/Admin)
 */
router.get(
  '/:id',
  authenticate,
  orderValidators.id,
  handleValidation,
  orderController.getOrderById
);

/**
 * @route   POST /api/v1/orders
 * @desc    Create a new order
 * @access  Private
 */
router.post(
  '/',
  authenticate,
  orderValidators.create,
  handleValidation,
  orderController.createOrder
);

/**
 * @route   PUT /api/v1/orders/:id/status
 * @desc    Update order status
 * @access  Private (Farmer/Admin)
 */
router.put(
  '/:id/status',
  authenticate,
  orderValidators.id,
  orderValidators.updateStatus,
  handleValidation,
  orderController.updateOrderStatus
);

/**
 * @route   POST /api/v1/orders/:id/confirm
 * @desc    Confirm order (Farmer)
 * @access  Private (Farmer)
 */
router.post(
  '/:id/confirm',
  authenticate,
  requireFarmer,
  orderValidators.id,
  handleValidation,
  orderController.confirmOrder
);

/**
 * @route   POST /api/v1/orders/:id/ship
 * @desc    Mark order as shipped (Farmer)
 * @access  Private (Farmer)
 */
router.post(
  '/:id/ship',
  authenticate,
  requireFarmer,
  orderValidators.id,
  handleValidation,
  orderController.shipOrder
);

/**
 * @route   POST /api/v1/orders/:id/deliver
 * @desc    Mark order as delivered
 * @access  Private (Farmer/Admin)
 */
router.post(
  '/:id/deliver',
  authenticate,
  orderValidators.id,
  handleValidation,
  orderController.deliverOrder
);

/**
 * @route   POST /api/v1/orders/:id/cancel
 * @desc    Cancel order
 * @access  Private (Order Owner/Farmer/Admin)
 */
router.post(
  '/:id/cancel',
  authenticate,
  orderValidators.id,
  handleValidation,
  orderController.cancelOrder
);

/**
 * @route   POST /api/v1/orders/:id/refund
 * @desc    Request refund for order
 * @access  Private (Order Owner)
 */
router.post(
  '/:id/refund',
  authenticate,
  orderValidators.id,
  handleValidation,
  orderController.requestRefund
);

/**
 * @route   GET /api/v1/orders/:id/tracking
 * @desc    Get order tracking information
 * @access  Private (Order Owner/Farmer/Admin)
 */
router.get(
  '/:id/tracking',
  authenticate,
  orderValidators.id,
  handleValidation,
  orderController.getOrderTracking
);

/**
 * @route   GET /api/v1/orders/:id/history
 * @desc    Get order status history
 * @access  Private (Order Owner/Farmer/Admin)
 */
router.get(
  '/:id/history',
  authenticate,
  orderValidators.id,
  handleValidation,
  orderController.getOrderHistory
);

/**
 * @route   GET /api/v1/orders/statistics/summary
 * @desc    Get order statistics summary
 * @access  Private
 */
router.get('/statistics/summary', authenticate, orderController.getOrderStatistics);

module.exports = router;
