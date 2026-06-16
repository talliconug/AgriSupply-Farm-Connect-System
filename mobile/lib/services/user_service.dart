import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  // Get all users (admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final data = await _apiService.query(
        'users',
        orderBy: 'created_at',
      );

      return data.map(UserModel.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Get farmers
  Future<List<UserModel>> getFarmers({final String? region}) async {
    try {
      final filters = <String, dynamic>{'role': 'farmer'};
      if (region != null) filters['region'] = region;

      final data = await _apiService.query(
        'users',
        filters: filters,
        orderBy: 'created_at',
      );

      return data.map(UserModel.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to fetch farmers: $e');
    }
  }

  // Get buyers
  Future<List<UserModel>> getBuyers() async {
    try {
      final data = await _apiService.query(
        'users',
        filters: {'role': 'buyer'},
        orderBy: 'created_at',
      );

      return data.map(UserModel.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to fetch buyers: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(final String userId) async {
    try {
      final data = await _apiService.getById('users', userId);
      if (data != null) {
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(final String query) async {
    try {
      final response = await _apiService.get(
        '/users/search',
        queryParams: {'q': query},
      );

      final data = (response['data'] ?? response) as List<dynamic>;
      return data.map((final json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Verify user (admin)
  Future<void> verifyUser(final String userId) async {
    try {
      await _apiService.post('/admin/users/$userId/verify');
    } catch (e) {
      throw Exception('Failed to verify user: $e');
    }
  }

  // Suspend user (admin)
  Future<void> suspendUser(final String userId, {final String? reason}) async {
    try {
      await _apiService.post('/admin/users/$userId/suspend', body: {'reason': reason});
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  // Unsuspend user (admin)
  Future<void> unsuspendUser(final String userId) async {
    try {
      await _apiService.post('/admin/users/$userId/unsuspend');
    } catch (e) {
      throw Exception('Failed to unsuspend user: $e');
    }
  }

  // Delete user (admin)
  Future<void> deleteUser(final String userId) async {
    try {
      await _apiService.delete('/admin/users/$userId');
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Update user role (admin)
  Future<void> updateUserRole(final String userId, final String newRole) async {
    try {
      await _apiService.put('/admin/users/$userId', body: {'role': newRole});
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Get user statistics (for admin dashboard)
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final users = await getAllUsers();

      final totalUsers = users.length;
      final farmers = users.where((final u) => u.role == UserRole.farmer).length;
      final buyers = users.where((final u) => u.role == UserRole.buyer).length;
      final admins = users.where((final u) => u.role == UserRole.admin).length;
      final verified = users.where((final u) => u.isVerified).length;
      const premium = 0; // Premium feature tracking not implemented yet
      final suspended = users.where((final u) => u.isSuspended).length;

      // Users by region
      final byRegion = <String, int>{};
      for (final user in users) {
        if (user.region != null) {
          byRegion[user.region!] = (byRegion[user.region!] ?? 0) + 1;
        }
      }

      // New users this month
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);
      final newThisMonth = users
          .where((final u) => u.createdAt.isAfter(thisMonth))
          .length;

      return {
        'total_users': totalUsers,
        'farmers': farmers,
        'buyers': buyers,
        'admins': admins,
        'verified': verified,
        'premium': premium,
        'suspended': suspended,
        'by_region': byRegion,
        'new_this_month': newThisMonth,
      };
    } catch (e) {
      throw Exception('Failed to get user statistics: $e');
    }
  }

  // Get farmer profile with products and ratings
  Future<Map<String, dynamic>> getFarmerProfile(final String farmerId) async {
    try {
      final user = await getUserById(farmerId);
      if (user == null) throw Exception('Farmer not found');

      // Get products
      final products = await _apiService.query(
        'products',
        filters: {'farmer_id': farmerId, 'status': 'active'},
        limit: 10,
      );

      // Get orders
      final orders = await _apiService.query(
        'order_items',
        filters: {'farmer_id': farmerId},
      );

      // Get reviews
      final reviews = await _apiService.query(
        'orders',
        filters: {'farmer_id': farmerId},
        select: 'rating, review, created_at, users(full_name, photo_url)',
      );

      // Calculate average rating
      final ratings = reviews
          .where((final r) => r['rating'] != null)
          .map((final r) => (r['rating'] as num).toDouble())
          .toList();
      
      final avgRating = ratings.isNotEmpty
          ? ratings.reduce((final a, final b) => a + b) / ratings.length
          : 0.0;

      return {
        'user': user.toJson(),
        'products': products,
        'total_products': products.length,
        'total_orders': orders.length,
        'average_rating': avgRating,
        'total_reviews': ratings.length,
        'reviews': reviews.take(5).toList(),
      };
    } catch (e) {
      throw Exception('Failed to get farmer profile: $e');
    }
  }

  // Follow farmer
  Future<void> followFarmer(final String userId, final String farmerId) async {
    try {
      await _apiService.post('/users/farmers/$farmerId/follow');
    } catch (e) {
      throw Exception('Failed to follow farmer: $e');
    }
  }

  // Unfollow farmer
  Future<void> unfollowFarmer(final String userId, final String farmerId) async {
    try {
      await _apiService.delete('/users/farmers/$farmerId/follow');
    } catch (e) {
      throw Exception('Failed to unfollow farmer: $e');
    }
  }

  // Check if following farmer
  Future<bool> isFollowingFarmer(final String userId, final String farmerId) async {
    try {
      final followers = await _apiService.query(
        'farmer_followers',
        filters: {'user_id': userId, 'farmer_id': farmerId},
        limit: 1,
      );
      return followers.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get followers count
  Future<int> getFollowersCount(final String farmerId) async {
    try {
      final followers = await _apiService.query(
        'farmer_followers',
        filters: {'farmer_id': farmerId},
      );
      return followers.length;
    } catch (e) {
      return 0;
    }
  }

  // Helper methods
  Future<void> _deleteUserData(final String userId) async {
    // Delete products
    final products = await _apiService.query(
      'products',
      filters: {'farmer_id': userId},
    );
    for (final product in products) {
      await _apiService.deleteRecord('products', product['id'] as String);
    }

    // Delete notifications
    final notifications = await _apiService.query(
      'notifications',
      filters: {'user_id': userId},
    );
    for (final notification in notifications) {
      await _apiService.deleteRecord('notifications', notification['id'] as String);
    }

    // Delete chat sessions
    final sessions = await _apiService.query(
      'ai_chat_sessions',
      filters: {'user_id': userId},
    );
    for (final session in sessions) {
      await _apiService.deleteRecord('ai_chat_sessions', session['id'] as String);
    }
  }

  Future<void> _sendVerificationNotification(final String userId) async {
    try {
      await _apiService.insert('notifications', {
        'user_id': userId,
        'type': 'account',
        'title': 'Account Verified',
          'message': 'Congratulations! Your account has been verified. You now have access to all features.',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _sendSuspensionNotification(final String userId, final String? reason) async {
    try {
      await _apiService.insert('notifications', {
        'user_id': userId,
        'type': 'account',
        'title': 'Account Suspended',
          'message': reason ?? 'Your account has been suspended. Please contact support for more information.',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _sendUnsuspensionNotification(final String userId) async {
    try {
      await _apiService.insert('notifications', {
        'user_id': userId,
        'type': 'account',
        'title': 'Account Restored',
          'message': 'Your account has been restored. You can now access all features again.',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _sendPremiumNotification(final String userId) async {
    try {
      await _apiService.insert('notifications', {
        'user_id': userId,
        'type': 'account',
        'title': 'Welcome to Premium!',
          'message': 'You now have access to all premium features including AI assistance and advanced analytics.',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail
    }
  }
}
