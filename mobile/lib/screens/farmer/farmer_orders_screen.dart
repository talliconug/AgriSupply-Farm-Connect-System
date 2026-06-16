import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/loading_overlay.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _searchQuery = '';
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      if (authProvider.currentUser == null) {
        return;
      }

      await orderProvider.loadFarmerOrders(authProvider.currentUser!.id);
      _hasLoaded = true;
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Orders'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'In Transit'),
            Tab(text: 'Delivered'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (final value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'Search orders...',
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

            // Stats
            _buildOrderStats(),

            // Orders List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(OrderStatus.pending),
                  _buildOrderList(OrderStatus.confirmed),
                  _buildOrderList(OrderStatus.shipped),
                  _buildOrderList(OrderStatus.delivered),
                  _buildOrderList(OrderStatus.cancelled),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStats() {
    return Consumer<OrderProvider>(
      builder: (final context, final provider, final child) {
        final pending = provider.farmerOrders
            .where((final o) => o.status == OrderStatus.pending)
            .length;
        final confirmed = provider.farmerOrders
            .where((final o) => o.status == OrderStatus.confirmed)
            .length;
        final inTransit = provider.farmerOrders
          .where((final o) => o.status == OrderStatus.shipped)
          .length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreen,
                AppColors.primaryGreen.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Pending', pending, Icons.schedule),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem('Confirmed', confirmed, Icons.check_circle),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem('In Transit', inTransit, Icons.local_shipping),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(final String label, final int count, final IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderList(final String status) {
    return Consumer<OrderProvider>(
      builder: (final context, final provider, final child) {
        final orders = provider.farmerOrders
            .where((final o) => o.status == status)
            .where((final o) =>
                (o.orderNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                o.buyerName.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (orders.isEmpty) {
          return _buildEmptyState(status);
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

  Widget _buildEmptyState(final String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No ${status.toLowerCase()} orders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(final OrderModel order) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(order.status),
                    color: _getStatusColor(order.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey600,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Buyer Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.grey200,
                      backgroundImage: order.buyerPhoto != null
                          ? NetworkImage(order.buyerPhoto!)
                          : null,
                      child: order.buyerPhoto == null
                          ? Text(
                              order.buyerName.isNotEmpty
                                  ? order.buyerName[0].toUpperCase()
                                  : 'B',
                              style: const TextStyle(
                                color: AppColors.grey700,
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
                          Text(
                            order.buyerName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            order.buyerPhone ?? 'No phone',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _callBuyer(order.buyerPhone),
                      icon: const Icon(
                        Icons.phone,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Items
                ...order.items.take(3).map((final item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: item.productImage != null
                                ? Image.network(
                                    item.productImage!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 40,
                                    height: 40,
                                    color: AppColors.grey200,
                                    child: const Icon(Icons.image, size: 20),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${item.quantity} ${item.unit}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.grey600),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFormat.format(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )),
                if (order.items.length > 3)
                  Text(
                    '+${order.items.length - 3} more items',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),

                const Divider(height: 24),

                // Total & Delivery
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.grey600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.deliveryAddress ?? 'Unknown',
                          style: const TextStyle(
                            color: AppColors.grey600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: AppColors.grey600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          currencyFormat.format(order.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          if (order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  if (order.status == OrderStatus.pending) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showDeclineDialog(order.id),
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
                        onPressed: () => _acceptOrder(order.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ] else if (order.status == OrderStatus.confirmed) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shipOrder(order.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                        ),
                        icon: const Icon(Icons.local_shipping, size: 18),
                        label: const Text('Start Delivery'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(final String status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.shipped:
        return AppColors.secondaryOrange;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  IconData _getStatusIcon(final String status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(final String status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  void _callBuyer(final String? phone) {
    if (phone == null) return;
    // Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phone...')),
    );
  }

  Future<void> _acceptOrder(final String orderId) async {
    setState(() => _isLoading = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final success = await orderProvider.confirmOrder(orderId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order confirmed'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to confirm order'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to confirm order'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeclineDialog(final String orderId) {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Decline Order'),
        content: const Text(
          'Are you sure you want to decline this order? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _declineOrder(orderId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  Future<void> _declineOrder(final String orderId) async {
    setState(() => _isLoading = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final success = await orderProvider.cancelOrder(
        orderId,
        reason: 'Declined by farmer',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order declined'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Failed to decline order'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to decline order'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _shipOrder(final String orderId) async {
    setState(() => _isLoading = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final success = await orderProvider.shipOrder(orderId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as in transit'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start delivery'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start delivery'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
