import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/loading_overlay.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _adminService = AdminService();

  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'newest';
  DateTimeRange? _dateFilter;

  List<OrderModel> _allOrders = [];
  List<OrderModel> _pendingOrders = [];
  List<OrderModel> _processingOrders = [];
  List<OrderModel> _shippedOrders = [];
  List<OrderModel> _deliveredOrders = [];
  List<OrderModel> _cancelledOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) return;

      final orders = await _adminService.getOrders(limit: 500);

      setState(() {
        _allOrders = orders;
        _pendingOrders = orders.where((final o) => o.status == 'pending').toList();
        _processingOrders = orders.where((final o) => o.status == 'processing').toList();
        _shippedOrders = orders.where((final o) => o.status == 'shipped').toList();
        _deliveredOrders = orders.where((final o) => o.status == 'delivered').toList();
        _cancelledOrders = orders.where((final o) => o.status == 'cancelled').toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<OrderModel> get _currentOrders {
    List<OrderModel> orders;
    switch (_tabController.index) {
      case 0:
        orders = _allOrders;
        break;
      case 1:
        orders = _pendingOrders;
        break;
      case 2:
        orders = _processingOrders;
        break;
      case 3:
        orders = _shippedOrders;
        break;
      case 4:
        orders = _deliveredOrders;
        break;
      case 5:
        orders = _cancelledOrders;
        break;
      default:
        orders = _allOrders;
    }

    return _filterAndSort(orders);
  }

  List<OrderModel> _filterAndSort(final List<OrderModel> orders) {
    final filtered = orders.where((final order) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!order.id.toLowerCase().contains(query) &&
            !order.buyerName.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Date filter
      if (_dateFilter != null) {
        if (order.createdAt.isBefore(_dateFilter!.start) ||
            order.createdAt.isAfter(_dateFilter!.end.add(const Duration(days: 1)))) {
          return false;
        }
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
        case 'amount_high':
          return b.totalAmount.compareTo(a.totalAmount);
        case 'amount_low':
          return a.totalAmount.compareTo(b.totalAmount);
        default:
          return 0;
      }
    });

    return filtered;
  }

  Future<void> _updateOrderStatus(final OrderModel order, final String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await _adminService.updateOrderStatus(
        orderId: order.id,
        status: newStatus,
      );

      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showOrderDetails(final OrderModel order) {
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
        builder: (final context, final scrollController) => _OrderDetailsSheet(
          order: order,
          scrollController: scrollController,
          onUpdateStatus: (final status) {
            Navigator.pop(context);
            _updateOrderStatus(order, status);
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
          title: const Text('Order Management'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primaryGreen,
            isScrollable: true,
            tabs: [
              Tab(
                text: 'All',
                icon: Badge(
                  label: Text('${_allOrders.length}'),
                  child: const Icon(Icons.all_inbox_outlined),
                ),
              ),
              Tab(
                text: 'Pending',
                icon: Badge(
                  label: Text('${_pendingOrders.length}'),
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.pending_outlined),
                ),
              ),
              Tab(
                text: 'Processing',
                icon: Badge(
                  label: Text('${_processingOrders.length}'),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.autorenew),
                ),
              ),
              Tab(
                text: 'Shipped',
                icon: Badge(
                  label: Text('${_shippedOrders.length}'),
                  backgroundColor: Colors.purple,
                  child: const Icon(Icons.local_shipping_outlined),
                ),
              ),
              Tab(
                text: 'Delivered',
                icon: Badge(
                  label: Text('${_deliveredOrders.length}'),
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.check_circle_outline),
                ),
              ),
              Tab(
                text: 'Cancelled',
                icon: Badge(
                  label: Text('${_cancelledOrders.length}'),
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
                  hintText: 'Search orders...',
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

            // Statistics Summary
            _buildStatsSummary(),

            // Orders List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(
                  6,
                  (_) => RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: _buildOrdersList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final currentOrders = _currentOrders;
    final totalAmount = currentOrders.fold<double>(
      0,
      (final sum, final order) => sum + order.totalAmount,
    );

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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Orders',
            value: '${currentOrders.length}',
            icon: Icons.receipt_long,
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          _StatItem(
            label: 'Total Value',
            value: 'UGX ${NumberFormat.compact().format(totalAmount)}',
            icon: Icons.payments,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    final orders = _currentOrders;

    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16),
            Text(
              'No orders found',
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
      itemCount: orders.length,
      itemBuilder: (final context, final index) {
        final order = orders[index];
        return _OrderCard(
          order: order,
          onTap: () => _showOrderDetails(order),
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
                  onSelected: (_) {
                    setState(() => _sortBy = 'newest');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Oldest'),
                  selected: _sortBy == 'oldest',
                  onSelected: (_) {
                    setState(() => _sortBy = 'oldest');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Amount: High-Low'),
                  selected: _sortBy == 'amount_high',
                  onSelected: (_) {
                    setState(() => _sortBy = 'amount_high');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Amount: Low-High'),
                  selected: _sortBy == 'amount_low',
                  onSelected: (_) {
                    setState(() => _sortBy = 'amount_low');
                    Navigator.pop(context);
                  },
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
                    _dateFilter = null;
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

class _StatItem extends StatelessWidget {

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(final BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
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
}

class _OrderCard extends StatelessWidget {

  const _OrderCard({
    required this.order,
    required this.onTap,
  });
  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.grey600),
                  const SizedBox(width: 4),
                  Text(
                    order.buyerName,
                    style: const TextStyle(color: AppColors.grey600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.grey600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(order.createdAt),
                    style: const TextStyle(color: AppColors.grey600, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} item(s)',
                    style: const TextStyle(color: AppColors.grey600),
                  ),
                  Text(
                    'UGX ${NumberFormat('#,###').format(order.totalAmount)}',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
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
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.grey600;
    }
  }
}

class _OrderDetailsSheet extends StatelessWidget {

  const _OrderDetailsSheet({
    required this.order,
    required this.scrollController,
    required this.onUpdateStatus,
  });
  final OrderModel order;
  final ScrollController scrollController;
  final void Function(String) onUpdateStatus;

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
              'Order Details',
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

        // Order Info
        _DetailRow(label: 'Order ID', value: order.id),
        _DetailRow(label: 'Buyer', value: order.buyerName),
        _DetailRow(label: 'Status', value: order.status.toUpperCase()),
        _DetailRow(
          label: 'Order Date',
          value: DateFormat('MMM dd, yyyy - HH:mm').format(order.createdAt),
        ),
        _DetailRow(label: 'Payment Method', value: order.paymentMethod),
        _DetailRow(label: 'Payment Status', value: order.paymentStatus),

        const SizedBox(height: 24),
        const Text(
          'Delivery Information',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _DetailRow(label: 'Address', value: order.deliveryAddress ?? 'Not provided'),
        if (order.deliveryNotes != null)
          _DetailRow(label: 'Notes', value: order.deliveryNotes!),

        const SizedBox(height: 24),
        const Text(
          'Order Items',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...order.items.map((final item) => _OrderItemCard(item: item)),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),

        // Pricing
        _PriceRow(label: 'Subtotal', value: order.subtotal),
        _PriceRow(label: 'Delivery Fee', value: order.deliveryFee),
        const SizedBox(height: 8),
        _PriceRow(
          label: 'Total Amount',
          value: order.totalAmount,
          isBold: true,
        ),

        const SizedBox(height: 32),

        // Status Update Buttons
        const Text(
          'Update Order Status',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),

        if (order.status == 'pending') ...[
          ElevatedButton(
            onPressed: () => onUpdateStatus('processing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Mark as Processing'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => onUpdateStatus('cancelled'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Cancel Order'),
          ),
        ],

        if (order.status == 'processing')
          ElevatedButton(
            onPressed: () => onUpdateStatus('shipped'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Mark as Shipped'),
          ),

        if (order.status == 'shipped')
          ElevatedButton(
            onPressed: () => onUpdateStatus('delivered'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Mark as Delivered'),
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
            width: 120,
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

class _OrderItemCard extends StatelessWidget {

  const _OrderItemCard({required this.item});
  final OrderItem item;

  @override
  Widget build(final BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UGX ${NumberFormat('#,###').format(item.price)} × ${item.quantity}',
                    style: const TextStyle(color: AppColors.grey600),
                  ),
                ],
              ),
            ),
            Text(
              'UGX ${NumberFormat('#,###').format(item.totalPrice)}',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });
  final String label;
  final double value;
  final bool isBold;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            'UGX ${NumberFormat('#,###').format(value)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
              color: isBold ? AppColors.primaryGreen : null,
            ),
          ),
        ],
      ),
    );
  }
}
