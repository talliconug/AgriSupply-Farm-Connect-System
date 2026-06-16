const { supabase, uploadFile, deleteFile } = require('../config/supabase');
const { ApiError, asyncHandler } = require('../middleware/errorMiddleware');
const { paginate, paginationResponse, slugify } = require('../utils/helpers');
const { processFiles } = require('../middleware/uploadMiddleware');
const constants = require('../config/constants');
const logger = require('../utils/logger');
const {
  createInAppNotification,
  createBulkInAppNotifications,
} = require('../utils/notificationHelper');

/**
 * @desc    Get all products with filters
 * @route   GET /api/v1/products
 */
const getProducts = asyncHandler(async (req, res) => {
  const { 
    page,
    limit,
    category,
    region,
    minPrice: minPriceRaw,
    maxPrice: maxPriceRaw,
    min_price: minPriceLegacy,
    max_price: maxPriceLegacy,
    isOrganic: isOrganicRaw,
    organic: organicLegacy,
    farmerId,
    sortBy: sortByRaw,
    sort: sortLegacy,
    sortOrder: sortOrderRaw,
  } = req.query;

  const minPrice = minPriceRaw ?? minPriceLegacy;
  const maxPrice = maxPriceRaw ?? maxPriceLegacy;
  const isOrganic = isOrganicRaw ?? organicLegacy;

  const requestedSort = sortByRaw ?? sortLegacy ?? 'created_at';
  let normalizedSortBy = requestedSort;
  let normalizedSortOrder = sortOrderRaw;

  // Backward-compatible sort aliases for older clients.
  if (requestedSort === 'newest') {
    normalizedSortBy = 'created_at';
    normalizedSortOrder = normalizedSortOrder ?? 'desc';
  } else if (requestedSort === 'price_low') {
    normalizedSortBy = 'price';
    normalizedSortOrder = normalizedSortOrder ?? 'asc';
  } else if (requestedSort === 'price_high') {
    normalizedSortBy = 'price';
    normalizedSortOrder = normalizedSortOrder ?? 'desc';
  } else if (requestedSort === 'relevance') {
    normalizedSortBy = 'rating';
    normalizedSortOrder = normalizedSortOrder ?? 'desc';
  }

  normalizedSortOrder = normalizedSortOrder ?? 'desc';

  const effectiveRegion = region || null;
  
  const { page: pageNum, limit: limitNum, offset } = paginate(page, limit);

  let query = supabase
    .from('products')
    .select(`
      *,
      farmer:farmer_id (id, full_name, photo_url, region, is_verified)
    `, { count: 'exact' })
    .eq('status', 'active');

  if (category) {
    query = query.eq('category', category);
  }

  if (effectiveRegion) {
    query = query.eq('farmer.region', effectiveRegion);
  }

  if (minPrice) {
    query = query.gte('price', parseFloat(minPrice));
  }

  if (maxPrice) {
    query = query.lte('price', parseFloat(maxPrice));
  }

  if (isOrganic === 'true') {
    query = query.eq('is_organic', true);
  }

  if (farmerId) {
    query = query.eq('farmer_id', farmerId);
  }

  // Apply sorting
  const validSortFields = ['created_at', 'price', 'rating', 'name'];
  const sortField = validSortFields.includes(normalizedSortBy)
    ? normalizedSortBy
    : 'created_at';
  query = query.order(sortField, { ascending: normalizedSortOrder === 'asc' });

  const { data, count, error } = await query.range(offset, offset + limitNum - 1);

  if (error) {
    logger.error('Get products error:', error);
    throw new ApiError(400, 'Failed to fetch products');
  }

  res.json({
    success: true,
    ...paginationResponse(data, count, pageNum, limitNum),
  });
});

/**
 * @desc    Search products
 * @route   GET /api/v1/products/search
 */
const searchProducts = asyncHandler(async (req, res) => {
  const {
    q,
    page,
    limit,
    category,
    region,
    minPrice: minPriceRaw,
    maxPrice: maxPriceRaw,
    min_price: minPriceLegacy,
    max_price: maxPriceLegacy,
    isOrganic: isOrganicRaw,
    organic: organicLegacy,
    sortBy: sortByRaw,
    sort: sortLegacy,
    sortOrder: sortOrderRaw,
  } = req.query;

  const minPrice = minPriceRaw ?? minPriceLegacy;
  const maxPrice = maxPriceRaw ?? maxPriceLegacy;
  const isOrganic = isOrganicRaw ?? organicLegacy;

  const requestedSort = sortByRaw ?? sortLegacy ?? 'rating';
  let normalizedSortBy = requestedSort;
  let normalizedSortOrder = sortOrderRaw;

  if (requestedSort === 'newest') {
    normalizedSortBy = 'created_at';
    normalizedSortOrder = normalizedSortOrder ?? 'desc';
  } else if (requestedSort === 'price_low') {
    normalizedSortBy = 'price';
    normalizedSortOrder = normalizedSortOrder ?? 'asc';
  } else if (requestedSort === 'price_high') {
    normalizedSortBy = 'price';
    normalizedSortOrder = normalizedSortOrder ?? 'desc';
  } else if (requestedSort === 'relevance') {
    normalizedSortBy = 'rating';
    normalizedSortOrder = normalizedSortOrder ?? 'desc';
  }

  normalizedSortOrder = normalizedSortOrder ?? 'desc';

  const effectiveRegion = region || null;
  const { page: pageNum, limit: limitNum, offset } = paginate(page, limit);

  if (!q || q.length < 2) {
    throw new ApiError(400, 'Search query must be at least 2 characters');
  }

  let query = supabase
    .from('products')
    .select(`
      *,
      farmer:farmer_id (id, full_name, photo_url, region, is_verified)
    `, { count: 'exact' })
    .eq('status', 'active')
    .or(`name.ilike.%${q}%,description.ilike.%${q}%,category.ilike.%${q}%`);

  if (category) {
    query = query.eq('category', category);
  }

  if (effectiveRegion) {
    query = query.eq('farmer.region', effectiveRegion);
  }

  if (minPrice) {
    query = query.gte('price', parseFloat(minPrice));
  }

  if (maxPrice) {
    query = query.lte('price', parseFloat(maxPrice));
  }

  if (isOrganic === 'true') {
    query = query.eq('is_organic', true);
  }

  const validSortFields = ['created_at', 'price', 'rating', 'name'];
  const sortField = validSortFields.includes(normalizedSortBy)
    ? normalizedSortBy
    : 'rating';
  query = query.order(sortField, { ascending: normalizedSortOrder === 'asc' });

  const { data, count, error } = await query.range(offset, offset + limitNum - 1);

  if (error) {
    logger.error('Search products error:', error);
    throw new ApiError(400, 'Failed to search products');
  }

  res.json({
    success: true,
    ...paginationResponse(data, count, pageNum, limitNum),
  });
});

/**
 * @desc    Get featured products
 * @route   GET /api/v1/products/featured
 */
const getFeaturedProducts = asyncHandler(async (req, res) => {
  const { limit = 10 } = req.query;

  let query = supabase
    .from('products')
    .select(`
      *,
      farmer:farmer_id (id, full_name, photo_url, region, is_verified)
    `)
    .eq('status', 'active')
    .eq('is_featured', true)
    .order('rating', { ascending: false });

  const { data, error } = await query.limit(parseInt(limit));

  if (error) {
    logger.error('Get featured products error:', error);
    throw new ApiError(400, 'Failed to fetch featured products');
  }

  res.json({
    success: true,
    data,
  });
});

/**
 * @desc    Get product categories with counts
 * @route   GET /api/v1/products/categories
 */
const getCategories = asyncHandler(async (req, res) => {
  const { data, error } = await supabase.rpc('get_category_counts');

  if (error) {
    logger.error('Get categories error:', error);
    // Fallback to manual count
    const categories = await Promise.all(
      constants.productCategories.map(async (cat) => {
        const { count } = await supabase
          .from('products')
          .select('*', { count: 'exact', head: true })
          .eq('category', cat.id)
          .eq('status', 'active');
        return { ...cat, count };
      })
    );

    return res.json({
      success: true,
      data: categories,
    });
  }

  const categoriesWithInfo = constants.productCategories.map(cat => {
    const countData = data.find(d => d.category === cat.id);
    return {
      ...cat,
      count: countData?.count || 0,
    };
  });

  res.json({
    success: true,
    data: categoriesWithInfo,
  });
});

/**
 * @desc    Get current farmer's products
 * @route   GET /api/v1/products/my-products
 */
const getMyProducts = asyncHandler(async (req, res) => {
  const { page, limit, isActive } = req.query;
  const { page: pageNum, limit: limitNum, offset } = paginate(page, limit);
  const farmerId = req.user.id;

  let query = supabase
    .from('products')
    .select('*', { count: 'exact' })
    .eq('farmer_id', farmerId);

  if (isActive !== undefined) {
    query = query.eq('status', isActive === 'true' ? 'active' : 'draft');
  }

  const { data, count, error } = await query
    .order('created_at', { ascending: false })
    .range(offset, offset + limitNum - 1);

  if (error) {
    logger.error('Get my products error:', error);
    throw new ApiError(400, 'Failed to fetch products');
  }

  res.json({
    success: true,
    ...paginationResponse(data, count, pageNum, limitNum),
  });
});

/**
 * @desc    Get product by ID
 * @route   GET /api/v1/products/:id
 */
const getProductById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const { data, error } = await supabase
    .from('products')
    .select(`
      *,
      farmer:farmer_id (id, full_name, photo_url, region, district, is_verified, rating, phone)
    `)
    .eq('id', id)
    .single();

  if (error || !data) {
    throw new ApiError(404, 'Product not found');
  }

  // Increment view count
  await supabase
    .from('products')
    .update({ views_count: (data.views_count || 0) + 1 })
    .eq('id', id);

  // Get related products
  const { data: relatedProducts } = await supabase
    .from('products')
    .select('id, name, images, price, unit, rating')
    .eq('category', data.category)
    .neq('id', id)
    .eq('status', 'active')
    .limit(4);

  // Check if user has favorited this product
  let isFavorite = false;
  if (req.user) {
    const { data: favorite } = await supabase
      .from('product_favorites')
      .select('id')
      .eq('product_id', id)
      .eq('user_id', req.user.id)
      .single();
    isFavorite = !!favorite;
  }

  res.json({
    success: true,
    data: {
      ...data,
      relatedProducts,
      isFavorite,
    },
  });
});

/**
 * @desc    Create a new product
 * @route   POST /api/v1/products
 */
const createProduct = asyncHandler(async (req, res) => {
  const { name, description, category, price, unit, quantity, isOrganic, harvestDate, expiryDate } = req.body;
  const farmerId = req.user.id;

  // Process uploaded images
  const images = [];
  if (req.files && req.files.length > 0) {
    const processedFiles = processFiles(req.files, 'product-images');
    
    for (const file of processedFiles) {
      const uploadResult = await uploadFile(
        file.buffer,
        'product-images',
        file.filePath,
        file.contentType
      );
      
      if (uploadResult.success) {
        images.push(uploadResult.publicUrl);
      }
    }
  }

  const productData = {
    farmer_id: farmerId,
    name,
    description,
    category,
    price: parseFloat(price),
    unit,
    quantity_available: parseInt(quantity),
    is_organic: isOrganic === 'true',
    status: 'active',
    images,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  // Add optional date fields if provided
  if (harvestDate) {
    productData.harvest_date = new Date(harvestDate).toISOString();
  }
  if (expiryDate) {
    const expiry = new Date(expiryDate);
    const harvest = harvestDate ? new Date(harvestDate) : null;
    if (harvest && expiry < harvest) {
      res.status(400);
      throw new Error('Expiry date must be on or after the harvest date');
    }
    productData.expiry_date = expiry.toISOString();
  }

  const { data, error } = await supabase
    .from('products')
    .insert(productData)
    .select()
    .single();

  if (error) {
    logger.error('Create product error:', error);
    throw new ApiError(400, 'Failed to create product');
  }

  // Notify buyers about newly listed products.
  const { data: buyers } = await supabase
    .from('users')
    .select('id')
    .eq('role', 'buyer')
    .eq('is_deleted', false);

  await createBulkInAppNotifications({
    userIds: buyers?.map((buyer) => buyer.id) || [],
    type: 'product',
    title: 'New Product Added',
    message: `${data.name} is now available in the marketplace.`,
    data: { productId: data.id, farmerId },
  });

  res.status(201).json({
    success: true,
    message: 'Product created successfully',
    data,
  });
});

/**
 * @desc    Update product
 * @route   PUT /api/v1/products/:id
 */
const updateProduct = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const farmerId = req.user.id;
  const updates = req.body;

  // Verify ownership
  const { data: product } = await supabase
    .from('products')
    .select('farmer_id')
    .eq('id', id)
    .single();

  if (!product) {
    throw new ApiError(404, 'Product not found');
  }

  if (product.farmer_id !== farmerId && req.user.role !== 'admin') {
    throw new ApiError(403, 'Not authorized to update this product');
  }

  // Prepare updates
  const allowedUpdates = ['name', 'description', 'category', 'price', 'unit', 'quantity', 'is_organic', 'status', 'harvest_date', 'expiry_date'];
  const filteredUpdates = {};
  
  for (const key of allowedUpdates) {
    if (updates[key] !== undefined) {
      if (key === 'price') {
        filteredUpdates[key] = parseFloat(updates[key]);
      } else if (key === 'quantity') {
        filteredUpdates.quantity_available = parseInt(updates[key]);
      } else if (key === 'harvest_date' || key === 'expiry_date') {
        filteredUpdates[key] = new Date(updates[key]).toISOString();
      } else {
        filteredUpdates[key] = updates[key];
      }
    }
  }

  // Validate expiry_date >= harvest_date for updates
  if (filteredUpdates.expiry_date || filteredUpdates.harvest_date) {
    const { data: existing } = await supabase
      .from('products')
      .select('harvest_date, expiry_date')
      .eq('id', id)
      .single();

    const harvest = filteredUpdates.harvest_date
      ? new Date(filteredUpdates.harvest_date)
      : (existing?.harvest_date ? new Date(existing.harvest_date) : null);
    const expiry = filteredUpdates.expiry_date
      ? new Date(filteredUpdates.expiry_date)
      : (existing?.expiry_date ? new Date(existing.expiry_date) : null);

    if (harvest && expiry && expiry < harvest) {
      res.status(400);
      throw new Error('Expiry date must be on or after the harvest date');
    }
  }

  filteredUpdates.updated_at = new Date().toISOString();

  const { data, error } = await supabase
    .from('products')
    .update(filteredUpdates)
    .eq('id', id)
    .select()
    .single();

  if (error) {
    logger.error('Update product error:', error);
    throw new ApiError(400, 'Failed to update product');
  }

  res.json({
    success: true,
    message: 'Product updated successfully',
    data,
  });
});

/**
 * @desc    Add images to product
 * @route   POST /api/v1/products/:id/images
 */
const addImages = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const farmerId = req.user.id;

  if (!req.files || req.files.length === 0) {
    throw new ApiError(400, 'No files uploaded');
  }

  // Verify ownership
  const { data: product } = await supabase
    .from('products')
    .select('farmer_id, images')
    .eq('id', id)
    .single();

  if (!product) {
    throw new ApiError(404, 'Product not found');
  }

  if (product.farmer_id !== farmerId && req.user.role !== 'admin') {
    throw new ApiError(403, 'Not authorized to update this product');
  }

  // Process and upload new images
  const newImages = [];
  const processedFiles = processFiles(req.files, 'product-images');
  
  for (const file of processedFiles) {
    const uploadResult = await uploadFile(
      file.buffer,
      'product-images',
      file.filePath,
      file.contentType
    );
    
    if (uploadResult.success) {
      newImages.push(uploadResult.publicUrl);
    }
  }

  // Update product with new images
  const allImages = [...(product.images || []), ...newImages];
  
  const { data, error } = await supabase
    .from('products')
    .update({
      images: allImages,
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    logger.error('Add images error:', error);
    throw new ApiError(400, 'Failed to add images');
  }

  res.json({
    success: true,
    message: 'Images added successfully',
    data: {
      images: data.images,
    },
  });
});

/**
 * @desc    Delete product image
 * @route   DELETE /api/v1/products/:id/images/:imageIndex
 */
const deleteImage = asyncHandler(async (req, res) => {
  const { id, imageIndex } = req.params;
  const farmerId = req.user.id;
  const index = parseInt(imageIndex);

  // Verify ownership
  const { data: product } = await supabase
    .from('products')
    .select('farmer_id, images')
    .eq('id', id)
    .single();

  if (!product) {
    throw new ApiError(404, 'Product not found');
  }

  if (product.farmer_id !== farmerId && req.user.role !== 'admin') {
    throw new ApiError(403, 'Not authorized to update this product');
  }

  if (!product.images || index >= product.images.length) {
    throw new ApiError(400, 'Invalid image index');
  }

  // Delete from storage
  const imageUrl = product.images[index];
  const imagePath = imageUrl.split('/').slice(-2).join('/');
  await deleteFile('products', imagePath);

  // Remove from array
  const updatedImages = product.images.filter((_, i) => i !== index);

  const { error } = await supabase
    .from('products')
    .update({
      images: updatedImages,
      updated_at: new Date().toISOString(),
    })
    .eq('id', id);

  if (error) {
    logger.error('Delete image error:', error);
    throw new ApiError(400, 'Failed to delete image');
  }

  res.json({
    success: true,
    message: 'Image deleted successfully',
  });
});

/**
 * @desc    Delete product
 * @route   DELETE /api/v1/products/:id
 */
const deleteProduct = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const farmerId = req.user.id;

  // Verify ownership
  const { data: product } = await supabase
    .from('products')
    .select('farmer_id, images')
    .eq('id', id)
    .single();

  if (!product) {
    throw new ApiError(404, 'Product not found');
  }

  if (product.farmer_id !== farmerId && req.user.role !== 'admin') {
    throw new ApiError(403, 'Not authorized to delete this product');
  }

  // Delete images from storage
  if (product.images && product.images.length > 0) {
    for (const imageUrl of product.images) {
      const imagePath = imageUrl.split('/').slice(-2).join('/');
      await deleteFile('products', imagePath);
    }
  }

  // Delete product
  const { error } = await supabase.from('products').delete().eq('id', id);

  if (error) {
    logger.error('Delete product error:', error);
    throw new ApiError(400, 'Failed to delete product');
  }

  res.json({
    success: true,
    message: 'Product deleted successfully',
  });
});

/**
 * @desc    Get product reviews
 * @route   GET /api/v1/products/:id/reviews
 */
const getProductReviews = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { page, limit } = req.query;
  const { page: pageNum, limit: limitNum, offset } = paginate(page, limit);

  const { data, count, error } = await supabase
    .from('product_reviews')
    .select(`
      *,
      user:user_id (id, full_name, photo_url)
    `, { count: 'exact' })
    .eq('product_id', id)
    .order('created_at', { ascending: false })
    .range(offset, offset + limitNum - 1);

  if (error) {
    logger.error('Get reviews error:', error);
    throw new ApiError(400, 'Failed to fetch reviews');
  }

  res.json({
    success: true,
    ...paginationResponse(data, count, pageNum, limitNum),
  });
});

/**
 * @desc    Add product review
 * @route   POST /api/v1/products/:id/reviews
 */
const addReview = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { rating, comment } = req.body;
  const userId = req.user.id;

  // Check if product exists
  const { data: product } = await supabase
    .from('products')
    .select('id, farmer_id')
    .eq('id', id)
    .single();

  if (!product) {
    throw new ApiError(404, 'Product not found');
  }

  // Check if user has purchased this product
  const { data: purchase } = await supabase
    .from('order_items')
    .select('id')
    .eq('product_id', id)
    .eq('buyer_id', userId)
    .limit(1)
    .single();

  // For now, allow reviews without purchase (can be changed)

  // Check if user already reviewed
  const { data: existingReview } = await supabase
    .from('product_reviews')
    .select('id')
    .eq('product_id', id)
    .eq('user_id', userId)
    .single();

  if (existingReview) {
    throw new ApiError(400, 'You have already reviewed this product');
  }

  // Add review
  const { data, error } = await supabase
    .from('product_reviews')
    .insert({
      product_id: id,
      user_id: userId,
      rating,
      comment,
      created_at: new Date().toISOString(),
    })
    .select(`
      *,
      user:user_id (id, full_name, photo_url)
    `)
    .single();

  if (error) {
    logger.error('Add review error:', error);
    throw new ApiError(400, 'Failed to add review');
  }

  await createInAppNotification({
    userId: product.farmer_id,
    type: 'review',
    title: 'New Product Review',
    message: `Your product received a ${rating}-star review.`,
    data: { productId: id, reviewId: data.id },
  });

  // Update product rating
  const { data: reviews } = await supabase
    .from('product_reviews')
    .select('rating')
    .eq('product_id', id);

  const avgRating = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;

  await supabase
    .from('products')
    .update({
      rating: avgRating,
      review_count: reviews.length,
    })
    .eq('id', id);

  res.status(201).json({
    success: true,
    message: 'Review added successfully',
    data,
  });
});

/**
 * @desc    Update product review
 * @route   PUT /api/v1/products/:id/reviews/:reviewId
 */
const updateReview = asyncHandler(async (req, res) => {
  const { id, reviewId } = req.params;
  const { rating, comment } = req.body;
  const userId = req.user.id;

  // Verify ownership
  const { data: review } = await supabase
    .from('product_reviews')
    .select('user_id')
    .eq('id', reviewId)
    .single();

  if (!review) {
    throw new ApiError(404, 'Review not found');
  }

  if (review.user_id !== userId && req.user.role !== 'admin') {
    throw new ApiError(403, 'Not authorized to update this review');
  }

  const { data, error } = await supabase
    .from('product_reviews')
    .update({
      rating,
      comment,
      updated_at: new Date().toISOString(),
    })
    .eq('id', reviewId)
    .select(`
      *,
      user:user_id (id, full_name, photo_url)
    `)
    .single();

  if (error) {
    logger.error('Update review error:', error);
    throw new ApiError(400, 'Failed to update review');
  }

  // Update product rating
  const { data: reviews } = await supabase
    .from('product_reviews')
    .select('rating')
    .eq('product_id', id);

  const avgRating = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;

  await supabase
    .from('products')
    .update({ rating: avgRating })
    .eq('id', id);

  res.json({
    success: true,
    message: 'Review updated successfully',
    data,
  });
});

/**
 * @desc    Delete product review
 * @route   DELETE /api/v1/products/:id/reviews/:reviewId
 */
const deleteReview = asyncHandler(async (req, res) => {
  const { id, reviewId } = req.params;
  const userId = req.user.id;

  // Verify ownership
  const { data: review } = await supabase
    .from('product_reviews')
    .select('user_id')
    .eq('id', reviewId)
    .single();

  if (!review) {
    throw new ApiError(404, 'Review not found');
  }

  if (review.user_id !== userId && req.user.role !== 'admin') {
    throw new ApiError(403, 'Not authorized to delete this review');
  }

  const { error } = await supabase
    .from('product_reviews')
    .delete()
    .eq('id', reviewId);

  if (error) {
    logger.error('Delete review error:', error);
    throw new ApiError(400, 'Failed to delete review');
  }

  // Update product rating
  const { data: reviews } = await supabase
    .from('product_reviews')
    .select('rating')
    .eq('product_id', id);

  if (reviews.length > 0) {
    const avgRating = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;
    await supabase
      .from('products')
      .update({
        rating: avgRating,
        review_count: reviews.length,
      })
      .eq('id', id);
  } else {
    await supabase
      .from('products')
      .update({
        rating: 0,
        review_count: 0,
      })
      .eq('id', id);
  }

  res.json({
    success: true,
    message: 'Review deleted successfully',
  });
});

/**
 * @desc    Add product to favorites
 * @route   POST /api/v1/products/:id/favorite
 */
const addToFavorites = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  // Check if already favorited
  const { data: existing } = await supabase
    .from('product_favorites')
    .select('id')
    .eq('product_id', id)
    .eq('user_id', userId)
    .single();

  if (existing) {
    throw new ApiError(400, 'Product already in favorites');
  }

  const { error } = await supabase.from('product_favorites').insert({
    product_id: id,
    user_id: userId,
    created_at: new Date().toISOString(),
  });

  if (error) {
    logger.error('Add to favorites error:', error);
    throw new ApiError(400, 'Failed to add to favorites');
  }

  res.json({
    success: true,
    message: 'Added to favorites',
  });
});

/**
 * @desc    Remove product from favorites
 * @route   DELETE /api/v1/products/:id/favorite
 */
const removeFromFavorites = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const { error } = await supabase
    .from('product_favorites')
    .delete()
    .eq('product_id', id)
    .eq('user_id', userId);

  if (error) {
    logger.error('Remove from favorites error:', error);
    throw new ApiError(400, 'Failed to remove from favorites');
  }

  res.json({
    success: true,
    message: 'Removed from favorites',
  });
});

/**
 * @desc    Get user's favorite products
 * @route   GET /api/v1/products/favorites/list
 */
const getFavorites = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { page, limit } = req.query;
  const { page: pageNum, limit: limitNum, offset } = paginate(page, limit);

  const { data, count, error } = await supabase
    .from('product_favorites')
    .select(`
      product:product_id (
        *,
        farmer:farmer_id (id, full_name, photo_url, region, is_verified)
      )
    `, { count: 'exact' })
    .eq('user_id', userId)
    .range(offset, offset + limitNum - 1);

  if (error) {
    logger.error('Get favorites error:', error);
    throw new ApiError(400, 'Failed to fetch favorites');
  }

  const products = data.map(item => item.product);

  res.json({
    success: true,
    ...paginationResponse(products, count, pageNum, limitNum),
  });
});

module.exports = {
  getProducts,
  searchProducts,
  getFeaturedProducts,
  getCategories,
  getMyProducts,
  getProductById,
  createProduct,
  updateProduct,
  addImages,
  deleteImage,
  deleteProduct,
  getProductReviews,
  addReview,
  updateReview,
  deleteReview,
  addToFavorites,
  removeFromFavorites,
  getFavorites,
};
