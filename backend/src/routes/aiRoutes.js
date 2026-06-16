const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');
const { authenticate } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/errorMiddleware');
const { uploadSingle } = require('../middleware/uploadMiddleware');
const { aiValidators } = require('../utils/validators');

/**
 * @route   POST /api/v1/ai/chat
 * @desc    Send message to AI assistant
 * @access  Private
 */
router.post(
  '/chat',
  authenticate,
  aiValidators.chat,
  handleValidation,
  aiController.chat
);

/**
 * @route   POST /api/v1/ai/analyze-image
 * @desc    Analyze crop/plant image
 * @access  Private
 */
router.post(
  '/analyze-image',
  authenticate,
  uploadSingle('image'),
  aiController.analyzeImage
);

/**
 * @route   GET /api/v1/ai/sessions
 * @desc    Get user's chat sessions
 * @access  Private
 */
router.get('/sessions', authenticate, aiController.getChatSessions);

/**
 * @route   GET /api/v1/ai/sessions/:sessionId
 * @desc    Get chat session by ID
 * @access  Private
 */
router.get('/sessions/:sessionId', authenticate, aiController.getChatSession);

/**
 * @route   DELETE /api/v1/ai/sessions/:sessionId
 * @desc    Delete chat session
 * @access  Private
 */
router.delete('/sessions/:sessionId', authenticate, aiController.deleteChatSession);

/**
 * @route   POST /api/v1/ai/crop-analysis
 * @desc    Get detailed crop analysis
 * @access  Private
 */
router.post('/crop-analysis', authenticate, aiController.getCropAnalysis);

/**
 * @route   GET /api/v1/ai/farming-tips
 * @desc    Get personalized farming tips
 * @access  Private
 */
router.get('/farming-tips', authenticate, aiController.getFarmingTips);

/**
 * @route   GET /api/v1/ai/market-predictions
 * @desc    Get market predictions for crops
 * @access  Private
 */
router.get('/market-predictions', authenticate, aiController.getMarketPredictions);

/**
 * @route   GET /api/v1/ai/weather-recommendations
 * @desc    Get weather-based farming recommendations
 * @access  Private
 */
router.get('/weather-recommendations', authenticate, aiController.getWeatherRecommendations);

/**
 * @route   POST /api/v1/ai/pest-identification
 * @desc    Identify pests from image
 * @access  Private
 */
router.post(
  '/pest-identification',
  authenticate,
  uploadSingle('image'),
  aiController.identifyPest
);

/**
 * @route   POST /api/v1/ai/disease-diagnosis
 * @desc    Diagnose plant disease from image
 * @access  Private
 */
router.post(
  '/disease-diagnosis',
  authenticate,
  uploadSingle('image'),
  aiController.diagnosePlantDisease
);

/**
 * @route   GET /api/v1/ai/usage
 * @desc    Get AI usage statistics
 * @access  Private
 */
router.get('/usage', authenticate, aiController.getUsageStats);

module.exports = router;
