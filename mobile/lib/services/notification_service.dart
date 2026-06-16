import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();
  RealtimeChannel? _subscription;

  // Get all notifications for user
  Future<List<NotificationModel>> getNotifications(final String userId) async {
    try {
      final data = await _apiService.query(
        'notifications',
        filters: {'user_id': userId},
        orderBy: 'created_at',
        limit: 100,
      );

      return data.map(NotificationModel.fromJson).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Mark single notification as read
  Future<void> markAsRead(final String notificationId) async {
    try {
      await _apiService.update('notifications', notificationId, {
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(final String userId) async {
    try {
      // Get all unread notifications
      final notifications = await _apiService.query(
        'notifications',
        filters: {
          'user_id': userId,
          'is_read': false,
        },
      );

      // Update each notification
      for (final notification in notifications) {
        await _apiService.update('notifications', notification['id'] as String, {
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(final String notificationId) async {
    try {
      await _apiService.deleteRecord('notifications', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications(final String userId) async {
    try {
      final notifications = await _apiService.query(
        'notifications',
        filters: {'user_id': userId},
      );

      for (final notification in notifications) {
        await _apiService.deleteRecord('notifications', notification['id'] as String);
      }
    } catch (e) {
      throw Exception('Failed to clear notifications: $e');
    }
  }

  // Create notification
  Future<NotificationModel> createNotification({
    required final String userId,
    required final String type,
    required final String title,
    required final String body,
    final Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = await _apiService.insert('notifications', {
        'user_id': userId,
        'type': type,
        'title': title,
        'message': body,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      return NotificationModel.fromJson(notificationData);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Send notification to multiple users
  Future<void> sendBulkNotification({
    required final List<String> userIds,
    required final String type,
    required final String title,
    required final String body,
    final Map<String, dynamic>? data,
  }) async {
    try {
      for (final userId in userIds) {
        await createNotification(
          userId: userId,
          type: type,
          title: title,
          body: body,
          data: data,
        );
      }
    } catch (e) {
      throw Exception('Failed to send bulk notifications: $e');
    }
  }

  // Subscribe to real-time notifications
  void subscribeToNotifications(
    final String userId, {
    required final Function(NotificationModel) onNewNotification,
  }) {
    _subscription = Supabase.instance.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (final payload) {
            final notification = NotificationModel.fromJson(payload.newRecord);
            onNewNotification(notification);
          },
        )
        .subscribe();
  }

  // Unsubscribe from real-time notifications
  void unsubscribeFromNotifications() {
    if (_subscription != null) {
      Supabase.instance.client.removeChannel(_subscription!);
      _subscription = null;
    }
  }

  // Get notification preferences
  Future<Map<String, bool>> getPreferences(final String userId) async {
    try {
      final data = await _apiService.getById('notification_preferences', userId);
      
      if (data != null) {
        return {
          'order_updates': (data['order_updates'] as bool?) ?? true,
          'new_messages': (data['new_messages'] as bool?) ?? true,
          'promotions': (data['promotions'] as bool?) ?? true,
          'price_alerts': (data['price_alerts'] as bool?) ?? true,
          'farming_tips': (data['farming_tips'] as bool?) ?? true,
        };
      }

      // Return defaults if no preferences found
      return {
        'order_updates': true,
        'new_messages': true,
        'promotions': true,
        'price_alerts': true,
        'farming_tips': true,
      };
    } catch (e) {
      // Return defaults on error
      return {
        'order_updates': true,
        'new_messages': true,
        'promotions': true,
        'price_alerts': true,
        'farming_tips': true,
      };
    }
  }

  // Update notification preferences
  Future<void> updatePreferences({
    required final String userId,
    final bool? orderUpdates,
    final bool? newMessages,
    final bool? promotions,
    final bool? priceAlerts,
    final bool? farmingTips,
  }) async {
    try {
      final updates = <String, dynamic>{
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (orderUpdates != null) updates['order_updates'] = orderUpdates;
      if (newMessages != null) updates['new_messages'] = newMessages;
      if (promotions != null) updates['promotions'] = promotions;
      if (priceAlerts != null) updates['price_alerts'] = priceAlerts;
      if (farmingTips != null) updates['farming_tips'] = farmingTips;

      // Check if preferences exist
      final existing = await _apiService.getById('notification_preferences', userId);
      
      if (existing != null) {
        await _apiService.update('notification_preferences', userId, updates);
      } else {
        updates['created_at'] = DateTime.now().toIso8601String();
        updates['order_updates'] = orderUpdates ?? true;
        updates['new_messages'] = newMessages ?? true;
        updates['promotions'] = promotions ?? true;
        updates['price_alerts'] = priceAlerts ?? true;
        updates['farming_tips'] = farmingTips ?? true;
        await _apiService.insert('notification_preferences', updates);
      }
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  // Send order notification
  Future<void> sendOrderNotification({
    required final String userId,
    required final String orderId,
    required final String orderNumber,
    required final String status,
  }) async {
    String title;
    String body;

    switch (status) {
      case 'confirmed':
        title = 'Order Confirmed';
        body = 'Your order #$orderNumber has been confirmed';
        break;
      case 'shipped':
        title = 'Order Shipped';
        body = 'Your order #$orderNumber is on its way';
        break;
      case 'delivered':
        title = 'Order Delivered';
        body = 'Your order #$orderNumber has been delivered';
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        body = 'Your order #$orderNumber has been cancelled';
        break;
      default:
        title = 'Order Update';
        body = 'Your order #$orderNumber has been updated';
    }

    await createNotification(
      userId: userId,
      type: NotificationType.orderUpdate,
      title: title,
      body: body,
      data: {'order_id': orderId, 'order_number': orderNumber},
    );
  }

  // Send promotion notification
  Future<void> sendPromotionNotification({
    required final List<String> userIds,
    required final String title,
    required final String body,
    final String? imageUrl,
    final String? actionUrl,
  }) async {
    await sendBulkNotification(
      userIds: userIds,
      type: NotificationType.promotion,
      title: title,
      body: body,
      data: {
        'image_url': imageUrl,
        'action_url': actionUrl,
      },
    );
  }

  // Send farming tip notification
  Future<void> sendFarmingTip({
    required final List<String> farmerIds,
    required final String title,
    required final String tip,
  }) async {
    await sendBulkNotification(
      userIds: farmerIds,
      type: NotificationType.farmingTip,
      title: title,
      body: tip,
    );
  }

  // Get unread count
  Future<int> getUnreadCount(final String userId) async {
    try {
      final notifications = await _apiService.query(
        'notifications',
        filters: {
          'user_id': userId,
          'is_read': false,
        },
      );
      return notifications.length;
    } catch (e) {
      return 0;
    }
  }
}
