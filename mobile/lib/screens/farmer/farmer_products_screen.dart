import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/loading_overlay.dart';

class FarmerProductsScreen extends StatefulWidget {
  const FarmerProductsScreen({super.key});

  @override
  State<FarmerProductsScreen> createState() => _FarmerProductsScreenState();
}

class _FarmerProductsScreenState extends State<FarmerProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      await productProvider.loadFarmerProducts(authProvider.currentUser!.id);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Out of Stock'),
            Tab(text: 'Draft'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-product'),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Search & Filter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (final value) =>
                            setState(() => _searchQuery = value),
                        decoration: const InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list),
                      onSelected: (final value) {
                        setState(() => _selectedCategory = value);
                      },
                      itemBuilder: (final context) => [
                        const PopupMenuItem(value: 'All', child: Text('All')),
                        ...ProductCategory.all.map(
                          (final cat) =>
                              PopupMenuItem(value: cat, child: Text(cat)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Products List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductList(ProductStatus.active),
                  _buildProductList(ProductStatus.outOfStock),
                  _buildProductList(ProductStatus.draft),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(final String status) {
    return Consumer<ProductProvider>(
      builder: (final context, final provider, final child) {
        final products = provider.farmerProducts
            .where((final p) => p.status == status)
            .where((final p) =>
                _selectedCategory == 'All' ||
                p.category == _selectedCategory)
            .where((final p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (products.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: _loadProducts,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (final context, final index) {
              return _buildProductCard(products[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(final String status) {
    String message;
    IconData icon;

    switch (status) {
      case ProductStatus.active:
        message = 'No active products';
        icon = Icons.inventory_2_outlined;
        break;
      case ProductStatus.outOfStock:
        message = 'No out-of-stock products';
        icon = Icons.remove_shopping_cart;
        break;
      case ProductStatus.draft:
        message = 'No draft products';
        icon = Icons.drafts_outlined;
        break;
      default:
        message = 'No products';
        icon = Icons.inventory_2_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to start selling',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(final ProductModel product) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/add-product',
          arguments: {'productId': product.id},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, final __, final ___) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.grey200,
                          child: const Icon(Icons.image),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.grey200,
                        child: const Icon(Icons.image),
                      ),
              ),
              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isOrganic)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Organic',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          currencyFormat.format(product.price),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          '/${product.unit}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey500,
                                  ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStockColor(product.availableQuantity)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.availableQuantity.toInt()} ${product.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStockColor(product.availableQuantity),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.visibility, size: 14, color: AppColors.grey500),
                        const SizedBox(width: 4),
                        Text(
                          '${product.views} views',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.shopping_cart, size: 14, color: AppColors.grey500),
                        const SizedBox(width: 4),
                        Text(
                          '${product.totalSold} sold',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          onSelected: (final value) => _handleProductAction(product, value),
                          itemBuilder: (final context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: product.status == ProductStatus.active
                                  ? 'deactivate'
                                  : 'activate',
                              child: Row(
                                children: [
                                  Icon(
                                    product.status == ProductStatus.active
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    product.status == ProductStatus.active
                                        ? 'Deactivate'
                                        : 'Activate',
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStockColor(final double quantity) {
    if (quantity <= 0) return AppColors.error;
    if (quantity < 10) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _handleProductAction(final ProductModel product, final String action) async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    switch (action) {
      case 'edit':
        Navigator.pushNamed(
          context,
          '/add-product',
          arguments: {'productId': product.id},
        );
        break;
      case 'activate':
        await productProvider.updateProductStatus(
          product.id,
          ProductStatus.active,
        );
        break;
      case 'deactivate':
        await productProvider.updateProductStatus(
          product.id,
          ProductStatus.draft,
        );
        break;
      case 'delete':
        _showDeleteDialog(product);
        break;
    }
  }

  void _showDeleteDialog(final ProductModel product) {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final productProvider =
                  Provider.of<ProductProvider>(context, listen: false);
              final success = await productProvider.deleteProduct(product.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class ProductStatus {
  static const String active = 'active';
  static const String outOfStock = 'out_of_stock';
  static const String draft = 'draft';
  static const String pending = 'pending';
}
