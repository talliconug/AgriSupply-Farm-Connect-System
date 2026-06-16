import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar_widget.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _currentIndex = 0;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    // Marketplace is global for buyers unless they explicitly choose a region filter.
    productProvider.setRegion(null, refresh: false);
    await Future.wait([
      productProvider.fetchProducts(refresh: true),
      productProvider.fetchFeaturedProducts(),
    ]);
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildCategoriesTab(),
          _buildOrdersTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (final index) {
          setState(() => _currentIndex = index);
          if (index == 2) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final orderProvider = Provider.of<OrderProvider>(context, listen: false);
            if (authProvider.currentUser != null) {
              orderProvider.fetchBuyerOrders(authProvider.currentUser!.id);
            }
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProducts,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    SearchBarWidget(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.search),
                    ),
                  ],
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ProductCategory.all.length,
                  itemBuilder: (final context, final index) {
                    final category = ProductCategory.all[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: category,
                        icon: ProductCategory.getIcon(category),
                        isSelected: _selectedCategory == category,
                        onTap: () {
                          setState(() {
                            _selectedCategory =
                                _selectedCategory == category ? null : category;
                          });
                          Provider.of<ProductProvider>(context, listen: false)
                              .setCategory(_selectedCategory);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Featured Products
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Featured Products',
                onViewAll: () {},
              ),
            ),
            _buildFeaturedProducts(),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // All Products
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                _selectedCategory ?? 'Fresh Produce',
                onViewAll: () {},
              ),
            ),
            _buildProductGrid(),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.fullName.split(' ').first ?? 'Guest'}! 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Find fresh produce near you',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.notifications),
              icon: const Icon(Icons.notifications_outlined),
            ),
            Consumer<CartProvider>(
              builder: (final context, final cartProvider, final child) {
                return Stack(
                  children: [
                    IconButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.cart),
                      icon: const Icon(Icons.shopping_cart_outlined),
                    ),
                    if (cartProvider.itemCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryOrange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cartProvider.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(final String title, {final VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    return Consumer<ProductProvider>(
      builder: (final context, final productProvider, final child) {
        if (productProvider.isLoading && productProvider.featuredProducts.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final products = productProvider.featuredProducts;

        if (products.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Text('No featured products')),
          );
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (final context, final index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 160,
                    child: ProductCard(
                      product: products[index],
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.productDetail,
                        arguments: products[index].id,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (final context, final productProvider, final child) {
        if (productProvider.isLoading && productProvider.products.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final products = productProvider.products;

        if (products.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.64,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate(
              (final context, final index) {
                return ProductCard(
                  product: products[index],
                  isCompact: true,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.productDetail,
                    arguments: products[index].id,
                  ),
                );
              },
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: ProductCategory.all.length,
                itemBuilder: (final context, final index) {
                  final category = ProductCategory.all[index];
                  return _buildCategoryCard(
                    category,
                    ProductCategory.getIcon(category),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(final String category, final String icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _currentIndex = 0;
        });
        Provider.of<ProductProvider>(context, listen: false)
            .setCategory(category);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              category,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Orders',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer<OrderProvider>(
                builder: (final context, final orderProvider, final child) {
                  if (orderProvider.isLoading && orderProvider.buyerOrders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orders = orderProvider.buyerOrders;

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders yet',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start shopping to see your orders here',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.grey600,
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.currentUser != null) {
                        await orderProvider.fetchBuyerOrders(authProvider.currentUser!.id);
                      }
                    },
                    child: ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (final context, final index) {
                        final order = orders[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order.id.substring(0, 8)}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  _buildOrderStatusChip(order.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${order.items.length} items \u2022 UGX ${order.totalAmount.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.createdAt.toLocal().toString().split('.').first,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey600,
                                    ),
                              ),
                              if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Deliver to: ${order.deliveryAddress}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.grey500,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusChip(final String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        break;
      case 'confirmed':
      case 'processing':
        color = AppColors.info;
        break;
      case 'shipped':
      case 'delivered':
      case 'completed':
        color = AppColors.success;
        break;
      default:
        color = AppColors.grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryGreen,
              child: Text(
                user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? 'Guest User',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: 32),
            _buildProfileMenuItem(
              icon: Icons.person_outlined,
              title: 'Edit Profile',
              onTap: () => Navigator.pushNamed(context, AppRoutes.buyerProfile),
            ),
            _buildProfileMenuItem(
              icon: Icons.location_on_outlined,
              title: 'Delivery Addresses',
              onTap: () => Navigator.pushNamed(context, AppRoutes.deliveryAddresses),
            ),
            _buildProfileMenuItem(
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              onTap: () => Navigator.pushNamed(context, AppRoutes.paymentMethods),
            ),
            _buildProfileMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.notifications),
            ),
            _buildProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => Navigator.pushNamed(context, AppRoutes.helpSupport),
            ),
            _buildProfileMenuItem(
              icon: Icons.info_outlined,
              title: 'About',
              onTap: () => Navigator.pushNamed(context, AppRoutes.about),
            ),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              isDestructive: true,
              onTap: () async {
                await authProvider.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required final IconData icon,
    required final String title,
    required final VoidCallback onTap,
    final bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.grey700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.grey900,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.grey600,
      ),
      onTap: onTap,
    );
  }
}
