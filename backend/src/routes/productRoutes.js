const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { authenticate, optionalAuth, requireFarmer } = require('../middleware/authMiddleware');
const { handleValidation } = require('../middleware/errorMiddleware');
const { uploadMultiple } = require('../middleware/uploadMiddleware');
const { optionalUploadMultiple } = require('../middleware/optionalUploadMiddleware');
const { productValidators } = require('../utils/validators');

/**
 * @route   GET /api/v1/products
 * @desc    Get all products with filters
 * @access  Public
 */
router.get(
  '/',
  productValidators.list,
  handleValidation,
  optionalAuth,
  productController.getProducts
);

/**
 * @route   GET /api/v1/products/search
 * @desc    Search products
 * @access  Public
 */
router.get('/search', optionalAuth, productController.searchProducts);

/**
 * @route   GET /api/v1/products/featured
 * @desc    Get featured products
 * @access  Public
 */
router.get('/featured', optionalAuth, productController.getFeaturedProducts);

/**
 * @route   GET /api/v1/products/categories
 * @desc    Get product categories with counts
 * @access  Public
 */
router.get('/categories', productController.getCategories);

/**
 * @route   GET /api/v1/products/my-products
 * @desc    Get current farmer's products
 * @access  Private (Farmer)
 */
router.get('/my-products', authenticate, requireFarmer, productController.getMyProducts);

/**
 * @route   GET /api/v1/products/:id
 * @desc    Get product by ID
 * @access  Public
 */
router.get(
  '/:id',
  productValidators.id,
  handleValidation,
  optionalAuth,
  productController.getProductById
);

/**
 * @route   POST /api/v1/products
 * @desc    Create a new product
 * @access  Private (Farmer)
 */
router.post(
  '/',
  authenticate,
  requireFarmer,
  optionalUploadMultiple('images', 5), // Now accepts both JSON and multipart
  productValidators.create,
  handleValidation,
  productController.createProduct
);

/**
 * @route   PUT /api/v1/products/:id
 * @desc    Update product
 * @access  Private (Farmer - Owner)
 */
router.put(
  '/:id',
  authenticate,
  requireFarmer,
  productValidators.id,
  productValidators.update,
  handleValidation,
  productController.updateProduct
);

/**
 * @route   POST /api/v1/products/:id/images
 * @desc    Add images to product
 * @access  Private (Farmer - Owner)
 */
router.post(
  '/:id/images',
  authenticate,
  requireFarmer,
  productValidators.id,
  handleValidation,
  uploadMultiple('images', 5),
  productController.addImages
);

/**
 * @route   DELETE /api/v1/products/:id/images/:imageIndex
 * @desc    Delete product image
 * @access  Private (Farmer - Owner)
 */
router.delete(
  '/:id/images/:imageIndex',
  authenticate,
  requireFarmer,
  productController.deleteImage
);

/**
 * @route   DELETE /api/v1/products/:id
 * @desc    Delete product
 * @access  Private (Farmer - Owner)
 */
router.delete(
  '/:id',
  authenticate,
  requireFarmer,
  productValidators.id,
  handleValidation,
  productController.deleteProduct
);

/**
 * @route   GET /api/v1/products/:id/reviews
 * @desc    Get product reviews
 * @access  Public
 */
router.get(
  '/:id/reviews',
  productValidators.id,
  handleValidation,
  productController.getProductReviews
);

/**
 * @route   POST /api/v1/products/:id/reviews
 * @desc    Add product review
 * @access  Private
 */
router.post(
  '/:id/reviews',
  authenticate,
  productValidators.id,
  productValidators.review,
  handleValidation,
  productController.addReview
);

/**
 * @route   PUT /api/v1/products/:id/reviews/:reviewId
 * @desc    Update product review
 * @access  Private (Review Owner)
 */
router.put(
  '/:id/reviews/:reviewId',
  authenticate,
  productValidators.review,
  handleValidation,
  productController.updateReview
);

/**
 * @route   DELETE /api/v1/products/:id/reviews/:reviewId
 * @desc    Delete product review
 * @access  Private (Review Owner)
 */
router.delete(
  '/:id/reviews/:reviewId',
  authenticate,
  productController.deleteReview
);

/**
 * @route   POST /api/v1/products/:id/favorite
 * @desc    Add product to favorites
 * @access  Private
 */
router.post(
  '/:id/favorite',
  authenticate,
  productValidators.id,
  handleValidation,
  productController.addToFavorites
);

/**
 * @route   DELETE /api/v1/products/:id/favorite
 * @desc    Remove product from favorites
 * @access  Private
 */
router.delete(
  '/:id/favorite',
  authenticate,
  productValidators.id,
  handleValidation,
  productController.removeFromFavorites
);

/**
 * @route   GET /api/v1/products/favorites
 * @desc    Get user's favorite products
 * @access  Private
 */
router.get('/favorites/list', authenticate, productController.getFavorites);

module.exports = router;
