import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  int _currentIndex = 0;
  List<FlSpot> _salesChartData = [];
  List<String> _chartDays = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await productProvider.fetchFarmerProducts(authProvider.currentUser!.id);
      await orderProvider.fetchFarmerOrders(authProvider.currentUser!.id);
      _calculateSalesData(orderProvider);
    }
  }

  void _calculateSalesData(final OrderProvider orderProvider) {
    // Get orders from last 7 days
    final now = DateTime.now();
    final salesByDay = <String, double>{};
    final days = <String>[];
    
    // Initialize last 7 days with 0
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = '${date.month}/${date.day}';
      final dayLabel = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      days.add(dayLabel);
      salesByDay[dayKey] = 0;
    }
    
    // Calculate sales for each day
    for (final order in orderProvider.farmerOrders) {
      if (order.status == 'delivered' || order.status == 'completed') {
        final orderDate = order.createdAt;
        final daysSince = now.difference(orderDate).inDays;
        
        if (daysSince < 7) {
          final dayKey = '${orderDate.month}/${orderDate.day}';
          salesByDay[dayKey] = (salesByDay[dayKey] ?? 0) + order.total;
        }
      }
    }
    
    // Convert to chart data
    final spots = <FlSpot>[];
    final maxSale = salesByDay.values.isEmpty ? 100000.0 : salesByDay.values.reduce((final a, final b) => a > b ? a : b);
    var index = 0;
    
    for (final entry in salesByDay.entries) {
      final normalizedValue = maxSale > 0 ? ((entry.value / maxSale) * 6) : 0.0;
      spots.add(FlSpot(index.toDouble(), normalizedValue));
      index++;
    }
    
    setState(() {
      _salesChartData = spots.isEmpty ? [FlSpot.zero] : spots;
      _chartDays = days;
    });
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          _buildProductsTab(),
          _buildOrdersTab(),
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addProduct),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (final index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
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

  Widget _buildDashboardTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.fullName.split(' ').first ?? 'Farmer'}!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your farm products',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey600,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.aiAssistant),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: AppColors.secondaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),


              // Stats Cards
              _buildStatsGrid(),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Sales Chart
              Text(
                'Sales Overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildSalesChart(),
              const SizedBox(height: 24),

              // Recent Orders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Orders',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: const Text('View All'),
                  ),
                ],
              ),
              _buildRecentOrders(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Consumer2<ProductProvider, OrderProvider>(
      builder: (final context, final productProvider, final orderProvider, final child) {
        final products = productProvider.farmerProducts;
        final orders = orderProvider.farmerOrders;
        final pendingOrders = orders.where((final o) => o.status == 'pending').length;
        final totalSales = orders.where((final o) => o.isPaid).fold<double>(0, (final sum, final o) => sum + o.totalAmount);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Products',
              '${products.length}',
              Icons.inventory_2,
              AppColors.primaryGreen,
            ),
            _buildStatCard(
              'Pending Orders',
              '$pendingOrders',
              Icons.pending_actions,
              AppColors.warning,
            ),
            _buildStatCard(
              'Total Orders',
              '${orders.length}',
              Icons.receipt_long,
              AppColors.info,
            ),
            _buildStatCard(
              'Total Sales',
              'UGX ${(totalSales / 1000).toStringAsFixed(0)}K',
              Icons.trending_up,
              AppColors.success,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(final String title, final String value, final IconData icon, final Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Add Product',
            Icons.add_circle_outline,
            AppColors.primaryGreen,
            () => Navigator.pushNamed(context, AppRoutes.addProduct),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'AI Assistant',
            Icons.psychology,
            AppColors.secondaryOrange,
            () => Navigator.pushNamed(context, AppRoutes.aiAssistant),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'Analytics',
            Icons.analytics,
            AppColors.info,
            () => Navigator.pushNamed(context, AppRoutes.farmerAnalytics),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(final String title, final IconData icon, final Color color, final VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _salesChartData.isEmpty
          ? const Center(
              child: Text(
                'No sales data available',
                style: TextStyle(color: AppColors.grey600),
              ),
            )
          : LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (final value, final meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _chartDays.length) {
                          return Text(
                            _chartDays[index],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 7,
                lineBarsData: [
                  LineChartBarData(
                    spots: _salesChartData,
                    isCurved: true,
                    color: AppColors.primaryGreen,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryGreen.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRecentOrders() {
    return Consumer<OrderProvider>(
      builder: (final context, final orderProvider, final child) {
        final orders = orderProvider.farmerOrders.take(3).toList();

        if (orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: orders.map((final order) {
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
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt, color: AppColors.primaryGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.buyerName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${order.items.length} items',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'UGX ${order.totalAmount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primaryGreen,
                                ),
                          ),
                          _buildStatusChip(order.status),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  _buildHistoryRow(order.status),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatusChip(final String status) {
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

  Widget _buildHistoryRow(final String status) {
    const labels = ['Pending', 'Processing', 'Delivered'];
    final currentIndex = _historyStageIndex(status);

    return Row(
      children: labels.asMap().entries.map((final entry) {
        final index = entry.key;
        final label = entry.value;
        final isReached = index <= currentIndex;
        final color = isReached ? AppColors.primaryGreen : AppColors.grey400;

        return Container(
          margin: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              if (isReached)
                Icon(Icons.check, size: 12, color: color)
              else
                Icon(Icons.circle_outlined, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  int _historyStageIndex(final String status) {
    switch (status) {
      case 'pending':
      case 'confirmed':
        return 0;
      case 'processing':
      case 'shipped':
      case 'out_for_delivery':
      case 'in_transit':
        return 1;
      case 'delivered':
      case 'completed':
        return 2;
      default:
        return 0;
    }
  }

  Widget _buildProductsTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Products',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (final context, final productProvider, final child) {
                  final products = productProvider.farmerProducts;

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.grey400),
                          const SizedBox(height: 16),
                          Text(
                            'No products yet',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first product to start selling',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.grey600,
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (final context, final index) {
                      final product = products[index];
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
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.eco, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'UGX ${product.price.toStringAsFixed(0)} / ${product.unit}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${product.availableQuantity.toStringAsFixed(0)} ${product.unit} available',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: product.isAvailable ? AppColors.success : AppColors.error,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.editProduct,
                                arguments: product.id,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
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
              'Orders',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<OrderProvider>(
                builder: (final context, final orderProvider, final child) {
                  final orders = orderProvider.farmerOrders;

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.grey400),
                          const SizedBox(height: 16),
                          Text('No orders yet', style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
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
                                _buildStatusChip(order.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(order.buyerName),
                            Text(
                              '${order.items.length} items • UGX ${order.totalAmount.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'History',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey600,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            _buildHistoryRow(order.status),
                            if (order.isPending) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await orderProvider.cancelOrder(
                                          order.id,
                                          reason: 'Declined by farmer',
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error),
                                      ),
                                      child: const Text('Decline'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await orderProvider.confirmOrder(order.id);
                                      },
                                      child: const Text('Accept'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
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
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryGreen,
                  child: Text(
                    user?.fullName.substring(0, 1).toUpperCase() ?? 'F',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (user?.isVerified ?? false)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(user?.fullName ?? 'Farmer', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 32),
            _buildProfileMenuItem(Icons.person_outlined, 'Edit Profile', () => Navigator.pushNamed(context, AppRoutes.farmerProfile)),
            _buildProfileMenuItem(Icons.psychology_outlined, 'AI Assistant', () => Navigator.pushNamed(context, AppRoutes.aiAssistant)),
            _buildProfileMenuItem(
              Icons.analytics_outlined,
              'Analytics',
              () => Navigator.pushNamed(context, AppRoutes.farmerAnalytics),
            ),
            _buildProfileMenuItem(Icons.help_outline, 'Help & Support', () {
              Navigator.pushNamed(context, AppRoutes.helpSupport);
            }),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              Icons.logout,
              'Logout',
              () async {
                await authProvider.signOut();
                if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(final IconData icon, final String title, final VoidCallback onTap, {final bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.grey700),
      title: Text(title, style: TextStyle(color: isDestructive ? AppColors.error : null)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
