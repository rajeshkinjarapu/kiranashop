import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../services/firestore_service.dart';

class ProductSalesRow {
  final String productId;
  final String name;
  final String imageUrl;
  final int units;
  final double amount;

  const ProductSalesRow({
    required this.productId,
    required this.name,
    this.imageUrl = '',
    required this.units,
    required this.amount,
  });
}

class OrderProvider extends ChangeNotifier {
  final FirestoreService _service;

  List<OrderModel> myOrders = [];
  List<OrderModel> allOrders = [];
  bool loading = false;

  StreamSubscription<List<OrderModel>>? _mySub;
  StreamSubscription<List<OrderModel>>? _allSub;

  OrderProvider({FirestoreService? service})
      : _service = service ?? FirestoreService();

  String? _activeUserId;
  bool _isListeningAll = false;

  void listenUserOrders(String userId) {
    if (_activeUserId == userId && _mySub != null) return;
    _activeUserId = userId;
    _isListeningAll = false;
    _mySub?.cancel();
    _allSub?.cancel();
    loading = true;
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
    if (_isListeningAll && _allSub != null) return;
    _isListeningAll = true;
    _activeUserId = null;
    _allSub?.cancel();
    _mySub?.cancel();
    loading = true;
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

  Future<void> updateStatus(OrderModel order, String status) =>
      _service.updateOrderStatus(order, status);

  Future<void> deleteOrder(String orderId) => _service.deleteOrder(orderId);

  // ---------- Admin dashboard helpers ----------

  static bool _isSale(OrderModel o) => o.status != 'cancelled';

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _monthStart(DateTime d) => DateTime(d.year, d.month);

  /// Monday 00:00 of the week containing [d].
  static DateTime _weekStart(DateTime d) {
    final day = _dayStart(d);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static bool _isToday(DateTime? dt) {
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _inRange(OrderModel o, DateTime start, DateTime end) {
    final t = o.createdAt;
    if (t == null || !_isSale(o)) return false;
    return !t.isBefore(start) && t.isBefore(end);
  }

  double _salesBetween(DateTime start, DateTime end) => allOrders
      .where((o) => _inRange(o, start, end))
      .fold(0.0, (sum, o) => sum + o.total);

  int get todaysOrdersCount =>
      allOrders.where((o) => _isToday(o.createdAt)).length;

  int get pendingOrdersCount => allOrders
      .where((o) => o.status != 'delivered' && o.status != 'cancelled')
      .length;

  double get todaysSales {
    final start = _dayStart(DateTime.now());
    return _salesBetween(start, start.add(const Duration(days: 1)));
  }

  double get yesterdaysSales {
    final today = _dayStart(DateTime.now());
    return _salesBetween(today.subtract(const Duration(days: 1)), today);
  }

  double get thisWeekSales {
    final start = _weekStart(DateTime.now());
    return _salesBetween(start, start.add(const Duration(days: 7)));
  }

  double get lastWeekSales {
    final thisWeek = _weekStart(DateTime.now());
    return _salesBetween(thisWeek.subtract(const Duration(days: 7)), thisWeek);
  }

  double get thisMonthSales {
    final start = _monthStart(DateTime.now());
    final next = DateTime(start.year, start.month + 1);
    return _salesBetween(start, next);
  }

  double get lastMonthSales {
    final thisMonth = _monthStart(DateTime.now());
    final last = DateTime(thisMonth.year, thisMonth.month - 1);
    return _salesBetween(last, thisMonth);
  }

  /// Positive = growth, negative = decline. `null` if previous period was 0.
  static double? percentChange(double current, double previous) {
    if (previous == 0) return current == 0 ? 0 : null;
    return ((current - previous) / previous) * 100;
  }

  List<ProductSalesRow> topSellingThisMonth({int? limit}) {
    final start = _monthStart(DateTime.now());
    final end = DateTime(start.year, start.month + 1);
    final map = <String, ProductSalesRow>{};

    for (final order in allOrders.where((o) => _inRange(o, start, end))) {
      for (final item in order.items) {
        final key = item.productId.isNotEmpty ? item.productId : item.name;
        if (key.isEmpty) continue;
        final existing = map[key];
        map[key] = ProductSalesRow(
          productId: item.productId,
          name: item.name.isEmpty ? 'Unknown item' : item.name,
          imageUrl: item.imageUrl,
          units: (existing?.units ?? 0) + item.qty,
          amount: (existing?.amount ?? 0) + item.lineTotal,
        );
      }
    }

    final rows = map.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    if (limit == null || rows.length <= limit) return rows;
    return rows.take(limit).toList();
  }

  List<OrderModel> get recentOrders => allOrders.take(10).toList();

  @override
  void dispose() {
    _mySub?.cancel();
    _allSub?.cancel();
    super.dispose();
  }
}
