import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

class OrderTrackingScreen extends StatefulWidget {

  const OrderTrackingScreen({required this.orderId, super.key});
  final String orderId;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  Map<String, DateTime> _statusHistory = {};

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final order = await orderProvider.getOrderById(widget.orderId);
      final history = <String, DateTime>{};

      if (order != null) {
        try {
          final rawHistory = await orderProvider.getStatusHistory(order.id);
          for (final entry in rawHistory) {
            final status = entry['status'] as String?;
            final createdAtRaw = entry['created_at'] as String?;
            if (status == null || createdAtRaw == null) continue;
            final createdAt = DateTime.parse(createdAtRaw);
            final existing = history[status];
            if (existing == null || createdAt.isBefore(existing)) {
              history[status] = createdAt;
            }
          }
        } catch (_) {
          // Ignore history failures and fall back to order timestamps.
        }

        history.putIfAbsent('pending', () => order.createdAt);
        if (order.deliveredAt != null) {
          history.putIfAbsent('delivered', () => order.deliveredAt!);
        }
        if (order.status == 'completed') {
          history.putIfAbsent('completed', () => order.updatedAt);
        }
      }
      setState(() {
        _order = order;
        _statusHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Tracking')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId.substring(0, 8)}'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrder,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 24),
              _buildTrackingTimeline(),
              const SizedBox(height: 24),
              _buildDeliveryInfo(),
              const SizedBox(height: 24),
              _buildOrderItems(),
              const SizedBox(height: 24),
              _buildPaymentSummary(),
              const SizedBox(height: 32),
              if (!_order!.isDelivered && !_order!.isCancelled)
                _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusMessage;

    switch (_order!.status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.pending;
        statusMessage = 'Waiting for confirmation';
        break;
      case 'confirmed':
        statusColor = AppColors.info;
        statusIcon = Icons.check_circle;
        statusMessage = 'Order confirmed by farmer';
        break;
      case 'processing':
        statusColor = AppColors.info;
        statusIcon = Icons.inventory;
        statusMessage = 'Being prepared for delivery';
        break;
      case 'shipped':
        statusColor = AppColors.primaryGreen;
        statusIcon = Icons.local_shipping;
        statusMessage = 'On the way to you';
        break;
      case 'delivered':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusMessage = 'Delivered successfully';
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusMessage = 'Delivered successfully';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusMessage = 'Order was cancelled';
        break;
      default:
        statusColor = AppColors.grey500;
        statusIcon = Icons.help;
        statusMessage = 'Unknown status';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _order!.statusDisplay,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey600,
                      ),
                ),
                if (_order!.estimatedDelivery != null && !_order!.isDelivered)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Est. delivery: ${DateFormat('MMM dd, yyyy').format(_order!.estimatedDelivery!)}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final steps = [
      {'status': 'pending', 'label': 'Order Placed', 'icon': Icons.receipt},
      {'status': 'confirmed', 'label': 'Confirmed', 'icon': Icons.check_circle},
      {'status': 'processing', 'label': 'Processing', 'icon': Icons.inventory},
      {'status': 'shipped', 'label': 'Shipped', 'icon': Icons.local_shipping},
      {'status': 'delivered', 'label': 'Delivered', 'icon': Icons.home},
    ];

    final normalizedStatus = _normalizeStatus(_order!.status);
    var currentIndex = steps.indexWhere((final s) => s['status'] == normalizedStatus);
    if (currentIndex < 0) {
      currentIndex = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Progress',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((final entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;
          final stepStatus = step['status']! as String;
          final stepTimestamp = _getStatusTimestamp(stepStatus);

          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primaryGreen
                          : AppColors.grey300,
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: AppColors.primaryGreen, width: 3)
                          : null,
                    ),
                    child: Icon(
                      step['icon']! as IconData,
                      color: isCompleted ? Colors.white : AppColors.grey500,
                      size: 20,
                    ),
                  ),
                  if (index < steps.length - 1)
                    Container(
                      width: 2,
                      height: 30,
                      color: isCompleted
                          ? AppColors.primaryGreen
                          : AppColors.grey300,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['label']! as String,
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted
                              ? AppColors.grey900
                              : AppColors.grey500,
                        ),
                      ),
                      if (stepTimestamp != null && (isCompleted || isCurrent))
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm')
                              .format(stepTimestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  String _normalizeStatus(final String status) {
    switch (status) {
      case 'out_for_delivery':
      case 'in_transit':
      case 'shipped':
        return 'shipped';
      case 'completed':
        return 'delivered';
      default:
        return status;
    }
  }

  DateTime? _getStatusTimestamp(final String status) {
    switch (status) {
      case 'pending':
        return _statusHistory['pending'] ?? _order?.createdAt;
      case 'shipped':
        return _statusHistory['shipped'] ??
            _statusHistory['in_transit'] ??
            _statusHistory['out_for_delivery'];
      case 'delivered':
        return _statusHistory['delivered'] ??
            _statusHistory['completed'] ??
            _order?.deliveredAt;
      default:
        return _statusHistory[status];
    }
  }

  Widget _buildDeliveryInfo() {
    final hasCoordinates = _order!.deliveryLatitude != null && _order!.deliveryLongitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Information',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (hasCoordinates) ...[
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_order!.deliveryLatitude!, _order!.deliveryLongitude!),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.agrisupply.mobile',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_order!.deliveryLatitude!, _order!.deliveryLongitude!),
                        width: 56,
                        height: 56,
                        child: const Icon(
                          Icons.location_on,
                          size: 42,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.location_on_outlined,
                'Address',
                _order!.deliveryAddress ?? 'Not specified',
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.map_outlined,
                'Region',
                '${_order!.deliveryDistrict}, ${_order!.deliveryRegion}',
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.phone_outlined,
                'Phone',
                _order!.buyerPhone ?? 'Not specified',
              ),
              if (_order!.deliveryNotes != null &&
                  _order!.deliveryNotes!.isNotEmpty) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.note_outlined,
                  'Notes',
                  _order!.deliveryNotes!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(final IconData icon, final String label, final String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.grey600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        ...(_order!.items.map((final item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
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
                          item.productName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${item.quantity} ${item.unit} × UGX ${item.price.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'UGX ${item.totalPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryGreen,
                        ),
                  ),
                ],
              ),
            ))),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Summary',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildPaymentRow('Subtotal', 'UGX ${_order!.subtotal.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              _buildPaymentRow('Delivery Fee', 'UGX ${_order!.deliveryFee.toStringAsFixed(0)}'),
              const Divider(height: 24),
              _buildPaymentRow(
                'Total',
                'UGX ${_order!.totalAmount.toStringAsFixed(0)}',
                isBold: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _order!.isPaid ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: _order!.isPaid ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _order!.isPaid ? 'Paid via ${PaymentMethod.getDisplay(_order!.paymentMethod)}' : 'Payment pending',
                    style: TextStyle(
                      color: _order!.isPaid ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(final String label, final String value, {final bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : null),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.helpSupport),
            child: const Text('Contact Support'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showCancelOrderDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Cancel Order'),
          ),
        ),
      ],
    );
  }

  void _showCancelOrderDialog() {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              final success = await orderProvider.cancelOrder(
                widget.orderId,
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
                  Navigator.pop(context);
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
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }
}
