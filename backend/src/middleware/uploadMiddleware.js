const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { ApiError } = require('./errorMiddleware');
const constants = require('../config/constants');

// Configure multer for memory storage
const storage = multer.memoryStorage();

// File filter function
const fileFilter = (req, file, cb) => {
  // Check allowed MIME types first.
  if (constants.upload.allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    // Some clients may report generic MIME; allow known safe image extensions.
    const ext = path.extname(file.originalname || '').toLowerCase();
    const extensionAllowed = ['.jpg', '.jpeg', '.png', '.webp'].includes(ext);

    if (extensionAllowed) {
      cb(null, true);
      return;
    }

    cb(new ApiError(400, `Invalid file type. Allowed types: ${constants.upload.allowedTypes.join(', ')}`), false);
  }
};

// Create multer instance
const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: constants.upload.maxFileSize,
    files: 10, // Maximum number of files
  },
});

// Single file upload
const uploadSingle = (fieldName = 'file') => upload.single(fieldName);

// Multiple files upload
const uploadMultiple = (fieldName = 'files', maxCount = 5) => upload.array(fieldName, maxCount);

// Multiple fields upload
const uploadFields = (fields) => upload.fields(fields);

/**
 * Generate unique filename
 * @param {Object} file - Multer file object
 * @returns {string} Unique filename
 */
const generateFilename = (file) => {
  const ext = path.extname(file.originalname);
  return `${uuidv4()}${ext}`;
};

/**
 * Process uploaded file for Supabase storage
 * @param {Object} file - Multer file object
 * @param {string} folder - Storage folder
 * @returns {Object} Processed file info
 */
const processFile = (file, folder = 'uploads') => {
  if (!file) return null;
  
  const filename = generateFilename(file);
  const filePath = `${folder}/${filename}`;
  
  return {
    buffer: file.buffer,
    filename,
    filePath,
    contentType: file.mimetype,
    size: file.size,
    originalName: file.originalname,
  };
};

/**
 * Process multiple uploaded files
 * @param {Array} files - Array of multer file objects
 * @param {string} folder - Storage folder
 * @returns {Array} Processed files info
 */
const processFiles = (files, folder = 'uploads') => {
  if (!files || !files.length) return [];
  
  return files.map(file => processFile(file, folder));
};

module.exports = {
  upload,
  uploadSingle,
  uploadMultiple,
  uploadFields,
  generateFilename,
  processFile,
  processFiles,
};
