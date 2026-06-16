import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    await orderProvider.fetchBuyerOrders(authProvider.currentUser!.id);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasLoaded = true;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!_hasLoaded && authProvider.currentUser != null && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
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
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(['pending', 'confirmed', 'processing', 'shipped', 'out_for_delivery', 'in_transit']),
                _buildOrdersList(['delivered', 'completed']),
                _buildOrdersList(['cancelled']),
              ],
            ),
    );
  }

  Widget _buildOrdersList(final List<String> statuses) {
    return Consumer<OrderProvider>(
      builder: (final context, final orderProvider, final child) {
        final orders = orderProvider.buyerOrders
            .where((final order) => statuses.contains(order.status))
            .toList();

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
                  'No orders found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your orders will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey600,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (final context, final index) {
              return _buildOrderCard(orders[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(final OrderModel order) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.orderTracking,
        arguments: order.id,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(order.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'History',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _buildHistoryRow(order.status),
            const Divider(height: 24),
            ...order.items.take(2).map((final item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.quantity} ${item.unit}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            if (order.items.length > 2)
              Text(
                '+${order.items.length - 2} more items',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryGreen,
                    ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'UGX ${order.totalAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      order.isPaid ? Icons.check_circle : Icons.pending,
                      size: 16,
                      color: order.isPaid ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.isPaid ? 'Paid' : 'Pending',
                      style: TextStyle(
                        color: order.isPaid ? AppColors.success : AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (order.isPending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelOrder(order.id),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancel Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
        color = AppColors.primaryGreen;
        break;
      case 'delivered':
      case 'completed':
        color = AppColors.success;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      default:
        color = AppColors.grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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

  Future<void> _cancelOrder(final String orderId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProvider.cancelOrder(
      orderId,
      reason: 'Cancelled by buyer',
    );
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Failed to cancel order'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
