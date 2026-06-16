import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  List<dynamic> _extractListResponse(final dynamic response) {
    if (response is List) return response;

    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;

      if (data is Map<String, dynamic>) {
        final items = data['items'];
        if (items is List) return items;
      }

      final items = response['items'];
      if (items is List) return items;
    }

    return const [];
  }

  Map<String, String> _mapSortParams(final String sortBy) {
    switch (sortBy) {
      case 'price_low':
        return {'sortBy': 'price', 'sortOrder': 'asc'};
      case 'price_high':
        return {'sortBy': 'price', 'sortOrder': 'desc'};
      case 'rating':
      case 'relevance':
        return {'sortBy': 'rating', 'sortOrder': 'desc'};
      case 'name':
        return {'sortBy': 'name', 'sortOrder': 'asc'};
      case 'newest':
      default:
        return {'sortBy': 'created_at', 'sortOrder': 'desc'};
    }
  }

  // Get all products with filters
  Future<List<ProductModel>> getProducts({
    final int page = 1,
    final int pageSize = 20,
    final String? category,
    final String? region,
    final double? minPrice,
    final double? maxPrice,
    final bool? organicOnly,
    final String sortBy = 'newest',
  }) async {
    try {
      // Build query parameters
      final params = <String, String>{
        'page': page.toString(),
        'limit': pageSize.toString(),
      };

      if (category != null) params['category'] = ProductCategory.toId(category);
      if (region != null) params['region'] = region;
      if (minPrice != null) params['minPrice'] = minPrice.toString();
      if (maxPrice != null) params['maxPrice'] = maxPrice.toString();
      if (organicOnly ?? false) params['isOrganic'] = 'true';
      params.addAll(_mapSortParams(sortBy));

      final response = await _apiService.get('/products', queryParams: params);
      final data = _extractListResponse(response);

      return data.map((final json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Get featured products
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final response = await _apiService.get('/products/featured');
      final data = _extractListResponse(response);

      return data.map((final json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured products: $e');
    }
  }

  // Get products by farmer
  Future<List<ProductModel>> getProductsByFarmer(final String farmerId) async {
    try {
      final data = await _apiService.query(
        'products',
        filters: {'farmer_id': farmerId},
        orderBy: 'created_at',
      );

      return data.map(ProductModel.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to fetch farmer products: $e');
    }
  }

  // Get product by ID
  Future<ProductModel> getProductById(final String productId) async {
    try {
      final data = await _apiService.getById('products', productId);
      if (data == null) {
        throw Exception('Product not found');
      }
      return ProductModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts(
    final String query, {
    final int page = 1,
    final int pageSize = 20,
    final String? category,
    final String? region,
    final double? minPrice,
    final double? maxPrice,
    final bool? organicOnly,
    final String sortBy = 'relevance',
  }) async {
    try {
      final params = <String, String>{
        'q': query,
        'page': page.toString(),
        'limit': pageSize.toString(),
      };

      if (category != null) params['category'] = ProductCategory.toId(category);
      if (region != null) params['region'] = region;
      if (minPrice != null) params['minPrice'] = minPrice.toString();
      if (maxPrice != null) params['maxPrice'] = maxPrice.toString();
      if (organicOnly ?? false) params['isOrganic'] = 'true';
      params.addAll(_mapSortParams(sortBy));

      final response = await _apiService.get(
        '/products/search',
        queryParams: params,
      );
      final data = _extractListResponse(response);

      return data.map((final json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Create product
  Future<ProductModel> createProduct(
    final ProductModel product,
    final List<File> imageFiles,
  ) async {
    try {
      final files = <http.MultipartFile>[];
      
      // Add image files
      for (var i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final bytes = await file.readAsBytes();
        final filename = file.path.split('/').last;
        final extension = filename.contains('.')
            ? filename.split('.').last.toLowerCase()
            : '';

        MediaType contentType;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            contentType = MediaType('image', 'jpeg');
            break;
          case 'png':
            contentType = MediaType('image', 'png');
            break;
          case 'webp':
            contentType = MediaType('image', 'webp');
            break;
          default:
            throw Exception(
              'Unsupported image format "$extension". Use JPG, PNG, or WEBP.',
            );
        }
        
        files.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: filename,
            contentType: contentType,
          ),
        );
      }

      // Prepare form fields
      final fields = <String, String>{
        'name': product.name,
        'description': product.description,
        'category': ProductCategory.toId(product.category), // Convert to backend ID
        'price': product.price.toString(),
        'unit': ProductUnit.toBackend(product.unit),
        'quantity': product.quantity.toInt().toString(),
        'isOrganic': product.isOrganic.toString(),
        'harvestDate': product.harvestDate.toIso8601String(),
        if (product.expiryDate != null) 
          'expiryDate': product.expiryDate!.toIso8601String(),
      };

      final response = await _apiService.postMultipart('/products', fields, files: files);
      final data = response['data'] ?? response;
      return ProductModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      // Log detailed error for debugging
      print('Product creation error: $e');
      throw Exception('Failed to create product: $e');
    }
  }

  // Update product
  Future<ProductModel> updateProduct(final ProductModel product) async {
    try {
      final data = await _apiService.update(
        'products',
        product.id,
        product.toJson(),
      );
      return ProductModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(final String productId) async {
    try {
      await _apiService.deleteRecord('products', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Update product status
  Future<void> updateProductStatus(final String productId, final String status) async {
    try {
      await _apiService.update('products', productId, {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update product status: $e');
    }
  }

  // Upload product images
  Future<List<String>> uploadImages(final String productId, final List<String> imagePaths) async {
    try {
      final imageUrls = <String>[];

      for (var i = 0; i < imagePaths.length; i++) {
        final file = File(imagePaths[i]);
        final bytes = await file.readAsBytes();
        final extension = imagePaths[i].split('.').last;
        final path = 'products/$productId/image_$i.$extension';

        final url = await _apiService.uploadFile(
          bucket: 'products',
          path: path,
          fileBytes: bytes,
          contentType: 'image/$extension',
        );

        imageUrls.add(url);
      }

      // Update product with new image URLs
      await _apiService.update('products', productId, {
        'images': imageUrls,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Delete product image
  Future<void> deleteImage(final String productId, final String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('products');
      if (bucketIndex >= 0) {
        final path = pathSegments.sublist(bucketIndex).join('/');
        await _apiService.deleteFile(bucket: 'products', path: path);
      }

      // Get current product
      final product = await getProductById(productId);
      final updatedImages = product.images.where((final img) => img != imageUrl).toList();

      // Update product
      await _apiService.update('products', productId, {
        'images': updatedImages,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Get product categories with counts
  Future<Map<String, int>> getCategoryCounts() async {
    try {
      final response = await _apiService.get('/products/categories');
      final rawData = response['data'] ?? response;

      if (rawData is! List) {
        return {};
      }

      final counts = <String, int>{};
      for (final item in rawData) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id']?.toString();
        if (id == null || id.isEmpty) continue;
        final displayCategory = ProductCategory.fromId(id);
        counts[displayCategory] = (item['count'] as num?)?.toInt() ?? 0;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to fetch category counts: $e');
    }
  }

  // Update product quantity (after order)
  Future<void> updateQuantity(final String productId, final int soldQuantity) async {
    try {
      final product = await getProductById(productId);
      final newQuantity = product.availableQuantity - soldQuantity;

      final updates = {
        'available_quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If quantity is 0, mark as out of stock
      if (newQuantity <= 0) {
        updates['status'] = 'out_of_stock';
      }

      await _apiService.update('products', productId, updates);
    } catch (e) {
      throw Exception('Failed to update quantity: $e');
    }
  }

  // Increment view count
  Future<void> incrementViews(final String productId) async {
    try {
      await _apiService.post('/products/$productId/view');
    } catch (e) {
      // Silent fail for view count
    }
  }

  // Get similar products
  Future<List<ProductModel>> getSimilarProducts(
    final String productId,
    final String category,
  ) async {
    try {
      final response = await _apiService.get(
        '/products',
        queryParams: {
          'category': ProductCategory.toId(category),
          'limit': '6',
          ..._mapSortParams('rating'),
        },
      );
      final data = _extractListResponse(response);

      return data
          .map((final json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .where((final product) => product.id != productId)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch similar products: $e');
    }
  }

  // Add product review
  Future<void> addReview(
    final String productId, {
    required final double rating,
    final String? comment,
  }) async {
    try {
      await _apiService.post('/products/$productId/reviews', body: {
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  Future<void> _updateProductRating(final String productId) async {
    try {
      final reviews = await _apiService.query(
        'product_reviews',
        filters: {'product_id': productId},
      );

      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold<double>(
          0,
          (final sum, final review) => sum + (review['rating'] as num).toDouble(),
        );
        final avgRating = totalRating / reviews.length;

        await _apiService.update('products', productId, {
          'rating': avgRating,
          'review_count': reviews.length,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Silent fail for rating update
    }
  }

  // Get product reviews
  Future<List<Map<String, dynamic>>> getProductReviews(final String productId) async {
    try {
      final response = await _apiService.get('/products/$productId/reviews');
      final reviews = (response['data'] ?? []) as List<dynamic>;
      return reviews.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<void> updateReview(
    final String productId,
    final String reviewId, {
    required final double rating,
    final String? comment,
  }) async {
    try {
      await _apiService.put('/products/$productId/reviews/$reviewId', body: {
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  Future<void> deleteReview(final String productId, final String reviewId) async {
    try {
      await _apiService.delete('/products/$productId/reviews/$reviewId');
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }
}
