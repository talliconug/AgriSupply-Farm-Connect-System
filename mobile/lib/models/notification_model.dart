class NotificationModel {

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt, this.data,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(final Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: (json['body'] ?? json['message'] ?? '') as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // order, product, payment, promotion, system
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'message': body,
      'type': type,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    final String? id,
    final String? userId,
    final String? title,
    final String? body,
    final String? type,
    final Map<String, dynamic>? data,
    final bool? isRead,
    final DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationType {
  static const String order = 'order';
  static const String product = 'product';
  static const String payment = 'payment';
  static const String promotion = 'promotion';
  static const String system = 'system';
  static const String review = 'review';
  static const String ai = 'ai';
  static const String orderUpdate = 'order_update';
  static const String farmingTip = 'farming_tip';
  static const String delivery = 'delivery';
  static const String message = 'message';

  static List<String> get all =>
      [order, product, payment, promotion, system, review, ai, orderUpdate, farmingTip, delivery, message];
}
