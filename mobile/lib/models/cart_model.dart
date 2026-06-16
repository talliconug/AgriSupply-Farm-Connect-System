import 'product_model.dart';

/// Cart item model used by CartProvider with ProductModel reference
class CartItemModel {

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
  });

  factory CartItemModel.fromJson(final Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }
  final String id;
  final ProductModel product;
  final int quantity;

  double get totalPrice => product.price * quantity;

  CartItemModel copyWith({
    final String? id,
    final ProductModel? product,
    final int? quantity,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
    };
  }
}

class CartModel {

  CartModel({required this.items});

  factory CartModel.fromJson(final Map<String, dynamic> json) {
    return CartModel(
      items: (json['items'] as List<dynamic>)
          .map((final e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  final List<CartItem> items;

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((final e) => e.toJson()).toList(),
    };
  }

  double get subtotal => items.fold(0, (final sum, final item) => sum + item.totalPrice);
  int get itemCount => items.length;
  int get totalQuantity =>
      items.fold(0, (final sum, final item) => sum + item.quantity.toInt());

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CartItem? getItem(final String productId) {
    try {
      return items.firstWhere((final item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  bool hasProduct(final String productId) {
    return items.any((final item) => item.productId == productId);
  }

  List<String> get farmerIds {
    return items.map((final item) => item.farmerId).toSet().toList();
  }

  List<CartItem> getItemsByFarmer(final String farmerId) {
    return items.where((final item) => item.farmerId == farmerId).toList();
  }
}

class CartItem {

  CartItem({
    required this.productId,
    required this.productName,
    required this.farmerId, required this.farmerName, required this.price, required this.unit, required this.quantity, required this.availableQuantity, this.productImage,
  });

  factory CartItem.fromJson(final Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productImage: json['product_image'] as String?,
      farmerId: json['farmer_id'] as String,
      farmerName: json['farmer_name'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      availableQuantity: (json['available_quantity'] as num).toDouble(),
    );
  }

  factory CartItem.fromProduct(final ProductModel product, final double quantity) {
    return CartItem(
      productId: product.id,
      productName: product.name,
      productImage: product.primaryImage,
      farmerId: product.farmerId,
      farmerName: product.farmerName,
      price: product.price,
      unit: product.unit,
      quantity: quantity,
      availableQuantity: product.availableQuantity,
    );
  }
  final String productId;
  final String productName;
  final String? productImage;
  final String farmerId;
  final String farmerName;
  final double price;
  final String unit;
  final double quantity;
  final double availableQuantity;

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'available_quantity': availableQuantity,
    };
  }

  CartItem copyWith({
    final String? productId,
    final String? productName,
    final String? productImage,
    final String? farmerId,
    final String? farmerName,
    final double? price,
    final String? unit,
    final double? quantity,
    final double? availableQuantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
    );
  }

  double get totalPrice => price * quantity;
  String get displayPrice => 'UGX ${price.toStringAsFixed(0)}/$unit';
  String get displayTotal => 'UGX ${totalPrice.toStringAsFixed(0)}';
  bool get isAvailable => quantity <= availableQuantity;
}
