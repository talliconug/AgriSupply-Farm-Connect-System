const multer = require('multer');
const path = require('path');
const { ApiError } = require('./errorMiddleware');

const isAllowedImageFile = (file, allowedTypes) => {
  if (allowedTypes.includes(file.mimetype)) {
    return true;
  }

  // Some mobile clients may send octet-stream or uncommon aliases; fall back to extension.
  const ext = path.extname(file.originalname || '').toLowerCase();
  return ['.jpg', '.jpeg', '.png', '.webp'].includes(ext);
};

/**
 * Optional file upload middleware
 * Allows requests to pass through even if no files are uploaded
 * This handles both multipart/form-data and application/json content types
 */
const optionalUploadMultiple = (fieldName = 'files', maxCount = 5) => {
  return (req, res, next) => {
    const contentType = req.get('Content-Type') || '';
    
    // If it's not multipart, skip multer and continue
    if (!contentType.includes('multipart/form-data')) {
      return next();
    }
    
    // Otherwise, use multer to handle the multipart upload
    const upload = multer({
      storage: multer.memoryStorage(),
      fileFilter: (req, file, cb) => {
        const constants = require('../config/constants');
        if (isAllowedImageFile(file, constants.upload.allowedTypes)) {
          cb(null, true);
        } else {
          cb(new ApiError(400, `Invalid file type. Allowed types: ${constants.upload.allowedTypes.join(', ')}`), false);
        }
      },
      limits: {
        fileSize: require('../config/constants').upload.maxFileSize,
        files: maxCount,
      },
    }).array(fieldName, maxCount);
    
    upload(req, res, next);
  };
};

module.exports = {
  ...require('./uploadMiddleware'),
  optionalUploadMultiple,
};
