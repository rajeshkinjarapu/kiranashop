import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

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
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
