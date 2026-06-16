import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/cart_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/custom_button.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (final context, final cartProvider, final child) {
              if (cartProvider.itemCount > 0) {
                return TextButton(
                  onPressed: () => _showClearCartDialog(context, cartProvider),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: AppColors.error),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (final context, final cartProvider, final child) {
          if (cartProvider.items.isEmpty) {
            return _buildEmptyCart(context);
          }
          return _buildCartContent(context, cartProvider);
        },
      ),
      bottomSheet: Consumer<CartProvider>(
        builder: (final context, final cartProvider, final child) {
          if (cartProvider.items.isEmpty) {
            return const SizedBox.shrink();
          }
          return _buildBottomBar(context, cartProvider);
        },
      ),
    );
  }

  Widget _buildEmptyCart(final BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(final BuildContext context, final CartProvider cartProvider) {
    final items = cartProvider.items;
    final farmerIds = cartProvider.farmerIds.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
      itemCount: farmerIds.length,
      itemBuilder: (final context, final index) {
        final farmerId = farmerIds[index];
        final farmerItems = items.where((final item) => item.product.farmerId == farmerId).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farmer Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.store, size: 20, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    farmerItems.first.product.farmerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            // Items from this farmer
            ...farmerItems.map((final item) => _buildCartItem(context, item, cartProvider)),
            if (index < farmerIds.length - 1)
              const Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildCartItem(final BuildContext context, final CartItemModel item, final CartProvider cartProvider) {
    final product = item.product;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
                    imageUrl: product.primaryImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (final context, final url) => const ColoredBox(
                      color: AppColors.grey200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (final context, final url, final error) => const ColoredBox(
                      color: AppColors.grey200,
                      child: Icon(Icons.image),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'UGX ${product.price.toStringAsFixed(0)} / ${product.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Controls
                    Row(
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove,
                          onPressed: () {
                            if (item.quantity > 1) {
                              cartProvider.updateQuantity(
                                product.id,
                                item.quantity - 1,
                              );
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${item.quantity} ${product.unit}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Icons.add,
                          onPressed: () {
                            if (item.quantity < product.availableQuantity) {
                              cartProvider.updateQuantity(
                                product.id,
                                item.quantity + 1,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    // Total
                    Text(
                      'UGX ${item.totalPrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => cartProvider.removeItem(product.id),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required final IconData icon,
    required final VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomBar(final BuildContext context, final CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    context,
                    'Subtotal (${cartProvider.itemCount} items)',
                    'UGX ${cartProvider.subtotal.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    context,
                    'Delivery Fee',
                    'Calculated at checkout',
                    isSubtle: true,
                  ),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    context,
                    'Estimated Total',
                    'UGX ${cartProvider.subtotal.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Checkout Button
            CustomButton(
              text: 'Proceed to Checkout',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.checkout),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    final BuildContext context,
    final String label,
    final String value, {
    final bool isBold = false,
    final bool isSubtle = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSubtle ? AppColors.grey500 : null,
                fontWeight: isBold ? FontWeight.bold : null,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSubtle ? AppColors.grey500 : AppColors.primaryGreen,
                fontWeight: isBold ? FontWeight.bold : null,
              ),
        ),
      ],
    );
  }

  void _showClearCartDialog(final BuildContext context, final CartProvider cartProvider) {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
