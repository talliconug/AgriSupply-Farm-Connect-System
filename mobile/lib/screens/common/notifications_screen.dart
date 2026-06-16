import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/loading_overlay.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      if (userId != null) {
        await notificationProvider.fetchNotifications(userId);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (final context) => [
                const PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 18),
                      SizedBox(width: 12),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, size: 18),
                      SizedBox(width: 12),
                      Text('Clear all'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 18),
                      SizedBox(width: 12),
                      Text('Settings'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Consumer<NotificationProvider>(
          builder: (final context, final provider, final child) {
            if (provider.notifications.isEmpty) {
              return _buildEmptyState();
            }

            // Group notifications by date
            final grouped = _groupNotificationsByDate(provider.notifications);

            return RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: grouped.length,
                itemBuilder: (final context, final index) {
                  final entry = grouped.entries.elementAt(index);
                  return _buildDateGroup(entry.key, entry.value);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.grey700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
        ],
      ),
    );
  }

  Map<String, List<NotificationModel>> _groupNotificationsByDate(
      final List<NotificationModel> notifications) {
    final grouped = <String, List<NotificationModel>>{};

    for (final notification in notifications) {
      final dateKey = _getDateKey(notification.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }

    return grouped;
  }

  String _getDateKey(final DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  Widget _buildDateGroup(final String date, final List<NotificationModel> notifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            date,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.grey600,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...notifications.map(_buildNotificationCard),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNotificationCard(final NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (final direction) {
        final provider =
            Provider.of<NotificationProvider>(context, listen: false);
        provider.deleteNotification(notification.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Undo delete
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: notification.isRead
                  ? null
                  : Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey600,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(final String type) {
    if (type == NotificationType.orderUpdate ||
        type == 'new_order' ||
        type == 'order_placed' ||
        type.startsWith('order_')) {
      return Icons.shopping_bag;
    }

    if (type == 'payment_received' ||
        type == 'payment_failed' ||
        type.startsWith('payment_')) {
      return Icons.payment;
    }

    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.delivery:
        return Icons.local_shipping;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.message:
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(final String type) {
    if (type == NotificationType.orderUpdate ||
        type == 'new_order' ||
        type == 'order_placed' ||
        type.startsWith('order_')) {
      return AppColors.primaryGreen;
    }

    if (type == 'payment_received' ||
        type == 'payment_failed' ||
        type.startsWith('payment_')) {
      return AppColors.success;
    }

    switch (type) {
      case NotificationType.order:
        return AppColors.primaryGreen;
      case NotificationType.payment:
        return AppColors.success;
      case NotificationType.delivery:
        return AppColors.info;
      case NotificationType.promotion:
        return AppColors.secondaryOrange;
      case NotificationType.system:
        return AppColors.warning;
      case NotificationType.message:
        return AppColors.info;
      default:
        return AppColors.grey600;
    }
  }

  String _formatTime(final DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('hh:mm a').format(time);
    }
  }

  void _handleNotificationTap(final NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      provider.markAsRead(notification.id);
    }

    // Navigate based on notification type
    final actionUrl = notification.data?['action_url'] as String?;
    if (actionUrl != null) {
      // Navigate to specific screen
      Navigator.pushNamed(context, actionUrl);
    }
  }

  Future<void> _handleMenuAction(final String action) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';

    switch (action) {
      case 'read_all':
        await provider.markAllAsRead(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'settings':
        _showNotificationSettings();
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<NotificationProvider>(context, listen: false);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final userId = authProvider.currentUser?.id ?? '';
              await provider.clearAllNotifications(userId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications cleared'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child:
                const Text('Clear All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (final context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSettingsTile(
              title: 'Order Updates',
              subtitle: 'Get notified about order status changes',
              value: true,
            ),
            _buildSettingsTile(
              title: 'Promotions',
              subtitle: 'Receive promotional offers and discounts',
              value: true,
            ),
            _buildSettingsTile(
              title: 'Messages',
              subtitle: 'Get notified about new messages',
              value: true,
            ),
            _buildSettingsTile(
              title: 'System Updates',
              subtitle: 'Important system notifications',
              value: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required final String title,
    required final String subtitle,
    required final bool value,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.grey600),
      ),
      value: value,
      onChanged: (final newValue) {
        // Handle settings change
      },
      activeThumbColor: AppColors.primaryGreen,
    );
  }
}
