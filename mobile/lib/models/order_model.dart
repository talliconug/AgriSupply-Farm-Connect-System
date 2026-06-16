
class OrderModel {

  OrderModel({
    required this.id,
    required this.buyerId, required this.buyerName, required this.items, required this.subtotal, required this.deliveryFee, required this.totalAmount, required this.paymentMethod, required this.createdAt, required this.updatedAt, this.orderNumber,
    this.buyerPhone,
    this.buyerAddress,
    this.status = 'pending',
    this.paymentStatus = 'pending',
    this.paymentReference,
    this.deliveryAddress,
    this.deliveryRegion,
    this.deliveryDistrict,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryNotes,
    this.estimatedDelivery,
    this.deliveredAt,
    this.buyerPhoto,
    this.refundRequested = false,
  });

  factory OrderModel.fromJson(final Map<String, dynamic> json) {
    final buyer = json['buyer'] as Map<String, dynamic>?;
    final totalAmountRaw = json['total_amount'] ?? json['total'] ?? 0;
    final paymentMethodRaw = json['payment_method'] ?? json['paymentMethod'] ?? PaymentMethod.mobileMoney;
    final deliveryAddressRaw = json['delivery_address'];

    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String?,
      buyerId: json['buyer_id'] as String,
      buyerName: json['buyer_name'] as String? ?? buyer?['full_name'] as String? ?? 'Buyer',
      buyerPhone: json['buyer_phone'] as String? ?? buyer?['phone'] as String?,
      buyerAddress: json['buyer_address'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((final e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      totalAmount: (totalAmountRaw as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentMethod: paymentMethodRaw as String,
      paymentReference: json['payment_reference'] as String?,
      deliveryAddress: deliveryAddressRaw is String
        ? deliveryAddressRaw
        : (deliveryAddressRaw is Map<String, dynamic>
          ? deliveryAddressRaw['address'] as String?
          : null),
      deliveryRegion: json['delivery_region'] as String?,
      deliveryDistrict: json['delivery_district'] as String?,
      deliveryLatitude:
          json['delivery_latitude'] != null
              ? (json['delivery_latitude'] as num).toDouble()
              : null,
      deliveryLongitude:
          json['delivery_longitude'] != null
              ? (json['delivery_longitude'] as num).toDouble()
              : null,
      deliveryNotes: json['delivery_notes'] as String?,
      estimatedDelivery:
          json['estimated_delivery'] != null
              ? DateTime.parse(json['estimated_delivery'] as String)
              : null,
      deliveredAt:
          json['delivered_at'] != null
              ? DateTime.parse(json['delivered_at'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      buyerPhoto: json['buyer_photo'] as String?,
      refundRequested: json['refund_requested'] as bool? ?? false,
    );
  }
  final String id;
  final String? orderNumber;
  final String buyerId;
  final String buyerName;
  final String? buyerPhone;
  final String? buyerAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String
  status; // pending, confirmed, processing, shipped, delivered, cancelled
  final String paymentStatus; // pending, paid, failed, refunded
  final String paymentMethod; // marzpay, cash_on_delivery
  final String? paymentReference;
  final String? deliveryAddress;
  final String? deliveryRegion;
  final String? deliveryDistrict;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryNotes;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? buyerPhoto;
  final bool refundRequested;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'buyer_address': buyerAddress,
      'items': items.map((final e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total_amount': totalAmount,
      'status': status,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'delivery_address': deliveryAddress,
      'delivery_region': deliveryRegion,
      'delivery_district': deliveryDistrict,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'delivery_notes': deliveryNotes,
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'buyer_photo': buyerPhoto,
      'refund_requested': refundRequested,
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isProcessing => status == 'processing';
  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get isPaid => paymentStatus == 'paid' || paymentStatus == 'completed';

  double get total => totalAmount;

  OrderModel copyWith({
    final String? id,
    final String? orderNumber,
    final String? buyerId,
    final String? buyerName,
    final String? buyerPhone,
    final String? buyerAddress,
    final List<OrderItem>? items,
    final double? subtotal,
    final double? deliveryFee,
    final double? totalAmount,
    final String? status,
    final String? paymentStatus,
    final String? paymentMethod,
    final String? paymentReference,
    final String? deliveryAddress,
    final String? deliveryRegion,
    final String? deliveryDistrict,
    final double? deliveryLatitude,
    final double? deliveryLongitude,
    final String? deliveryNotes,
    final DateTime? estimatedDelivery,
    final DateTime? deliveredAt,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final String? buyerPhoto,
    final bool? refundRequested,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryRegion: deliveryRegion ?? this.deliveryRegion,
      deliveryDistrict: deliveryDistrict ?? this.deliveryDistrict,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      buyerPhoto: buyerPhoto ?? this.buyerPhoto,
      refundRequested: refundRequested ?? this.refundRequested,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'On the way';
      case 'out_for_delivery':
      case 'in_transit':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class OrderItem {

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.farmerId, required this.farmerName, required this.price, required this.unit, required this.quantity, required this.totalPrice, this.productImage,
    this.status = 'pending',
    this.farmerNotes,
  });

  factory OrderItem.fromJson(final Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final farmer = json['farmer'] as Map<String, dynamic>?;

    final priceRaw = json['price'] ?? json['unit_price'] ?? 0;
    final totalRaw = json['total_price'] ?? json['total'] ?? json['subtotal'] ?? 0;
    final quantityRaw = json['quantity'] ?? 0;

    return OrderItem(
      id: (json['id'] as String?) ?? (json['product_id'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: (json['order_id'] as String?) ?? '',
      productId: (json['product_id'] as String?) ?? product?['id'] as String? ?? '',
      productName: json['product_name'] as String? ?? product?['name'] as String? ?? 'Product',
      productImage: json['product_image'] as String?,
      farmerId: (json['farmer_id'] as String?) ?? farmer?['id'] as String? ?? '',
      farmerName: json['farmer_name'] as String? ?? farmer?['full_name'] as String? ?? 'Farmer',
      price: (priceRaw as num).toDouble(),
      unit: json['unit'] as String? ?? product?['unit'] as String? ?? 'unit',
      quantity: (quantityRaw as num).toDouble(),
      totalPrice: (totalRaw as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      farmerNotes: json['farmer_notes'] as String?,
    );
  }
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? productImage;
  final String farmerId;
  final String farmerName;
  final double price;
  final String unit;
  final double quantity;
  final double totalPrice;
  final String status; // pending, confirmed, declined
  final String? farmerNotes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'total_price': totalPrice,
      'status': status,
      'farmer_notes': farmerNotes,
    };
  }

  double get subtotal => totalPrice;
}

class OrderStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String processing = 'processing';
  static const String shipped = 'shipped';
  static const String inTransit = 'in_transit';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';
  static const String refunded = 'refunded';

  static List<String> get all => [
    pending,
    confirmed,
    processing,
    shipped,
    inTransit,
    delivered,
    cancelled,
    refunded,
  ];
}

class PaymentStatus {
  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String paid = 'paid';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String refunded = 'refunded';

  static List<String> get all => [pending, processing, paid, completed, failed, refunded];
}

class PaymentMethod {
  static const String mobileMoney = 'marzpay';
  static const String cashOnDelivery = 'cash_on_delivery';

  static List<String> get all => [mobileMoney, cashOnDelivery];

  static String getDisplay(final String method) {
    switch (method) {
      case mobileMoney:
        return 'Mobile Money';
      case 'mobile_money':
        return 'Mobile Money';
      case cashOnDelivery:
        return 'Cash on Delivery';
      default:
        return method;
    }
  }
}
