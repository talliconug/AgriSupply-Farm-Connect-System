import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  CartProvider() {
    _restoreFromStorage();
  }
  final List<CartItemModel> _items = [];
  String? _selectedPaymentMethod;
  String? _deliveryAddress;
  String? _deliveryNotes;
  double _deliveryFee = 5000; // Default delivery fee in UGX

  static const _storageKey = 'agrisupply.cart';

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  int get totalItems => _items.fold(0, (final sum, final item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  String? get deliveryAddress => _deliveryAddress;
  String? get deliveryNotes => _deliveryNotes;
  double get deliveryFee => _deliveryFee;

  double get subtotal {
    return _items.fold(0, (final sum, final item) => sum + item.totalPrice);
  }

  double get total {
    return subtotal + _deliveryFee;
  }

  // Group items by farmer
  Map<String, List<CartItemModel>> get itemsByFarmer {
    final grouped = <String, List<CartItemModel>>{};
    
    for (final item in _items) {
      final farmerId = item.product.farmerId;
      if (grouped.containsKey(farmerId)) {
        grouped[farmerId]!.add(item);
      } else {
        grouped[farmerId] = [item];
      }
    }
    
    return grouped;
  }

  // Get unique farmer IDs from cart items
  Set<String> get farmerIds {
    return _items.map((final item) => item.product.farmerId).toSet();
  }

  void addItem(final ProductModel product, [final int quantity = 1]) {
    final existingIndex = _items.indexWhere(
      (final item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Update existing item quantity
      final existingItem = _items[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      
      if (newQuantity <= product.availableQuantity) {
        _items[existingIndex] = existingItem.copyWith(quantity: newQuantity);
      }
    } else {
      // Add new item
      if (quantity <= product.availableQuantity) {
        _items.add(CartItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: quantity,
        ));
      }
    }
    
    notifyListeners();
    _persistToStorage();
  }

  void removeItem(final String productId) {
    _items.removeWhere((final item) => item.product.id == productId);
    notifyListeners();
    _persistToStorage();
  }

  void updateQuantity(final String productId, final int quantity) {
    final index = _items.indexWhere((final item) => item.product.id == productId);
    
    if (index >= 0) {
      final item = _items[index];
      
      if (quantity <= 0) {
        _items.removeAt(index);
      } else if (quantity <= item.product.availableQuantity) {
        _items[index] = item.copyWith(quantity: quantity);
      }
      
      notifyListeners();
      _persistToStorage();
    }
  }

  void incrementQuantity(final String productId) {
    final index = _items.indexWhere((final item) => item.product.id == productId);
    
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity < item.product.availableQuantity) {
        _items[index] = item.copyWith(quantity: item.quantity + 1);
        notifyListeners();
        _persistToStorage();
      }
    }
  }

  void decrementQuantity(final String productId) {
    final index = _items.indexWhere((final item) => item.product.id == productId);
    
    if (index >= 0) {
      final item = _items[index];
      if (item.quantity > 1) {
        _items[index] = item.copyWith(quantity: item.quantity - 1);
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
      _persistToStorage();
    }
  }

  bool isInCart(final String productId) {
    return _items.any((final item) => item.product.id == productId);
  }

  int getQuantity(final String productId) {
    final item = _items.firstWhere(
      (final item) => item.product.id == productId,
      orElse: () => CartItemModel(
        id: '',
        product: ProductModel.empty(),
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  void setPaymentMethod(final String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
    _persistToStorage();
  }

  void setDeliveryAddress(final String address) {
    _deliveryAddress = address;
    notifyListeners();
    _persistToStorage();
  }

  void setDeliveryNotes(final String notes) {
    _deliveryNotes = notes;
    notifyListeners();
    _persistToStorage();
  }

  void setDeliveryFee(final double fee) {
    _deliveryFee = fee;
    notifyListeners();
    _persistToStorage();
  }

  void clear() {
    _items.clear();
    _selectedPaymentMethod = null;
    _deliveryAddress = null;
    _deliveryNotes = null;
    _deliveryFee = 5000;
    notifyListeners();
    _persistToStorage();
  }

  // Alias for clear() - clears all cart items
  void clearCart() {
    clear();
  }

  // Calculate delivery fee based on region
  double calculateDeliveryFee(final String region) {
    switch (region.toLowerCase()) {
      case 'central':
        _deliveryFee = 5000;
        break;
      case 'eastern':
        _deliveryFee = 8000;
        break;
      case 'western':
        _deliveryFee = 10000;
        break;
      case 'northern':
        _deliveryFee = 12000;
        break;
      default:
        _deliveryFee = 5000;
    }
    notifyListeners();
    return _deliveryFee;
  }

  // Convert cart to order items for submission
  List<Map<String, dynamic>> toOrderItems() {
    return _items.map((final item) => {
      'product_id': item.product.id,
      'quantity': item.quantity,
      'price': item.product.price,
      'total': item.totalPrice,
      'farmer_id': item.product.farmerId,
    }).toList();
  }

  // Save cart to local storage
  Map<String, dynamic> toJson() {
    return {
      'items': _items.map((final item) => item.toJson()).toList(),
      'payment_method': _selectedPaymentMethod,
      'delivery_address': _deliveryAddress,
      'delivery_notes': _deliveryNotes,
      'delivery_fee': _deliveryFee,
    };
  }

  // Load cart from local storage
  void fromJson(final Map<String, dynamic> json) {
    _items.clear();
    
    if (json['items'] != null) {
      final savedItems = json['items'] as List;
      for (final itemJson in savedItems) {
        _items.add(CartItemModel.fromJson(itemJson as Map<String, dynamic>));
      }
    }
    
    _selectedPaymentMethod = json['payment_method'] as String?;
    _deliveryAddress = json['delivery_address'] as String?;
    _deliveryNotes = json['delivery_notes'] as String?;
    _deliveryFee = ((json['delivery_fee'] ?? 5000) as num).toDouble();
    
    notifyListeners();
    _persistToStorage();
  }

  Future<void> _persistToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(toJson());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Ignore persistence errors.
    }
  }

  Future<void> _restoreFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        fromJson(decoded);
      }
    } catch (_) {
      // Ignore restoration errors.
    }
  }
}
