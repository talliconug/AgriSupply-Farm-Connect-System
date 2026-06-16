import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/loading_overlay.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _adminService = AdminService();

  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'newest';
  String? _filterByCategory;
  String? _filterByStatus;

  List<ProductModel> _allProducts = [];
  List<ProductModel> _pendingProducts = [];
  List<ProductModel> _activeProducts = [];
  List<ProductModel> _rejectedProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) return;

      final products = await _adminService.getProducts(limit: 500);
      
      setState(() {
        _allProducts = products;
        _pendingProducts = products.where((final p) => p.status == 'pending').toList();
        _activeProducts = products.where((final p) => p.status == 'active').toList();
        _rejectedProducts = products.where((final p) => p.status == 'rejected').toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<ProductModel> get _currentProducts {
    List<ProductModel> products;
    switch (_tabController.index) {
      case 0:
        products = _allProducts;
        break;
      case 1:
        products = _pendingProducts;
        break;
      case 2:
        products = _activeProducts;
        break;
      case 3:
        products = _rejectedProducts;
        break;
      default:
        products = _allProducts;
    }

    return _filterAndSort(products);
  }

  List<ProductModel> _filterAndSort(final List<ProductModel> products) {
    final filtered = products.where((final product) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!product.name.toLowerCase().contains(query) &&
            !product.farmerName.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Category filter
      if (_filterByCategory != null && product.category != _filterByCategory) {
        return false;
      }

      // Status filter
      if (_filterByStatus != null && product.status != _filterByStatus) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    filtered.sort((final a, final b) {
      switch (_sortBy) {
        case 'newest':
          return b.createdAt.compareTo(a.createdAt);
        case 'oldest':
          return a.createdAt.compareTo(b.createdAt);
        case 'price_low':
          return a.price.compareTo(b.price);
        case 'price_high':
          return b.price.compareTo(a.price);
        case 'name':
          return a.name.compareTo(b.name);
        default:
          return 0;
      }
    });

    return filtered;
  }

  Future<void> _updateProductStatus(
    final ProductModel product,
    final String newStatus,
  ) async {
    setState(() => _isLoading = true);
    try {
      await _adminService.updateProduct(
        productId: product.id,
        status: newStatus,
      );
      
      await _loadProducts(); // Reload products
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product ${newStatus == 'active' ? 'approved' : 'rejected'}'),
            backgroundColor: newStatus == 'active' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(final ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _adminService.deleteProduct(product.id);
      
      await _loadProducts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showProductDetails(final ProductModel product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (final context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (final context, final scrollController) => _ProductDetailsSheet(
          product: product,
          scrollController: scrollController,
          onApprove: () {
            Navigator.pop(context);
            _updateProductStatus(product, 'active');
          },
          onReject: () {
            Navigator.pop(context);
            _updateProductStatus(product, 'rejected');
          },
          onDelete: () {
            Navigator.pop(context);
            _deleteProduct(product);
          },
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Product Management'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primaryGreen,
            tabs: [
              Tab(
                text: 'All',
                icon: Badge(
                  label: Text('${_allProducts.length}'),
                  child: const Icon(Icons.inventory_2_outlined),
                ),
              ),
              Tab(
                text: 'Pending',
                icon: Badge(
                  label: Text('${_pendingProducts.length}'),
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.pending_outlined),
                ),
              ),
              Tab(
                text: 'Active',
                icon: Badge(
                  label: Text('${_activeProducts.length}'),
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.check_circle_outline),
                ),
              ),
              Tab(
                text: 'Rejected',
                icon: Badge(
                  label: Text('${_rejectedProducts.length}'),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.cancel_outlined),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _showFilterSheet,
              icon: const Icon(Icons.filter_list),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (final value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                ),
              ),
            ),

            // Products List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(
                  4,
                  (_) => RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: _buildProductsList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    final products = _currentProducts;

    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (final context, final index) {
        final product = products[index];
        return _ProductCard(
          product: product,
          onTap: () => _showProductDetails(product),
          onApprove: () => _updateProductStatus(product, 'active'),
          onReject: () => _updateProductStatus(product, 'rejected'),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (final context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter & Sort',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Newest'),
                  selected: _sortBy == 'newest',
                  onSelected: (_) => setState(() => _sortBy = 'newest'),
                ),
                FilterChip(
                  label: const Text('Oldest'),
                  selected: _sortBy == 'oldest',
                  onSelected: (_) => setState(() => _sortBy = 'oldest'),
                ),
                FilterChip(
                  label: const Text('Price: Low-High'),
                  selected: _sortBy == 'price_low',
                  onSelected: (_) => setState(() => _sortBy = 'price_low'),
                ),
                FilterChip(
                  label: const Text('Price: High-Low'),
                  selected: _sortBy == 'price_high',
                  onSelected: (_) => setState(() => _sortBy = 'price_high'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _sortBy = 'newest';
                    _filterByCategory = null;
                    _filterByStatus = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Reset Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(final BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.images.isNotEmpty ? product.images[0] : '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, final __) => const ColoredBox(
                    color: AppColors.grey200,
                    child: Icon(Icons.image, color: AppColors.grey400),
                  ),
                  errorWidget: (_, final __, final ___) => const ColoredBox(
                    color: AppColors.grey200,
                    child: Icon(Icons.broken_image, color: AppColors.grey400),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.farmerName,
                      style: const TextStyle(
                        color: AppColors.grey600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(product.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(product.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'UGX ${NumberFormat('#,###').format(product.price)}',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              if (product.status == 'pending')
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: onApprove,
                      tooltip: 'Approve',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: onReject,
                      tooltip: 'Reject',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(final String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.grey600;
    }
  }
}

class _ProductDetailsSheet extends StatelessWidget {

  const _ProductDetailsSheet({
    required this.product,
    required this.scrollController,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });
  final ProductModel product;
  final ScrollController scrollController;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  @override
  Widget build(final BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        Row(
          children: [
            const Text(
              'Product Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Images
        if (product.images.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: product.images.length,
              itemBuilder: (final context, final index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product.images[index],
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Product Info
        _DetailRow(label: 'Name', value: product.name),
        _DetailRow(label: 'Category', value: product.category),
        _DetailRow(label: 'Farmer', value: product.farmerName),
        _DetailRow(
          label: 'Price',
          value: 'UGX ${NumberFormat('#,###').format(product.price)}/${product.unit}',
        ),
        _DetailRow(
          label: 'Available Quantity',
          value: '${product.availableQuantity} ${product.unit}',
        ),
        _DetailRow(
          label: 'Location',
          value: '${product.district ?? 'Unknown'}, ${product.region ?? 'Unknown'}',
        ),
        _DetailRow(
          label: 'Created',
          value: DateFormat('MMM dd, yyyy').format(product.createdAt),
        ),
        
        const SizedBox(height: 16),
        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(product.description),

        const SizedBox(height: 24),

        // Action Buttons
        if (product.status == 'pending') ...[
          ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check_circle),
            label: const Text('Approve Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.cancel),
            label: const Text('Reject Product'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete),
          label: const Text('Delete Product'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {

  const _DetailRow({
    required this.label,
    required this.value,
  });
  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
