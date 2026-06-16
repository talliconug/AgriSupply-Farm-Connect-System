const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authenticate } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/errorMiddleware');
const { notificationValidators } = require('../utils/validators');

/**
 * @route   GET /api/v1/notifications
 * @desc    Get all notifications for current user
 * @access  Private
 */
router.get('/', authenticate, notificationController.getNotifications);

/**
 * @route   GET /api/v1/notifications/unread-count
 * @desc    Get unread notification count
 * @access  Private
 */
router.get('/unread-count', authenticate, notificationController.getUnreadCount);

/**
 * @route   GET /api/v1/notifications/:id
 * @desc    Get notification by ID
 * @access  Private
 */
router.get(
  '/:id',
  authenticate,
  notificationValidators.id,
  handleValidation,
  notificationController.getNotificationById
);

/**
 * @route   PUT /api/v1/notifications/:id/read
 * @desc    Mark notification as read
 * @access  Private
 */
router.put(
  '/:id/read',
  authenticate,
  notificationValidators.id,
  handleValidation,
  notificationController.markAsRead
);

/**
 * @route   PUT /api/v1/notifications/read-all
 * @desc    Mark all notifications as read
 * @access  Private
 */
router.put('/read-all', authenticate, notificationController.markAllAsRead);

/**
 * @route   DELETE /api/v1/notifications/:id
 * @desc    Delete notification
 * @access  Private
 */
router.delete(
  '/:id',
  authenticate,
  notificationValidators.id,
  handleValidation,
  notificationController.deleteNotification
);

/**
 * @route   DELETE /api/v1/notifications
 * @desc    Delete all notifications
 * @access  Private
 */
router.delete('/', authenticate, notificationController.deleteAllNotifications);

/**
 * @route   GET /api/v1/notifications/preferences
 * @desc    Get notification preferences
 * @access  Private
 */
router.get('/preferences', authenticate, notificationController.getPreferences);

/**
 * @route   PUT /api/v1/notifications/preferences
 * @desc    Update notification preferences
 * @access  Private
 */
router.put(
  '/preferences',
  authenticate,
  notificationValidators.updatePreferences,
  handleValidation,
  notificationController.updatePreferences
);

/**
 * @route   POST /api/v1/notifications/register-device
 * @desc    Register device for push notifications
 * @access  Private
 */
router.post('/register-device', authenticate, notificationController.registerDevice);

/**
 * @route   DELETE /api/v1/notifications/unregister-device
 * @desc    Unregister device from push notifications
 * @access  Private
 */
router.delete('/unregister-device', authenticate, notificationController.unregisterDevice);

module.exports = router;
