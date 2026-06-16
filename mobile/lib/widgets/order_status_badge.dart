import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/order_model.dart';

class OrderStatusBadge extends StatelessWidget {

  const OrderStatusBadge({
    required this.status, super.key,
    this.isLarge = false,
    this.showIcon = true,
  });
  final String status;
  final bool isLarge;
  final bool showIcon;

  @override
  Widget build(final BuildContext context) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
        border: Border.all(
          color: statusInfo.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              statusInfo.icon,
              size: isLarge ? 16 : 12,
              color: statusInfo.color,
            ),
            SizedBox(width: isLarge ? 6 : 4),
          ],
          Text(
            statusInfo.label,
            style: TextStyle(
              fontSize: isLarge ? 13 : 11,
              fontWeight: FontWeight.w600,
              color: statusInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(final String status) {
    if (status == OrderStatus.pending) {
      return _StatusInfo(
        label: 'Pending',
        color: AppColors.warning,
        icon: Icons.schedule,
      );
    } else if (status == OrderStatus.confirmed) {
      return _StatusInfo(
        label: 'Confirmed',
        color: AppColors.info,
        icon: Icons.check_circle_outline,
      );
    } else if (status == OrderStatus.processing) {
      return _StatusInfo(
        label: 'Processing',
        color: AppColors.secondaryOrange,
        icon: Icons.autorenew,
      );
    } else if (status == OrderStatus.shipped) {
      return _StatusInfo(
        label: 'Shipped',
        color: AppColors.primaryGreen,
        icon: Icons.local_shipping,
      );
    } else if (status == OrderStatus.inTransit) {
      return _StatusInfo(
        label: 'In Transit',
        color: AppColors.primaryGreen,
        icon: Icons.delivery_dining,
      );
    } else if (status == OrderStatus.delivered) {
      return _StatusInfo(
        label: 'Delivered',
        color: AppColors.success,
        icon: Icons.check_circle,
      );
    } else if (status == OrderStatus.cancelled) {
      return _StatusInfo(
        label: 'Cancelled',
        color: AppColors.error,
        icon: Icons.cancel,
      );
    } else if (status == OrderStatus.refunded) {
      return _StatusInfo(
        label: 'Refunded',
        color: AppColors.grey600,
        icon: Icons.undo,
      );
    } else {
      return _StatusInfo(
        label: status,
        color: AppColors.grey600,
        icon: Icons.help_outline,
      );
    }
  }
}

class _StatusInfo {

  _StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
  final String label;
  final Color color;
  final IconData icon;
}

class OrderStatusTimeline extends StatelessWidget {

  const OrderStatusTimeline({
    required this.currentStatus, super.key,
    this.statusDates,
    this.isVertical = true,
  });
  final String currentStatus;
  final Map<String, DateTime>? statusDates;
  final bool isVertical;

  static final List<String> _normalFlow = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.inTransit,
    OrderStatus.delivered,
  ];

  @override
  Widget build(final BuildContext context) {
    if (currentStatus == OrderStatus.cancelled ||
        currentStatus == OrderStatus.refunded) {
      return _buildCancelledTimeline(context);
    }

    final currentIndex = _normalFlow.indexOf(currentStatus);

    if (isVertical) {
      return Column(
        children: List.generate(_normalFlow.length, (final index) {
          final status = _normalFlow[index];
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;
          final isLast = index == _normalFlow.length - 1;

          return _TimelineItem(
            status: status,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: isLast,
            date: statusDates?[status],
          );
        }),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_normalFlow.length, (final index) {
          final status = _normalFlow[index];
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;
          final isLast = index == _normalFlow.length - 1;

          return _HorizontalTimelineItem(
            status: status,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: isLast,
            date: statusDates?[status],
          );
        }),
      ),
    );
  }

  Widget _buildCancelledTimeline(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentStatus == OrderStatus.cancelled
            ? AppColors.error.withOpacity(0.1)
            : AppColors.grey200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            currentStatus == OrderStatus.cancelled
                ? Icons.cancel
                : Icons.undo,
            color: currentStatus == OrderStatus.cancelled
                ? AppColors.error
                : AppColors.grey600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStatus == OrderStatus.cancelled
                      ? 'Order Cancelled'
                      : 'Order Refunded',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: currentStatus == OrderStatus.cancelled
                        ? AppColors.error
                        : AppColors.grey700,
                  ),
                ),
                if (statusDates?[currentStatus] != null)
                  Text(
                    _formatDate(statusDates![currentStatus]!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(final DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(final DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

class _TimelineItem extends StatelessWidget {

  const _TimelineItem({
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    this.date,
  });
  final String status;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final DateTime? date;

  @override
  Widget build(final BuildContext context) {
    final statusInfo = _getStatusInfo();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? statusInfo.color
                      : AppColors.grey200,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: statusInfo.color.withOpacity(0.3),
                          width: 3,
                        )
                      : null,
                ),
                child: Icon(
                  isCompleted ? Icons.check : statusInfo.icon,
                  size: 12,
                  color: isCompleted ? Colors.white : AppColors.grey400,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? statusInfo.color : AppColors.grey200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusInfo.label,
                    style: TextStyle(
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCompleted ? AppColors.grey900 : AppColors.grey400,
                    ),
                  ),
                  if (date != null)
                    Text(
                      _formatDate(date!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  if (isCurrent)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        statusInfo.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfoExtended _getStatusInfo() {
    if (status == OrderStatus.pending) {
      return _StatusInfoExtended(
        label: 'Order Placed',
        color: AppColors.warning,
        icon: Icons.receipt_long,
        description: 'Your order has been placed and is awaiting confirmation',
      );
    } else if (status == OrderStatus.confirmed) {
      return _StatusInfoExtended(
        label: 'Order Confirmed',
        color: AppColors.info,
        icon: Icons.check_circle_outline,
        description: 'The farmer has confirmed your order',
      );
    } else if (status == OrderStatus.processing) {
      return _StatusInfoExtended(
        label: 'Processing',
        color: AppColors.secondaryOrange,
        icon: Icons.inventory,
        description: 'Your order is being prepared for shipping',
      );
    } else if (status == OrderStatus.shipped) {
      return _StatusInfoExtended(
        label: 'Shipped',
        color: AppColors.primaryGreen,
        icon: Icons.local_shipping,
        description: 'Your order has been shipped',
      );
    } else if (status == OrderStatus.inTransit) {
      return _StatusInfoExtended(
        label: 'In Transit',
        color: AppColors.primaryGreen,
        icon: Icons.delivery_dining,
        description: 'Your order is on the way to the delivery address',
      );
    } else if (status == OrderStatus.delivered) {
      return _StatusInfoExtended(
        label: 'Delivered',
        color: AppColors.success,
        icon: Icons.check_circle,
        description: 'Your order has been delivered successfully',
      );
    } else {
      return _StatusInfoExtended(
        label: 'Unknown',
        color: AppColors.grey400,
        icon: Icons.help_outline,
        description: '',
      );
    }
  }

  String _formatDate(final DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day} at ${_formatTime(date)}';
  }

  String _formatTime(final DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

class _StatusInfoExtended {

  _StatusInfoExtended({
    required this.label,
    required this.color,
    required this.icon,
    required this.description,
  });
  final String label;
  final Color color;
  final IconData icon;
  final String description;
}

class _HorizontalTimelineItem extends StatelessWidget {

  const _HorizontalTimelineItem({
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    this.date,
  });
  final String status;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final DateTime? date;

  @override
  Widget build(final BuildContext context) {
    final statusInfo = _getStatusInfo();

    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? statusInfo.color : AppColors.grey200,
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(
                        color: statusInfo.color.withOpacity(0.3),
                        width: 3,
                      )
                    : null,
              ),
              child: Icon(
                isCompleted ? Icons.check : statusInfo.icon,
                size: 16,
                color: isCompleted ? Colors.white : AppColors.grey400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusInfo.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCompleted ? AppColors.grey900 : AppColors.grey400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        if (!isLast)
          Container(
            width: 40,
            height: 2,
            margin: const EdgeInsets.only(bottom: 24),
            color: isCompleted ? statusInfo.color : AppColors.grey200,
          ),
      ],
    );
  }

  _StatusInfoExtended _getStatusInfo() {
    if (status == OrderStatus.pending) {
      return _StatusInfoExtended(
        label: 'Placed',
        color: AppColors.warning,
        icon: Icons.receipt_long,
        description: '',
      );
    } else if (status == OrderStatus.confirmed) {
      return _StatusInfoExtended(
        label: 'Confirmed',
        color: AppColors.info,
        icon: Icons.check_circle_outline,
        description: '',
      );
    } else if (status == OrderStatus.processing) {
      return _StatusInfoExtended(
        label: 'Processing',
        color: AppColors.secondaryOrange,
        icon: Icons.inventory,
        description: '',
      );
    } else if (status == OrderStatus.shipped) {
      return _StatusInfoExtended(
        label: 'Shipped',
        color: AppColors.primaryGreen,
        icon: Icons.local_shipping,
        description: '',
      );
    } else if (status == OrderStatus.inTransit) {
      return _StatusInfoExtended(
        label: 'In Transit',
        color: AppColors.primaryGreen,
        icon: Icons.delivery_dining,
        description: '',
      );
    } else if (status == OrderStatus.delivered) {
      return _StatusInfoExtended(
        label: 'Delivered',
        color: AppColors.success,
        icon: Icons.check_circle,
        description: '',
      );
    } else {
      return _StatusInfoExtended(
        label: 'Unknown',
        color: AppColors.grey400,
        icon: Icons.help_outline,
        description: '',
      );
    }
  }
}

class PaymentStatusBadge extends StatelessWidget {

  const PaymentStatusBadge({
    required this.status, super.key,
    this.isLarge = false,
  });
  final PaymentStatus status;
  final bool isLarge;

  @override
  Widget build(final BuildContext context) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            size: isLarge ? 16 : 12,
            color: statusInfo.color,
          ),
          SizedBox(width: isLarge ? 6 : 4),
          Text(
            statusInfo.label,
            style: TextStyle(
              fontSize: isLarge ? 13 : 11,
              fontWeight: FontWeight.w600,
              color: statusInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(final PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return _StatusInfo(
          label: 'Pending',
          color: AppColors.warning,
          icon: Icons.schedule,
        );
      case PaymentStatus.processing:
        return _StatusInfo(
          label: 'Processing',
          color: AppColors.info,
          icon: Icons.autorenew,
        );
      case PaymentStatus.completed:
        return _StatusInfo(
          label: 'Paid',
          color: AppColors.success,
          icon: Icons.check_circle,
        );
      case PaymentStatus.failed:
        return _StatusInfo(
          label: 'Failed',
          color: AppColors.error,
          icon: Icons.error,
        );
      case PaymentStatus.refunded:
        return _StatusInfo(
          label: 'Refunded',
          color: AppColors.grey600,
          icon: Icons.undo,
        );
      default:
        return _StatusInfo(
          label: 'Unknown',
          color: AppColors.grey400,
          icon: Icons.help_outline,
        );
    }
  }
}
