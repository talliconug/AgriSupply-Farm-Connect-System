import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasNewNotifications = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNewNotifications => _hasNewNotifications;

  int get unreadCount => _notifications.where((final n) => !n.isRead).length;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((final n) => !n.isRead).toList();

  // Group notifications by date
  Map<String, List<NotificationModel>> get groupedNotifications {
    final grouped = <String, List<NotificationModel>>{};
    final now = DateTime.now();

    for (final notification in _notifications) {
      String key;
      final diff = now.difference(notification.createdAt);

      if (diff.inDays == 0) {
        key = 'Today';
      } else if (diff.inDays == 1) {
        key = 'Yesterday';
      } else if (diff.inDays < 7) {
        key = 'This Week';
      } else if (diff.inDays < 30) {
        key = 'This Month';
      } else {
        key = 'Earlier';
      }

      if (grouped.containsKey(key)) {
        grouped[key]!.add(notification);
      } else {
        grouped[key] = [notification];
      }
    }

    return grouped;
  }

  // Fetch notifications for user
  Future<void> fetchNotifications(final String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications(userId);
      _hasNewNotifications = _notifications.any((final n) => !n.isRead);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  // Mark single notification as read
  Future<void> markAsRead(final String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      final index = _notifications.indexWhere((final n) => n.id == notificationId);
      if (index >= 0) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }

      _hasNewNotifications = _notifications.any((final n) => !n.isRead);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(final String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);

      _notifications = _notifications.map((final n) {
        return n.copyWith(isRead: true);
      }).toList();

      _hasNewNotifications = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Delete notification
  Future<void> deleteNotification(final String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _notifications.removeWhere((final n) => n.id == notificationId);
      _hasNewNotifications = _notifications.any((final n) => !n.isRead);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications(final String userId) async {
    try {
      await _notificationService.clearAllNotifications(userId);
      _notifications.clear();
      _hasNewNotifications = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Handle notification tap - navigate based on type
  void onNotificationTap(final NotificationModel notification) {
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    // Return action data for navigation
    // The screen that uses this provider will handle navigation
  }

  // Add new notification (for real-time updates)
  void addNotification(final NotificationModel notification) {
    _notifications.insert(0, notification);
    _hasNewNotifications = true;

    final isCritical = {
      'product',
      'order',
      'order_update',
      'new_order',
      'order_placed',
      'payment',
      'payment_received',
      'payment_failed',
      'review',
      'system',
      'account',
    }.contains(notification.type)
        || notification.type.startsWith('order_')
        || notification.type.startsWith('payment_');

    if (isCritical) {
      LocalNotificationService.showPopup(
        title: notification.title,
        body: notification.body,
      );
    }

    notifyListeners();
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
      await _notificationService.updatePreferences(
        userId: userId,
        orderUpdates: orderUpdates,
        newMessages: newMessages,
        promotions: promotions,
        priceAlerts: priceAlerts,
        farmingTips: farmingTips,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get notifications by type
  List<NotificationModel> getByType(final NotificationType type) {
    return _notifications.where((final n) => n.type == type).toList();
  }

  // Subscribe to real-time notifications
  void subscribeToNotifications(final String userId) {
    _notificationService.subscribeToNotifications(
      userId,
      onNewNotification: (final notification) {
        addNotification(notification);
      },
    );
  }

  // Unsubscribe from real-time notifications
  void unsubscribeFromNotifications() {
    _notificationService.unsubscribeFromNotifications();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
