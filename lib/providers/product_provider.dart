import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import '../models/category.dart';
import '../models/offer.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirestoreService _service;

  List<Category> categories = [];
  List<Product> products = [];
  List<Offer> offers = [];
  bool loading = true;
  String searchQuery = '';

  StreamSubscription<List<Category>>? _catSub;
  StreamSubscription<List<Product>>? _prodSub;
  StreamSubscription<List<Offer>>? _offerSub;

  ProductProvider({FirestoreService? service})
      : _service = service ?? FirestoreService() {
    _catSub = _service.categoriesStream().listen((data) {
      categories = data;
      notifyListeners();
    }, onError: (_) {});
    _prodSub = _service.productsStream().listen((data) {
      products = data;
      loading = false;
      notifyListeners();
    }, onError: (_) {
      loading = false;
      notifyListeners();
    });
    _offerSub = _service.offersStream().listen((data) {
      offers = data;
      notifyListeners();
    }, onError: (_) {});
  }

  List<Product> get activeProducts =>
      products.where((p) => p.isActive).toList();

  List<Product> get featuredProducts =>
      activeProducts.where((p) => p.isFeatured && p.inStock).toList();

  List<Product> get recentProducts {
    final list = activeProducts.where((p) => p.inStock).toList();
    return list.take(10).toList();
  }

  List<Product> byCategory(String categoryId) => activeProducts
      .where((p) => p.categoryId == categoryId && p.inStock)
      .toList();

  /// Products with stock qty <= 5 (low stock warning)
  int get lowStockCount =>
      products.where((p) => p.isActive && p.stockQty <= 5).length;

  List<Product> get searchResults {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return [];
    return activeProducts
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  @override
  void dispose() {
    _catSub?.cancel();
    _prodSub?.cancel();
    _offerSub?.cancel();
    super.dispose();
  }
}
