import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../services/firestore_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirestoreService _service;

  List<OrderModel> myOrders = [];
  List<OrderModel> allOrders = [];
  bool loading = false;

  StreamSubscription<List<OrderModel>>? _mySub;
  StreamSubscription<List<OrderModel>>? _allSub;

  OrderProvider({FirestoreService? service})
      : _service = service ?? FirestoreService();

  void listenUserOrders(String userId) {
    _mySub?.cancel();
    loading = true;
    notifyListeners();
    _mySub = _service.userOrdersStream(userId).listen((data) {
      myOrders = data;
      loading = false;
      notifyListeners();
    }, onError: (_) {
      loading = false;
      notifyListeners();
    });
  }

  void listenAllOrders() {
    _allSub?.cancel();
    loading = true;
    notifyListeners();
    _allSub = _service.allOrdersStream().listen((data) {
      allOrders = data;
      loading = false;
      notifyListeners();
    }, onError: (_) {
      loading = false;
      notifyListeners();
    });
  }

  void stopListening() {
    _mySub?.cancel();
    _allSub?.cancel();
    _mySub = null;
    _allSub = null;
    myOrders = [];
    allOrders = [];
    notifyListeners();
  }

  List<OrderModel> get activeOrders => myOrders
      .where((o) => o.status != 'delivered' && o.status != 'cancelled')
      .toList();

  List<OrderModel> get previousOrders => myOrders
      .where((o) => o.status == 'delivered' || o.status == 'cancelled')
      .toList();

  Future<String> placeOrder(OrderModel order) => _service.placeOrder(order);

  Future<void> updateStatus(String orderId, String status) =>
      _service.updateOrderStatus(orderId, status);

  // ---------- Admin dashboard helpers ----------

  static bool _isToday(DateTime? dt) {
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  int get todaysOrdersCount =>
      allOrders.where((o) => _isToday(o.createdAt)).length;

  int get pendingOrdersCount => allOrders
      .where((o) => o.status != 'delivered' && o.status != 'cancelled')
      .length;

  double get todaysSales => allOrders
      .where((o) => _isToday(o.createdAt) && o.status != 'cancelled')
      .fold(0.0, (sum, o) => sum + o.total);

  List<OrderModel> get recentOrders => allOrders.take(10).toList();

  @override
  void dispose() {
    _mySub?.cancel();
    _allSub?.cancel();
    super.dispose();
  }
}
