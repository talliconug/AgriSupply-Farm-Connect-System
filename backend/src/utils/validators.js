const { body, param, query } = require('express-validator');
const constants = require('../config/constants');

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const UG_PHONE_REGEX = /^\+256\d{9}$/;
const STRONG_PASSWORD_MIN = 8;

const legacyCategories = new Set([
  'fruits_vegetables',
  'grains_cereals',
  'dairy_eggs',
  'meat_poultry',
  'fish_seafood',
  'herbs_spices',
  'beverages',
  'processed_foods',
  'seeds_seedlings',
  'farm_equipment',
]);

const validPaymentMethods = new Set([
  'mtn_mobile_money',
  'airtel_money',
  'card',
  'cash_on_delivery',
  'mtn_mobile',
  'marzpay',
]);

const escapeMap = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
};

const passwordRule = bodyField => body(bodyField)
  .isLength({ min: 4 })
  .withMessage('Password must be at least 4 characters')
  .matches(/[A-Za-z0-9]/)
  .withMessage('Password must include at least one letter or number');

// Auth validators
const authValidators = {
  register: [
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Please provide a valid email'),
    passwordRule('password'),
    body('fullName')
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Full name must be between 2 and 100 characters'),
    body('role')
      .optional()
      .isIn(constants.userRoles)
      .withMessage('Invalid role'),
    body('phone')
      .optional()
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
  ],
  
  login: [
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Please provide a valid email'),
    body('password')
      .notEmpty()
      .withMessage('Password is required'),
  ],
  
  phoneOtp: [
    body('phone')
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
  ],
  
  verifyOtp: [
    body('phone')
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
    body('otp')
      .isLength({ min: 6, max: 6 })
      .isNumeric()
      .withMessage('OTP must be 6 digits'),
  ],
  
  resetPassword: [
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Please provide a valid email'),
  ],

  passwordResetSendOtp: [
    body('phone')
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
  ],

  passwordResetVerifyOtp: [
    body('phone')
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
    body('otp')
      .isLength({ min: 6, max: 6 })
      .isNumeric()
      .withMessage('OTP must be 6 digits'),
  ],

  passwordResetConfirm: [
    body('phone')
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
    body('resetToken')
      .isString()
      .isLength({ min: 16 })
      .withMessage('A valid reset token is required'),
    passwordRule('newPassword'),
  ],
  
  updatePassword: [
    body('currentPassword')
      .notEmpty()
      .withMessage('Current password is required'),
    passwordRule('newPassword'),
  ],
};

// User validators
const userValidators = {
  updateProfile: [
    body('fullName')
      .optional()
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Full name must be between 2 and 100 characters'),
    body('phone')
      .optional()
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
    body('region')
      .optional()
      .isIn(constants.uganda.regions)
      .withMessage('Invalid region'),
    body('bio')
      .optional()
      .isLength({ max: 500 })
      .withMessage('Bio must be less than 500 characters'),
  ],
  
  updateAddress: [
    body('region')
      .isIn(constants.uganda.regions)
      .withMessage('Invalid region'),
    body('district')
      .notEmpty()
      .withMessage('District is required'),
    body('address')
      .notEmpty()
      .isLength({ min: 5, max: 200 })
      .withMessage('Address must be between 5 and 200 characters'),
  ],
};

// Product validators
const productValidators = {
  create: [
    body('name')
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Product name must be between 2 and 100 characters'),
    body('description')
      .optional()
      .isLength({ max: 2000 })
      .withMessage('Description must be less than 2000 characters'),
    body('category')
      .isIn(constants.productCategories.map(c => c.id))
      .withMessage('Invalid category'),
    body('price')
      .custom((value) => {
        const num = parseFloat(value);
        return !isNaN(num) && num >= 0;
      })
      .withMessage('Price must be a positive number'),
    body('unit')
      .isIn(['kg', 'g', 'piece', 'bunch', 'liter', 'dozen', 'bag', 'crate'])
      .withMessage('Invalid unit'),
    body('quantity')
      .custom((value) => {
        const num = parseInt(value);
        return !isNaN(num) && num >= 0;
      })
      .withMessage('Quantity must be a non-negative integer'),
    body('isOrganic')
      .optional()
      .custom((value) => {
        return value === 'true' || value === 'false' || typeof value === 'boolean';
      })
      .withMessage('isOrganic must be a boolean or string "true"/"false"'),
  ],
  
  update: [
    body('name')
      .optional()
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage('Product name must be between 2 and 100 characters'),
    body('description')
      .optional()
      .isLength({ max: 2000 })
      .withMessage('Description must be less than 2000 characters'),
    body('category')
      .optional()
      .isIn(constants.productCategories.map(c => c.id))
      .withMessage('Invalid category'),
    body('price')
      .optional()
      .custom((value) => {
        const num = parseFloat(value);
        return !isNaN(num) && num >= 0;
      })
      .withMessage('Price must be a positive number'),
    body('quantity')
      .optional()
      .custom((value) => {
        const num = parseInt(value);
        return !isNaN(num) && num >= 0;
      })
      .withMessage('Quantity must be a non-negative integer'),
  ],
  
  id: [
    param('id')
      .isUUID()
      .withMessage('Invalid product ID'),
  ],
  
  list: [
    query('page')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Page must be a positive integer'),
    query('limit')
      .optional()
      .isInt({ min: 1, max: 100 })
      .withMessage('Limit must be between 1 and 100'),
    query('category')
      .optional()
      .isIn(constants.productCategories.map(c => c.id))
      .withMessage('Invalid category'),
    query('region')
      .optional()
      .isIn(constants.uganda.regions)
      .withMessage('Invalid region'),
    query('minPrice')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Minimum price must be a positive number'),
    query('min_price')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Minimum price must be a positive number'),
    query('maxPrice')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Maximum price must be a positive number'),
    query('max_price')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Maximum price must be a positive number'),
    query('isOrganic')
      .optional()
      .isIn(['true', 'false'])
      .withMessage('isOrganic must be true or false'),
    query('organic')
      .optional()
      .isIn(['true', 'false'])
      .withMessage('organic must be true or false'),
    query('sortBy')
      .optional()
      .isIn(['created_at', 'price', 'rating', 'name', 'newest', 'price_low', 'price_high', 'relevance'])
      .withMessage('Invalid sortBy value'),
    query('sort')
      .optional()
      .isIn(['created_at', 'price', 'rating', 'name', 'newest', 'price_low', 'price_high', 'relevance'])
      .withMessage('Invalid sort value'),
    query('sortOrder')
      .optional()
      .isIn(['asc', 'desc'])
      .withMessage('sortOrder must be asc or desc'),
  ],
  
  review: [
    body('rating')
      .isInt({ min: 1, max: 5 })
      .withMessage('Rating must be between 1 and 5'),
    body('comment')
      .optional()
      .isLength({ max: 1000 })
      .withMessage('Comment must be less than 1000 characters'),
  ],
};

// Order validators
const orderValidators = {
  create: [
    body('items')
      .isArray({ min: 1 })
      .withMessage('Order must have at least one item'),
    body('items.*.productId')
      .isUUID()
      .withMessage('Invalid product ID'),
    body('items.*.quantity')
      .isInt({ min: 1 })
      .withMessage('Quantity must be at least 1'),
    // Accept both mobile (deliveryAddress string) and web (shippingAddress object) formats
    body()
      .custom((value) => {
        if (!value.deliveryAddress && !value.shippingAddress) {
          throw new Error('Either deliveryAddress or shippingAddress is required');
        }
        return true;
      }),
    body('deliveryAddress')
      .optional()
      .isString()
      .isLength({ min: 5 })
      .withMessage('Delivery address must be at least 5 characters'),
    body('shippingAddress.region')
      .optional()
      .isIn(constants.uganda.regions)
      .withMessage('Invalid region'),
    body('shippingAddress.district')
      .optional()
      .isString()
      .withMessage('District must be a string'),
    body('shippingAddress.address')
      .optional()
      .isLength({ min: 5, max: 200 })
      .withMessage('Address must be between 5 and 200 characters'),
    body('paymentMethod')
      .isIn(['mtn_mobile', 'airtel_money', 'card', 'cash_on_delivery', 'marzpay'])
      .withMessage('Invalid payment method'),
  ],
  
  updateStatus: [
    body('status')
      .isIn(constants.orderStatuses)
      .withMessage('Invalid order status'),
    body('note')
      .optional()
      .isLength({ max: 500 })
      .withMessage('Note must be less than 500 characters'),
  ],
  
  id: [
    param('id')
      .isUUID()
      .withMessage('Invalid order ID'),
  ],
};

// Payment validators
const paymentValidators = {
  initiate: [
    body('orderId')
      .isUUID()
      .withMessage('Invalid order ID'),
    body('method')
      .isIn(['mtn_mobile', 'airtel_money', 'card', 'cash_on_delivery', 'marzpay'])
      .withMessage('Invalid payment method'),
    body('phone')
      .optional()
      .matches(/^(\+256|0)?[7][0-9]{8}$/)
      .withMessage('Please provide a valid Ugandan phone number'),
  ],
  
  callback: [
    body('transactionId')
      .notEmpty()
      .withMessage('Transaction ID is required'),
    body('status')
      .isIn(['success', 'failed', 'pending'])
      .withMessage('Invalid status'),
  ],
};

// Notification validators
const notificationValidators = {
  id: [
    param('id')
      .isUUID()
      .withMessage('Invalid notification ID'),
  ],
  
  updatePreferences: [
    body('orderUpdates')
      .optional()
      .isBoolean()
      .withMessage('orderUpdates must be a boolean'),
    body('promotions')
      .optional()
      .isBoolean()
      .withMessage('promotions must be a boolean'),
    body('farmingTips')
      .optional()
      .isBoolean()
      .withMessage('farmingTips must be a boolean'),
    body('priceAlerts')
      .optional()
      .isBoolean()
      .withMessage('priceAlerts must be a boolean'),
  ],
};

// AI validators
const aiValidators = {
  chat: [
    body('message')
      .trim()
      .isLength({ min: 1, max: 2000 })
      .withMessage('Message must be between 1 and 2000 characters'),
    body('sessionId')
      .optional()
      .isUUID()
      .withMessage('Invalid session ID'),
  ],
  
  analyzeImage: [
    body('imageUrl')
      .isURL()
      .withMessage('Please provide a valid image URL'),
    body('question')
      .optional()
      .isLength({ max: 500 })
      .withMessage('Question must be less than 500 characters'),
  ],
};

// Admin validators
const adminValidators = {
  updateUser: [
    param('id')
      .isUUID()
      .withMessage('Invalid user ID'),
    body('role')
      .optional()
      .isIn(constants.userRoles)
      .withMessage('Invalid role'),
    body('isVerified')
      .optional()
      .isBoolean()
      .withMessage('isVerified must be a boolean'),
    body('isSuspended')
      .optional()
      .isBoolean()
      .withMessage('isSuspended must be a boolean'),
  ],
  
  userList: [
    query('role')
      .optional()
      .isIn(constants.userRoles)
      .withMessage('Invalid role'),
    query('region')
      .optional()
      .isIn(constants.uganda.regions)
      .withMessage('Invalid region'),
    query('isVerified')
      .optional()
      .isBoolean()
      .withMessage('isVerified must be a boolean'),
  ],
};

// Backward-compatible utility validators used by unit tests.
const validateEmail = (email) => typeof email === 'string' && EMAIL_REGEX.test(email.trim());

const validatePhone = (phone) => typeof phone === 'string' && UG_PHONE_REGEX.test(phone.trim());

const validateUgandanPhone = validatePhone;

const validatePassword = (password, options = {}) => {
  const errors = [];

  if (typeof password !== 'string') {
    errors.push('Password is required');
  } else {
    if (password.length < STRONG_PASSWORD_MIN) {
      errors.push('Password must be at least 8 characters');
    }
    if (!/[a-z]/.test(password)) {
      errors.push('Password must include at least one lowercase letter');
    }
    if (!/[A-Z]/.test(password)) {
      errors.push('Password must include at least one uppercase letter');
    }
    if (!/\d/.test(password)) {
      errors.push('Password must include at least one number');
    }
  }

  const isValid = errors.length === 0;
  if (options.returnDetails) {
    return { isValid, errors };
  }
  return isValid;
};

const validatePrice = (price) => Number.isFinite(Number(price)) && Number(price) > 0;

const validateQuantity = (quantity) => Number.isInteger(Number(quantity)) && Number(quantity) > 0;

const sanitizeInput = (input) => {
  if (input == null) {
    return '';
  }

  return String(input)
    .trim()
    .replace(/[&<>"']/g, char => escapeMap[char]);
};

const validateOrderStatus = (status) =>
  typeof status === 'string' && constants.orderStatuses.includes(status);

const validatePaymentMethod = (method) =>
  typeof method === 'string' && validPaymentMethods.has(method);

const validateCategory = (category) => {
  if (typeof category !== 'string') {
    return false;
  }

  return (
    constants.productCategories.some(c => c.id === category)
    || legacyCategories.has(category)
  );
};

const validateRegion = (region) =>
  typeof region === 'string' && constants.uganda.regions.includes(region);

module.exports = {
  validateEmail,
  validatePhone,
  validatePassword,
  validateUgandanPhone,
  validatePrice,
  validateQuantity,
  sanitizeInput,
  validateOrderStatus,
  validatePaymentMethod,
  validateCategory,
  validateRegion,
  authValidators,
  userValidators,
  productValidators,
  orderValidators,
  paymentValidators,
  notificationValidators,
  aiValidators,
  adminValidators,
};
