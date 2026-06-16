import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {

  const ProductCard({
    required this.product, super.key,
    this.onTap,
    this.onFavorite,
    this.onAddToCart,
    this.isFavorite = false,
    this.showFarmerInfo = true,
    this.isCompact = false,
  });
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onAddToCart;
  final bool isFavorite;
  final bool showFarmerInfo;
  final bool isCompact;

  @override
  Widget build(final BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: product.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.images.first,
                          height: isCompact ? 100 : 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (final context, final url) => Container(
                            height: isCompact ? 100 : 120,
                            color: AppColors.grey200,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (final context, final url, final error) => Container(
                            height: isCompact ? 100 : 120,
                            color: AppColors.grey200,
                            child: const Icon(Icons.image, color: AppColors.grey400),
                          ),
                        )
                      : Container(
                          height: isCompact ? 100 : 120,
                          color: AppColors.grey200,
                          child: Center(
                            child: Text(
                              ProductCategory.getIcon(product.category),
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                ),

                // Favorite Button
                if (onFavorite != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite ? AppColors.error : AppColors.grey600,
                        ),
                      ),
                    ),
                  ),

                // Organic Badge
                if (product.isOrganic)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco, size: 10, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'Organic',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Out of Stock Overlay
                if (product.availableQuantity <= 0)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(isCompact ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  if (!isCompact)
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.grey500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (!isCompact) const SizedBox(height: 4),

                  // Name
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isCompact ? 4 : 8),

                  // Price
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currencyFormat.format(product.price),
                              style: TextStyle(
                                fontSize: isCompact ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            Text(
                              '/${product.unit}',
                              style: TextStyle(
                                fontSize: isCompact ? 10 : 11,
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onAddToCart != null && product.availableQuantity > 0)
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Farmer Info
                  if (showFarmerInfo && !isCompact) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.grey200,
                          backgroundImage: product.farmerPhoto != null
                              ? NetworkImage(product.farmerPhoto!)
                              : null,
                          child: product.farmerPhoto == null
                              ? Text(
                                  product.farmerName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.grey600,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.farmerName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.grey600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...[
                        const Icon(Icons.star, size: 12, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCardHorizontal extends StatelessWidget {

  const ProductCardHorizontal({
    required this.product, super.key,
    this.onTap,
    this.onFavorite,
    this.onAddToCart,
    this.isFavorite = false,
  });
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onAddToCart;
  final bool isFavorite;

  @override
  Widget build(final BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.images.first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (final context, final url) => Container(
                            width: 80,
                            height: 80,
                            color: AppColors.grey200,
                          ),
                          errorWidget: (final context, final url, final error) => Container(
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
                          child: Center(
                            child: Text(
                              ProductCategory.getIcon(product.category),
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                ),
                if (product.isOrganic)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.eco, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        currencyFormat.format(product.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      Text(
                        '/${product.unit}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.farmerName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                if (onFavorite != null)
                  IconButton(
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isFavorite ? AppColors.error : AppColors.grey400,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                if (onAddToCart != null)
                  IconButton(
                    onPressed: onAddToCart,
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      size: 20,
                      color: AppColors.primaryGreen,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FeaturedProductCard extends StatelessWidget {

  const FeaturedProductCard({
    required this.product, super.key,
    this.onTap,
  });
  final ProductModel product;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: product.images.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(product.images.first),
                  fit: BoxFit.cover,
                )
              : null,
          color: product.images.isEmpty ? AppColors.grey200 : null,
        ),
        child: Stack(
          children: [
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.isOrganic)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Organic',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        currencyFormat.format(product.price),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/${product.unit}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Featured Badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Featured',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
