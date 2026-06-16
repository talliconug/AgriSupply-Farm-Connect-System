import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/quantity_selector.dart';
import '../../widgets/rating_stars.dart';

class ProductDetailScreen extends StatefulWidget {

  const ProductDetailScreen({required this.productId, super.key});
  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = true;
  ProductModel? _product;
  bool _reviewsLoading = false;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final product = await productProvider.getProductById(widget.productId);
      setState(() {
        _product = product;
        _isLoading = false;
      });
      await _loadReviews();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    if (_product == null) return;
    setState(() => _reviewsLoading = true);
    try {
      final reviews = await _productService.getProductReviews(_product!.id);
      setState(() {
        _reviews = reviews;
        _reviewsLoading = false;
      });
    } catch (_) {
      setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _showAddReviewDialog() async {
    if (_product == null) return;

    final commentController = TextEditingController();
    double rating = 5;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (final context) {
        return StatefulBuilder(
          builder: (final context, final setModalState) => AlertDialog(
            title: const Text('Write a Review'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rating'),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (final index) {
                    final star = index + 1;
                    return IconButton(
                      onPressed: () => setModalState(() => rating = star.toDouble()),
                      icon: Icon(
                        star <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Comment',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      },
    );

    if (submitted != true) {
      commentController.dispose();
      return;
    }

    try {
      await _productService.addReview(
        _product!.id,
        rating: rating,
        comment: commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
      );
      await _loadReviews();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      commentController.dispose();
    }
  }

  void _addToCart() {
    if (_product == null) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(_product!, _quantity);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.remove);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text('${_product!.name} added to cart'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
            Navigator.pushNamed(context, AppRoutes.cart);
          },
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductInfo(),
                  const SizedBox(height: 24),
                  _buildFarmerInfo(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildReviewsSection(),
                  const SizedBox(height: 24),
                  _buildQuantitySection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    final images = _product!.images.isNotEmpty
        ? _product!.images
        : ['https://via.placeholder.com/400'];

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back, color: AppColors.grey900),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.share, color: AppColors.grey900),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite_border, color: AppColors.grey900),
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (final index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (final context, final index) {
                return CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  placeholder: (final context, final url) => const ColoredBox(
                    color: AppColors.grey200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (final context, final url, final error) => const ColoredBox(
                    color: AppColors.grey200,
                    child: Icon(Icons.image, size: 64),
                  ),
                );
              },
            ),
            if (images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (final index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? AppColors.primaryGreen
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_product!.isOrganic)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '🌱 Organic',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _product!.category,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _product!.name,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            RatingStars(rating: _product!.rating),
            const SizedBox(width: 8),
            Text(
              '(${_product!.totalRatings} reviews)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Text(
              '${_product!.totalSold} sold',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'UGX ${_product!.price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              ' / ${_product!.unit}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _product!.isAvailable
                  ? Icons.check_circle
                  : Icons.cancel,
              size: 16,
              color: _product!.isAvailable
                  ? AppColors.success
                  : AppColors.error,
            ),
            const SizedBox(width: 4),
            Text(
              _product!.isAvailable
                  ? '${_product!.availableQuantity.toStringAsFixed(0)} ${_product!.unit}s available'
                  : 'Out of stock',
              style: TextStyle(
                color: _product!.isAvailable
                    ? AppColors.success
                    : AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFarmerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryGreen,
            backgroundImage: _product!.farmerImage != null
                ? CachedNetworkImageProvider(_product!.farmerImage!)
                : null,
            child: _product!.farmerImage == null
                ? Text(
                    _product!.farmerName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _product!.farmerName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 4),
                    if (_product!.farmerVerified)
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: AppColors.info,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    RatingStars(rating: _product!.farmerRating, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      _product!.region ?? 'Uganda',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _product!.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey700,
                height: 1.5,
              ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Harvest Date', _formatDate(_product!.harvestDate)),
        if (_product!.expiryDate != null)
          _buildInfoRow('Best Before', _formatDate(_product!.expiryDate!)),
        _buildInfoRow('Location', '${_product!.district ?? ''}, ${_product!.region ?? 'Uganda'}'),
      ],
    );
  }

  Widget _buildInfoRow(final String label, final String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        QuantitySelector(
          quantity: _quantity,
          unit: _product!.unit,
          maxQuantity: _product!.availableQuantity.toInt(),
          onChanged: (final value) {
            setState(() => _quantity = value);
          },
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canReview = authProvider.isAuthenticated && authProvider.isBuyer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            if (canReview)
              TextButton.icon(
                onPressed: _showAddReviewDialog,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Write Review'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_reviewsLoading)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          Text(
            'No reviews yet. Be the first to review this product.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          )
        else
          ..._reviews.take(5).map((final review) {
            final user = review['user'] as Map<String, dynamic>?;
            final reviewRating = (review['rating'] as num?)?.toDouble() ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.grey300,
                        child: Text(
                          (user?['full_name']?.toString().isNotEmpty ?? false)
                              ? user!['full_name'].toString()[0].toUpperCase()
                              : 'U',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user?['full_name']?.toString() ?? 'Anonymous',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      RatingStars(rating: reviewRating, size: 14),
                    ],
                  ),
                  if ((review['comment'] as String?)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(review['comment'] as String),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildBottomBar() {
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
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'UGX ${(_product!.price * _quantity).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: CustomButton(
                text: 'Add to Cart',
                icon: Icons.add_shopping_cart,
                onPressed: _product!.isAvailable ? _addToCart : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(final DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
