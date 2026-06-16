import '../models/order_model.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  Map<String, dynamic> _normalizeOrderPayload(final Map<String, dynamic> raw) {
    return {
      ...raw,
      'items': raw['items'] ?? raw['order_items'] ?? <dynamic>[],
    };
  }

  Map<String, dynamic> _normalizeFarmerOrderPayload(final Map<String, dynamic> raw) {
    final normalized = _normalizeOrderPayload(raw);
    final items = normalized['items'];

    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map<String, dynamic> && first['status'] is String) {
        normalized['status'] = first['status'];
      }
    }

    return normalized;
  }

  // Get orders by buyer
  Future<List<OrderModel>> getOrdersByBuyer(final String buyerId) async {
    try {
      final response = await _apiService.get('/orders', queryParams: {
        'page': '1',
        'limit': '100',
      });
      final list = (response['data'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_normalizeOrderPayload)
          .map(OrderModel.fromJson)
          .toList();

      return list;
    } catch (e) {
      throw Exception('Failed to fetch buyer orders: $e');
    }
  }

  // Get orders by farmer
  Future<List<OrderModel>> getOrdersByFarmer(final String farmerId) async {
    try {
      if (farmerId.isEmpty) {
        return [];
      }

      final response = await _apiService.get('/orders/farmer', queryParams: {
        'page': '1',
        'limit': '100',
      });

      final list = (response['data'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_normalizeFarmerOrderPayload)
          .map(OrderModel.fromJson)
          .toList();

      return list;
    } catch (e) {
      throw Exception('Failed to fetch farmer orders: $e');
    }
  }

  // Get all orders (admin)
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final data = await _apiService.query(
        'orders',
        select: '*, order_items(*, products(*)), users!orders_buyer_id_fkey(full_name, phone)',
        orderBy: 'created_at',
      );

      return data.map(OrderModel.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to fetch all orders: $e');
    }
  }

  // Get order by ID
  Future<OrderModel> getOrderById(final String orderId) async {
    try {
      final response = await _apiService.get('/orders/$orderId');
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Order not found');
      }
      return OrderModel.fromJson(_normalizeOrderPayload(data));
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  // Create new order
  Future<OrderModel> createOrder({
    required final String buyerId,
    required final String deliveryAddress,
    required final String paymentMethod,
    required final List<Map<String, dynamic>> items,
    required final double subtotal,
    required final double deliveryFee,
    required final double total,
    final String? notes,
  }) async {
    try {
      // Prepare order payload
      final orderPayload = {
        'items': items.map((final item) => {
          'productId': item['product_id'],
          'quantity': item['quantity'],
        }).toList(),
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'notes': notes,
      };

      final response = await _apiService.post('/orders', body: orderPayload);
      final data = response['data'] ?? response;
      final order = OrderModel.fromJson(data as Map<String, dynamic>);

      try {
        await _notifyFarmers(items);
      } catch (_) {
        // Ignore notification errors to avoid blocking order creation.
      }

      await _notifyBuyerOrderPlaced(order);

      return order;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(final String orderId, final String status) async {
    try {
      await _apiService.put('/orders/$orderId/status', body: {'status': status});

      try {
        await _apiService.insert('order_status_history', {
          'order_id': orderId,
          'status': status,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // Allow status updates even if history logging fails.
      }

      await _notifyBuyerStatusChange(orderId, status);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Confirm order (farmer)
  Future<void> confirmOrder(final String orderId) async {
    try {
      await _apiService.post('/orders/$orderId/confirm');
    } catch (e) {
      throw Exception('Failed to confirm order: $e');
    }
  }

  // Ship order
  Future<void> shipOrder(final String orderId, {final String? trackingNumber}) async {
    try {
      await _apiService.post(
        '/orders/$orderId/ship',
        body: trackingNumber == null ? null : {'trackingNumber': trackingNumber},
      );
    } catch (e) {
      throw Exception('Failed to ship order: $e');
    }
  }

  // Cancel order
  Future<void> cancelOrder(final String orderId, {final String? reason}) async {
    try {
      await _apiService.post(
        '/orders/$orderId/cancel',
        body: reason == null ? null : {'reason': reason},
      );
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Request refund
  Future<void> requestRefund(final String orderId, {required final String reason}) async {
    try {
      await _apiService.update('orders', orderId, {
        'refund_requested': true,
        'refund_reason': reason,
        'refund_requested_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Notify admin
      await _notifyAdminRefundRequest(orderId, reason);
    } catch (e) {
      throw Exception('Failed to request refund: $e');
    }
  }

  // Process refund (admin)
  Future<void> processRefund(final String orderId, {final bool approved = true}) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (approved) {
        updates['status'] = 'refunded';
        updates['payment_status'] = 'refunded';
        updates['refunded_at'] = DateTime.now().toIso8601String();
      } else {
        updates['refund_requested'] = false;
        updates['refund_denied_at'] = DateTime.now().toIso8601String();
      }

      await _apiService.update('orders', orderId, updates);

      if (approved) {
        await _apiService.insert('order_status_history', {
          'order_id': orderId,
          'status': 'refunded',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  // Add rating and review
  Future<void> addRating(final String orderId, final double rating, {final String? review}) async {
    try {
      await _apiService.update('orders', orderId, {
        'rating': rating,
        'review': review,
        'rated_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(
    final String orderId,
    final String status, {
    final String? transactionId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'payment_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) {
        updates['transaction_id'] = transactionId;
      }

      if (status == PaymentStatus.paid) {
        updates['paid_at'] = DateTime.now().toIso8601String();
      }

      await _apiService.update('orders', orderId, updates);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Get order status history
  Future<List<Map<String, dynamic>>> getStatusHistory(final String orderId) async {
    try {
      final data = await _apiService.query(
        'order_status_history',
        filters: {'order_id': orderId},
        orderBy: 'created_at',
        ascending: true,
      );

      return data.map((final json) => json).toList();
    } catch (e) {
      throw Exception('Failed to fetch status history: $e');
    }
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStats({
    final String? farmerId,
    final String? buyerId,
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    try {
      final params = <String, String>{};
      
      if (farmerId != null) params['farmer_id'] = farmerId;
      if (buyerId != null) params['buyer_id'] = buyerId;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final response = await _apiService.get('/orders/stats', queryParams: params);
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch order stats: $e');
    }
  }

  // Helper methods
  String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(5);
    return 'AGR-$timestamp';
  }

  Future<void> _notifyFarmers(final List<Map<String, dynamic>> items) async {
    // Group items by farmer
    final farmerItems = <String, List<Map<String, dynamic>>>{};
    
    for (final item in items) {
      final farmerId = item['farmer_id'] as String;
      if (farmerItems.containsKey(farmerId)) {
        farmerItems[farmerId]!.add(item);
      } else {
        farmerItems[farmerId] = [item];
      }
    }

    // Send notification to each farmer
    for (final farmerId in farmerItems.keys) {
      try {
        await _apiService.insert('notifications', {
          'user_id': farmerId,
          'type': 'new_order',
          'title': 'New Order Received',
          'message': 'You have received a new order with ${farmerItems[farmerId]!.length} item(s)',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // RLS may block client-side inserts for other users.
      }
    }
  }

  Future<void> _notifyBuyerOrderPlaced(final OrderModel order) async {
    try {
      final orderLabel = order.orderNumber ?? order.id.substring(0, 8);
      await _apiService.insert('notifications', {
        'user_id': order.buyerId,
        'type': 'order_placed',
        'title': 'Order Placed',
        'message': 'Your order #$orderLabel has been received and is pending confirmation',
        'data': {'order_id': order.id},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Silent fail for notifications.
    }
  }

  Future<void> _notifyBuyerStatusChange(final String orderId, final String status) async {
    try {
      final order = await getOrderById(orderId);
      
      String title;
      String body;

      if (status == OrderStatus.confirmed) {
        title = 'Order Confirmed';
        body = 'Your order #${order.orderNumber} has been confirmed by the farmer';
      } else if (status == OrderStatus.processing) {
        title = 'Order Processing';
        body = 'Your order #${order.orderNumber} is being prepared';
      } else if (status == OrderStatus.shipped) {
        title = 'Order Shipped';
        body = 'Your order #${order.orderNumber} has been shipped';
      } else if (status == OrderStatus.inTransit) {
        title = 'Order In Transit';
        body = 'Your order #${order.orderNumber} is on the way';
      } else if (status == OrderStatus.delivered) {
        title = 'Order Delivered';
        body = 'Your order #${order.orderNumber} has been delivered';
      } else if (status == OrderStatus.cancelled) {
        title = 'Order Cancelled';
        body = 'Your order #${order.orderNumber} has been cancelled';
      } else {
        return;
      }

      await _apiService.insert('notifications', {
        'user_id': order.buyerId,
        'type': 'order_update',
        'title': title,
        'message': body,
        'data': {'order_id': orderId},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail for notifications
    }
  }

  Future<void> _notifyAdminRefundRequest(final String orderId, final String reason) async {
    try {
      // Get admin users
      final admins = await _apiService.query(
        'users',
        filters: {'role': 'admin'},
      );

      for (final admin in admins) {
        await _apiService.insert('notifications', {
          'user_id': admin['id'],
          'type': 'refund_request',
          'title': 'Refund Request',
          'message': 'A refund has been requested for order #$orderId: $reason',
          'data': {'order_id': orderId},
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _restoreProductQuantities(final String orderId) async {
    try {
      final items = await _apiService.query(
        'order_items',
        filters: {'order_id': orderId},
      );

      for (final item in items) {
        final product = await _apiService.getById('products', item['product_id'] as String);
        if (product != null) {
          await _apiService.update('products', product['id'] as String, {
            'available_quantity': (product['available_quantity'] as num) + (item['quantity'] as num),
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      // Silent fail
    }
  }
}
