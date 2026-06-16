const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate, optionalAuth } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/errorMiddleware');
const { uploadSingle } = require('../middleware/uploadMiddleware');
const { userValidators } = require('../utils/validators');

/**
 * @route   GET /api/v1/users/profile
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/profile', authenticate, userController.getProfile);

/**
 * @route   PUT /api/v1/users/profile
 * @desc    Update current user profile
 * @access  Private
 */
router.put(
  '/profile',
  authenticate,
  userValidators.updateProfile,
  handleValidation,
  userController.updateProfile
);

/**
 * @route   POST /api/v1/users/profile/photo
 * @desc    Upload profile photo
 * @access  Private
 */
router.post(
  '/profile/photo',
  authenticate,
  uploadSingle('photo'),
  userController.uploadPhoto
);

/**
 * @route   DELETE /api/v1/users/profile/photo
 * @desc    Delete profile photo
 * @access  Private
 */
router.delete('/profile/photo', authenticate, userController.deletePhoto);

/**
 * @route   PUT /api/v1/users/address
 * @desc    Update user address
 * @access  Private
 */
router.put(
  '/address',
  authenticate,
  userValidators.updateAddress,
  handleValidation,
  userController.updateAddress
);

/**
 * @route   GET /api/v1/users/farmers
 * @desc    Get list of farmers
 * @access  Public
 */
router.get('/farmers', optionalAuth, userController.getFarmers);

/**
 * @route   GET /api/v1/users/farmers/:id
 * @desc    Get farmer profile by ID
 * @access  Public
 */
router.get('/farmers/:id', optionalAuth, userController.getFarmerProfile);

/** * @route   GET /api/v1/users/farmers/:id/analytics
 * @desc    Get farmer analytics
 * @access  Private
 */
router.get('/farmers/:id/analytics', authenticate, userController.getFarmerAnalytics);

/** * @route   GET /api/v1/users/farmers/:id/analytics
 * @desc    Get farmer analytics
 * @access  Private
 */
router.get('/farmers/:id/analytics', authenticate, userController.getFarmerAnalytics);

/**
 * @route   POST /api/v1/users/farmers/:id/follow
 * @desc    Follow a farmer
 * @access  Private
 */
router.post('/farmers/:id/follow', authenticate, userController.followFarmer);

/**
 * @route   DELETE /api/v1/users/farmers/:id/follow
 * @desc    Unfollow a farmer
 * @access  Private
 */
router.delete('/farmers/:id/follow', authenticate, userController.unfollowFarmer);

/**
 * @route   GET /api/v1/users/following
 * @desc    Get list of followed farmers
 * @access  Private
 */
router.get('/following', authenticate, userController.getFollowing);

/**
 * @route   GET /api/v1/users/followers
 * @desc    Get list of followers (for farmers)
 * @access  Private
 */
router.get('/followers', authenticate, userController.getFollowers);

/**
 * @route   GET /api/v1/users/statistics
 * @desc    Get user statistics
 * @access  Private
 */
router.get('/statistics', authenticate, userController.getStatistics);

module.exports = router;
