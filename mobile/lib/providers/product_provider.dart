import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

enum ProductsStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  ProductsStatus _status = ProductsStatus.initial;
  final List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _farmerProducts = [];
  List<ProductModel> _searchResults = [];
  ProductModel? _selectedProduct;
  String? _errorMessage;
  
  // Filters
  String? _selectedCategory;
  String? _selectedRegion;
  double? _minPrice;
  double? _maxPrice;
  bool? _organicOnly;
  String _sortBy = 'newest';
  
  // Pagination
  int _currentPage = 1;
  bool _hasMoreProducts = true;
  static const int _pageSize = 20;

  // Getters
  ProductsStatus get status => _status;
  List<ProductModel> get products => _products;
  List<ProductModel> get featuredProducts => _featuredProducts;
  List<ProductModel> get farmerProducts => _farmerProducts;
  List<ProductModel> get searchResults => _searchResults;
  ProductModel? get selectedProduct => _selectedProduct;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  String? get selectedRegion => _selectedRegion;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool? get organicOnly => _organicOnly;
  String get sortBy => _sortBy;
  bool get hasMoreProducts => _hasMoreProducts;
  bool get isLoading => _status == ProductsStatus.loading;
  bool get isLoadingMore => _status == ProductsStatus.loadingMore;

  // Category counts
  Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final product in _products) {
      counts[product.category] = (counts[product.category] ?? 0) + 1;
    }
    return counts;
  }

  // Fetch all products with optional filters
  Future<void> fetchProducts({final bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreProducts = true;
    }

    if (_status == ProductsStatus.loading) return;

    _status = refresh ? ProductsStatus.loading : ProductsStatus.loadingMore;
    if (refresh) _products.clear();
    _errorMessage = null;
    notifyListeners();

    try {
      final newProducts = await _productService.getProducts(
        page: _currentPage,
        category: _selectedCategory,
        region: _selectedRegion,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        organicOnly: _organicOnly,
        sortBy: _sortBy,
      );

      if (newProducts.length < _pageSize) {
        _hasMoreProducts = false;
      }

      _products.addAll(newProducts);
      _currentPage++;
      _status = ProductsStatus.loaded;
    } catch (e) {
      _status = ProductsStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Fetch featured products
  Future<void> fetchFeaturedProducts() async {
    try {
      _featuredProducts = await _productService.getFeaturedProducts();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Fetch products by farmer ID
  Future<void> fetchFarmerProducts(final String farmerId) async {
    _status = ProductsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _farmerProducts = await _productService.getProductsByFarmer(farmerId);
      _status = ProductsStatus.loaded;
    } catch (e) {
      _status = ProductsStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Fetch single product by ID
  Future<void> fetchProductById(final String productId) async {
    _status = ProductsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedProduct = await _productService.getProductById(productId);
      _status = ProductsStatus.loaded;
    } catch (e) {
      _status = ProductsStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Search products
  Future<void> searchProducts(final String query) async {
    _status = ProductsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (query.trim().isEmpty) {
        _searchResults = await _productService.getProducts(
          category: _selectedCategory,
          region: _selectedRegion,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          organicOnly: _organicOnly,
          sortBy: _sortBy,
        );
      } else {
        _searchResults = await _productService.searchProducts(
          query,
          category: _selectedCategory,
          region: _selectedRegion,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          organicOnly: _organicOnly,
          sortBy: _sortBy,
        );
      }
      _status = ProductsStatus.loaded;
    } catch (e) {
      _status = ProductsStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Create new product
  Future<ProductModel?> createProduct(
    final ProductModel product,
    final List<File> imageFiles,
  ) async {
    _errorMessage = null;

    try {
      final createdProduct = await _productService.createProduct(product, imageFiles);
      _farmerProducts.insert(0, createdProduct);
      notifyListeners();
      return createdProduct;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update product
  Future<bool> updateProduct(final ProductModel product) async {
    _errorMessage = null;

    try {
      final updatedProduct = await _productService.updateProduct(product);
      
      // Update in farmer products list
      final farmerIndex = _farmerProducts.indexWhere((final p) => p.id == product.id);
      if (farmerIndex >= 0) {
        _farmerProducts[farmerIndex] = updatedProduct;
      }
      
      // Update in all products list
      final allIndex = _products.indexWhere((final p) => p.id == product.id);
      if (allIndex >= 0) {
        _products[allIndex] = updatedProduct;
      }
      
      // Update selected product if same
      if (_selectedProduct?.id == product.id) {
        _selectedProduct = updatedProduct;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(final String productId) async {
    _errorMessage = null;

    try {
      await _productService.deleteProduct(productId);
      
      _farmerProducts.removeWhere((final p) => p.id == productId);
      _products.removeWhere((final p) => p.id == productId);
      
      if (_selectedProduct?.id == productId) {
        _selectedProduct = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update product status
  Future<bool> updateProductStatus(final String productId, final String status) async {
    _errorMessage = null;

    try {
      await _productService.updateProductStatus(productId, status);
      
      // Update locally
      final farmerIndex = _farmerProducts.indexWhere((final p) => p.id == productId);
      if (farmerIndex >= 0) {
        _farmerProducts[farmerIndex] = _farmerProducts[farmerIndex].copyWith(
          status: status,
        );
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Upload product images
  Future<List<String>> uploadImages(final String productId, final List<String> imagePaths) async {
    try {
      return await _productService.uploadImages(productId, imagePaths);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Filter setters
  void setCategory(final String? category, {final bool refresh = true}) {
    if (_selectedCategory != category) {
      _selectedCategory = category == 'All' ? null : category;
      if (refresh) {
        fetchProducts(refresh: true);
      }
    }
  }

  void setRegion(final String? region, {final bool refresh = true}) {
    if (_selectedRegion != region) {
      _selectedRegion = region;
      if (refresh) {
        fetchProducts(refresh: true);
      }
    }
  }

  void setPriceRange(final double? min, final double? max, {final bool refresh = true}) {
    _minPrice = min;
    _maxPrice = max;
    if (refresh) {
      fetchProducts(refresh: true);
    }
  }

  void setOrganicOnly(final bool? value, {final bool refresh = true}) {
    if (_organicOnly != value) {
      _organicOnly = value;
      if (refresh) {
        fetchProducts(refresh: true);
      }
    }
  }

  void setSortBy(final String sortBy, {final bool refresh = true}) {
    if (_sortBy != sortBy) {
      _sortBy = sortBy;
      if (refresh) {
        fetchProducts(refresh: true);
      }
    }
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedRegion = null;
    _minPrice = null;
    _maxPrice = null;
    _organicOnly = null;
    _sortBy = 'newest';
    fetchProducts(refresh: true);
  }

  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }

  void setSelectedProduct(final ProductModel? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // Load more products for infinite scroll
  Future<void> loadMoreProducts() async {
    if (_hasMoreProducts && _status != ProductsStatus.loadingMore) {
      await fetchProducts();
    }
  }

  // Get products by category for home screen
  List<ProductModel> getProductsByCategory(final String category) {
    return _products.where((final p) => p.category == category).toList();
  }

  // Get filtered farmer products by status
  List<ProductModel> getFarmerProductsByStatus(final String status) {
    return _farmerProducts.where((final p) => p.status == status).toList();
  }

  // Get product by ID from local lists or fetch from service
  Future<ProductModel?> getProductById(final String productId) async {
    // First check local lists
    var product = _products.where((final p) => p.id == productId).firstOrNull;
    product ??= _farmerProducts.where((final p) => p.id == productId).firstOrNull;
    product ??= _featuredProducts.where((final p) => p.id == productId).firstOrNull;
    
    if (product != null) return product;
    
    // If not found locally, fetch from service
    try {
      return await _productService.getProductById(productId);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  // Load farmer products (alias for fetchFarmerProducts)
  Future<void> loadFarmerProducts(final String farmerId) async {
    await fetchFarmerProducts(farmerId);
  }

  // Fetch products by category
  Future<List<ProductModel>> fetchProductsByCategory(final String category) async {
    try {
      final products = await _productService.getProducts(
        pageSize: 50,
        category: category,
      );
      return products;
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }
}
