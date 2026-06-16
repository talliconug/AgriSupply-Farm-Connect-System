const constants = require('../config/constants');

/**
 * Format Ugandan phone number
 * @param {string} phone - Phone number
 * @returns {string} Formatted phone number
 */
const formatPhoneNumber = (phone) => {
  if (!phone) return null;
  
  // Remove all non-digit characters
  let cleaned = phone.replace(/\D/g, '');
  
  // Handle different formats
  if (cleaned.startsWith('256')) {
    cleaned = cleaned.substring(3);
  } else if (cleaned.startsWith('0')) {
    cleaned = cleaned.substring(1);
  }
  
  // Validate length
  if (cleaned.length !== 9) {
    return null;
  }
  
  return `+256${cleaned}`;
};

/**
 * Validate Ugandan phone number
 * @param {string} phone - Phone number
 * @returns {boolean} True if valid
 */
const isValidPhoneNumber = (phone) => {
  const formatted = formatPhoneNumber(phone);
  if (!formatted) return false;
  
  const prefix = formatted.substring(4, 6);
  const allPrefixes = [
    ...constants.uganda.mobileMoneyPrefixes.mtn,
    ...constants.uganda.mobileMoneyPrefixes.airtel,
  ];
  
  return allPrefixes.includes(prefix);
};

/**
 * Get mobile money provider from phone number
 * @param {string} phone - Phone number
 * @returns {string|null} Provider name or null
 */
const getMobileMoneyProvider = (phone) => {
  const formatted = formatPhoneNumber(phone);
  if (!formatted) return null;
  
  const prefix = formatted.substring(4, 6);
  
  if (constants.uganda.mobileMoneyPrefixes.mtn.includes(prefix)) {
    return 'mtn';
  }
  if (constants.uganda.mobileMoneyPrefixes.airtel.includes(prefix)) {
    return 'airtel';
  }
  
  return null;
};

/**
 * Format currency (UGX)
 * @param {number} amount - Amount in UGX
 * @returns {string} Formatted amount
 */
const formatCurrency = (amount) => {
  return new Intl.NumberFormat('en-UG', {
    style: 'currency',
    currency: 'UGX',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
};

/**
 * Parse currency string to number
 * @param {string} currencyString - Currency string
 * @returns {number} Amount
 */
const parseCurrency = (currencyString) => {
  if (typeof currencyString === 'number') return currencyString;
  return parseInt(currencyString.replace(/[^0-9]/g, ''), 10) || 0;
};

/**
 * Validate Uganda region
 * @param {string} region - Region name
 * @returns {boolean} True if valid
 */
const isValidRegion = (region) => {
  return constants.uganda.regions.includes(region);
};

/**
 * Validate Uganda district
 * @param {string} district - District name
 * @param {string} region - Region name
 * @returns {boolean} True if valid
 */
const isValidDistrict = (district, region) => {
  if (!region || !constants.uganda.districts[region]) {
    return false;
  }
  return constants.uganda.districts[region].includes(district);
};

/**
 * Get districts by region
 * @param {string} region - Region name
 * @returns {Array} Districts
 */
const getDistrictsByRegion = (region) => {
  return constants.uganda.districts[region] || [];
};

/**
 * Generate order number
 * @returns {string} Order number
 */
const generateOrderNumber = () => {
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = Math.random().toString(36).substring(2, 6).toUpperCase();
  return `AS-${timestamp}-${random}`;
};

/**
 * Generate tracking number
 * @returns {string} Tracking number
 */
const generateTrackingNumber = () => {
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const random = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `TRK${date}${random}`;
};

/**
 * Calculate delivery fee based on region
 * @param {string} fromRegion - Seller's region
 * @param {string} toRegion - Buyer's region
 * @returns {number} Delivery fee in UGX
 */
const calculateDeliveryFee = (fromRegion, toRegion) => {
  const safeFromRegion = fromRegion || toRegion || 'Central';
  const safeToRegion = toRegion || fromRegion || 'Central';
  if (safeFromRegion === safeToRegion) {
    return 500; // Same region
  }
  
  // Different regions
  const regionFees = {
    'Central-Eastern': 1000,
    'Central-Northern': 1500,
    'Central-Western': 1000,
    'Eastern-Northern': 1500,
    'Eastern-Western': 1000,
    'Northern-Western': 1500,
  };

  const key = [safeFromRegion, safeToRegion].sort().join('-');
  return regionFees[key] || 1500;
};

/**
 * Slugify string
 * @param {string} text - Text to slugify
 * @returns {string} Slugified text
 */
const slugify = (text) => {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
};

/**
 * Paginate query results
 * @param {number} page - Page number (1-indexed)
 * @param {number} limit - Items per page
 * @returns {Object} Pagination object with offset and limit
 */
const paginate = (page = 1, limit = 20) => {
  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(
    Math.max(1, parseInt(limit, 10) || 20),
    constants.pagination.maxLimit
  );
  const offset = (pageNum - 1) * limitNum;
  
  return {
    page: pageNum,
    limit: limitNum,
    offset,
  };
};

/**
 * Create pagination response
 * @param {Array} data - Data array
 * @param {number} total - Total count
 * @param {number} page - Current page
 * @param {number} limit - Items per page
 * @returns {Object} Pagination response
 */
const paginationResponse = (data, total, page, limit) => {
  const totalPages = Math.ceil(total / limit);
  
  return {
    data,
    pagination: {
      total,
      page,
      limit,
      totalPages,
      hasMore: page < totalPages,
      hasPrevious: page > 1,
    },
  };
};

/**
 * Sanitize user object (remove sensitive fields)
 * @param {Object} user - User object
 * @returns {Object} Sanitized user
 */
const sanitizeUser = (user) => {
  if (!user) return null;
  
  const { password, ...sanitized } = user;
  return sanitized;
};

/**
 * Generate OTP code
 * @param {number} length - OTP length
 * @returns {string} OTP code
 */
const generateOTP = (length = 6) => {
  return Math.random()
    .toString()
    .substring(2, 2 + length);
};

/**
 * Check if date is within range
 * @param {Date} date - Date to check
 * @param {Date} startDate - Start date
 * @param {Date} endDate - End date
 * @returns {boolean} True if within range
 */
const isDateInRange = (date, startDate, endDate) => {
  const d = new Date(date);
  return d >= new Date(startDate) && d <= new Date(endDate);
};

/**
 * Get date range for period
 * @param {string} period - Period (today, week, month, year)
 * @returns {Object} Start and end dates
 */
const getDateRange = (period) => {
  const now = new Date();
  const startOfDay = new Date(now.setHours(0, 0, 0, 0));
  
  switch (period) {
    case 'today':
      return {
        start: startOfDay,
        end: new Date(),
      };
    case 'week':
      const startOfWeek = new Date(startOfDay);
      startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay());
      return {
        start: startOfWeek,
        end: new Date(),
      };
    case 'month':
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      return {
        start: startOfMonth,
        end: new Date(),
      };
    case 'year':
      const startOfYear = new Date(now.getFullYear(), 0, 1);
      return {
        start: startOfYear,
        end: new Date(),
      };
    default:
      return {
        start: startOfDay,
        end: new Date(),
      };
  }
};

module.exports = {
  formatPhoneNumber,
  isValidPhoneNumber,
  getMobileMoneyProvider,
  formatCurrency,
  parseCurrency,
  isValidRegion,
  isValidDistrict,
  getDistrictsByRegion,
  generateOrderNumber,
  generateTrackingNumber,
  calculateDeliveryFee,
  slugify,
  paginate,
  paginationResponse,
  sanitizeUser,
  generateOTP,
  isDateInRange,
  getDateRange,
};
