import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartJson = prefs.getString('cart_items');
      if (cartJson != null) {
        final List<dynamic> decoded = json.decode(cartJson);
        for (var item in decoded) {
          final cartItem = CartItem.fromMap(item as Map<String, dynamic>);
          _items[cartItem.product.id] = cartItem;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> cartList = _items.values.map((item) => item.toMap()).toList();
      await prefs.setString('cart_items', json.encode(cartList));
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, i) => sum + i.qty);
  double get subtotal => _items.values.fold(0.0, (sum, i) => sum + i.lineTotal);

  int qtyOf(String productId) => _items[productId]?.qty ?? 0;

  void add(Product product) {
    final existing = _items[product.id];
    _items[product.id] = existing == null
        ? CartItem(product: product, qty: 1)
        : existing.copyWith(qty: existing.qty + 1);
    notifyListeners();
    _saveCart();
  }

  void decrement(Product product) {
    final existing = _items[product.id];
    if (existing == null) return;
    if (existing.qty <= 1) {
      _items.remove(product.id);
    } else {
      _items[product.id] = existing.copyWith(qty: existing.qty - 1);
    }
    notifyListeners();
    _saveCart();
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
    _saveCart();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _saveCart();
  }
}
