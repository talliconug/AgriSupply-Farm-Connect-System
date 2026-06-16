import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  Map<String, dynamic> _extractMap(final dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return response;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(final dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final items = data['items'];
        if (items is List) return items;
        for (final key in const ['users', 'products', 'orders', 'results', 'rows']) {
          final value = data[key];
          if (value is List) return value;
        }
      }
      final items = response['items'];
      if (items is List) return items;
      for (final key in const ['users', 'products', 'orders', 'results', 'rows']) {
        final value = response[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _apiService.get('/admin/dashboard');
    return _extractMap(response);
  }

  Future<List<UserModel>> getUsers({
    final String? role,
    final int page = 1,
    final int limit = 100,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (role != null && role.isNotEmpty) {
      params['role'] = role;
    }

    final response = await _apiService.get('/admin/users', queryParams: params);
    final users = _extractList(response);
    return users
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  Future<UserModel> updateUser({
    required final String userId,
    final String? role,
    final bool? isVerified,
    final bool? isPremium,
    final bool? isSuspended,
  }) async {
    final response = await _apiService.put(
      '/admin/users/$userId',
      body: {
        if (role != null) 'role': role,
        if (isVerified != null) 'is_verified': isVerified,
        if (isPremium != null) 'is_premium': isPremium,
        if (isSuspended != null) 'is_suspended': isSuspended,
      },
    );

    return UserModel.fromJson(_extractMap(response));
  }

  Future<UserModel> verifyFarmer(
    final String userId, {
    final bool override = false,
    final String? overrideReason,
  }) async {
    final response = await _apiService.post(
      '/admin/users/$userId/verify',
      body: {
        'override': override,
        if (overrideReason != null && overrideReason.trim().isNotEmpty)
          'overrideReason': overrideReason.trim(),
      },
    );

    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> suspendUser(final String userId, {required final String reason}) async {
    await _apiService.post(
      '/admin/users/$userId/suspend',
      body: {'reason': reason},
    );
  }

  Future<void> unsuspendUser(final String userId) async {
    await _apiService.post('/admin/users/$userId/unsuspend');
  }

  Future<void> deleteUser(final String userId) async {
    await _apiService.delete('/admin/users/$userId');
  }

  Future<List<ProductModel>> getProducts({
    final String? status,
    final String? category,
    final String? search,
    final int page = 1,
    final int limit = 100,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (category != null && category.isNotEmpty) 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _apiService.get('/admin/products', queryParams: params);
    final data = _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(_normalizeProduct)
        .map(ProductModel.fromJson)
        .toList();
    return data;
  }

  Future<void> updateProduct({
    required final String productId,
    final String? status,
    final bool? isFeatured,
    final String? rejectionReason,
  }) async {
    await _apiService.put(
      '/admin/products/$productId',
      body: {
        if (status != null) 'status': status,
        if (isFeatured != null) 'is_featured': isFeatured,
        if (rejectionReason != null && rejectionReason.isNotEmpty)
          'rejection_reason': rejectionReason,
      },
    );
  }

  Future<void> deleteProduct(final String productId) async {
    await _apiService.delete('/admin/products/$productId');
  }

  Future<List<OrderModel>> getOrders({
    final String? status,
    final String? paymentStatus,
    final String? region,
    final int page = 1,
    final int limit = 100,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (paymentStatus != null && paymentStatus.isNotEmpty)
        'payment_status': paymentStatus,
      if (region != null && region.isNotEmpty) 'region': region,
    };

    final response = await _apiService.get('/admin/orders', queryParams: params);
    final data = _extractList(response)
        .whereType<Map<String, dynamic>>()
        .map(_normalizeOrder)
        .map(OrderModel.fromJson)
        .toList();
    return data;
  }

  Future<void> updateOrderStatus({
    required final String orderId,
    required final String status,
    final String? notes,
  }) async {
    await _apiService.put(
      '/admin/orders/$orderId',
      body: {
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<Map<String, dynamic>> getSalesAnalytics({final String period = '30d'}) async {
    final response = await _apiService.get(
      '/admin/analytics/sales',
      queryParams: {'period': period},
    );
    return _extractMap(response);
  }

  Future<Map<String, dynamic>> getUserAnalytics({final String period = '30d'}) async {
    final response = await _apiService.get(
      '/admin/analytics/users',
      queryParams: {'period': period},
    );
    return _extractMap(response);
  }

  Future<Map<String, dynamic>> getProductAnalytics() async {
    final response = await _apiService.get('/admin/analytics/products');
    return _extractMap(response);
  }

  Future<Map<String, dynamic>> getRegionalAnalytics() async {
    final response = await _apiService.get('/admin/analytics/regions');
    return _extractMap(response);
  }

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _apiService.get('/admin/settings');
    return _extractMap(response);
  }

  Future<Map<String, dynamic>> updateSettings(final Map<String, dynamic> settings) async {
    final response = await _apiService.put('/admin/settings', body: settings);
    return _extractMap(response);
  }

  Future<void> sendBroadcast({
    required final String title,
    required final String message,
    final String? targetRole,
    final String? targetRegion,
  }) async {
    await _apiService.post(
      '/admin/notifications/broadcast',
      body: {
        'title': title,
        'message': message,
        if (targetRole != null && targetRole.isNotEmpty) 'targetRole': targetRole,
        if (targetRegion != null && targetRegion.isNotEmpty)
          'targetRegion': targetRegion,
      },
    );
  }

  Map<String, dynamic> _normalizeProduct(final Map<String, dynamic> raw) {
    final farmer = raw['farmer'] as Map<String, dynamic>?;
    return {
      ...raw,
      'farmer_name': raw['farmer_name'] ?? farmer?['full_name'] ?? 'Unknown Farmer',
      'farmer_id': raw['farmer_id'] ?? farmer?['id'] ?? '',
      'quantity_available': raw['quantity_available'] ?? raw['quantity'] ?? 0,
      'available_quantity': raw['available_quantity'] ?? raw['quantity_available'] ?? raw['quantity'] ?? 0,
      'is_organic': raw['is_organic'] ?? false,
      'images': raw['images'] ?? <dynamic>[],
      'rating': raw['rating'] ?? 0,
      'created_at': raw['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': raw['updated_at'] ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _normalizeOrder(final Map<String, dynamic> raw) {
    final buyer = raw['buyer'] as Map<String, dynamic>?;
    final orderItems = (raw['order_items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((final item) => {
              'id': item['id'] ?? '',
              'order_id': item['order_id'] ?? raw['id'] ?? '',
              'product_id': item['product_id'] ?? '',
              'product_name': item['product_name'] ?? item['name'] ?? 'Product',
              'product_image': item['product_image'],
              'farmer_id': item['farmer_id'] ?? '',
              'farmer_name': item['farmer_name'] ?? 'Farmer',
              'price': (item['price'] ?? 0),
              'unit': item['unit'] ?? 'unit',
              'quantity': (item['quantity'] ?? 0),
              'total_price': (item['total_price'] ?? item['price'] ?? 0),
              'status': item['status'] ?? 'pending',
              'farmer_notes': item['farmer_notes'],
            })
        .toList();

    return {
      ...raw,
      'buyer_name': raw['buyer_name'] ?? buyer?['full_name'] ?? 'Buyer',
      'buyer_phone': raw['buyer_phone'] ?? buyer?['phone'],
      'buyer_address': raw['buyer_address'] ?? raw['delivery_address'],
      'items': orderItems,
      'subtotal': raw['subtotal'] ?? raw['total_amount'] ?? 0,
      'delivery_fee': raw['delivery_fee'] ?? 0,
      'total_amount': raw['total_amount'] ?? 0,
      'payment_method': raw['payment_method'] ?? 'mobile_money',
      'created_at': raw['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': raw['updated_at'] ?? DateTime.now().toIso8601String(),
    };
  }
}
