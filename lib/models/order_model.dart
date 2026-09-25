import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final String unit;
  final String imageUrl;
  final double price;
  final int qty;

  const OrderItem({
    required this.productId,
    required this.name,
    this.unit = '',
    this.imageUrl = '',
    required this.price,
    required this.qty,
  });

  double get lineTotal => price * qty;

  factory OrderItem.fromMap(Map<String, dynamic> d) => OrderItem(
        productId: d['productId'] ?? '',
        name: d['name'] ?? '',
        unit: d['unit'] ?? '',
        imageUrl: d['imageUrl'] ?? '',
        price: (d['price'] ?? 0).toDouble(),
        qty: (d['qty'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'unit': unit,
        'imageUrl': imageUrl,
        'price': price,
        'qty': qty,
      };
}

class OrderModel {
  final String id;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String address;
  final String fulfillmentType; // Delivery | Pickup
  final String paymentMethod;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryCharge;
  final double total;
  final String status; // new|accepted|preparing|ready|delivered|cancelled
  final DateTime? createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    this.address = '',
    this.fulfillmentType = 'Delivery',
    this.paymentMethod = 'Katha (అరువు)',
    this.items = const [],
    required this.subtotal,
    this.deliveryCharge = 0,
    required this.total,
    this.status = 'new',
    this.createdAt,
  });

  int get totalQty => items.fold(0, (total, i) => total + i.qty);

  factory OrderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawItems = (d['items'] as List?) ?? [];
    return OrderModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      customerName: d['customerName'] ?? '',
      customerPhone: d['customerPhone'] ?? '',
      address: d['address'] ?? '',
      fulfillmentType: d['fulfillmentType'] ?? 'Delivery',
      paymentMethod: d['paymentMethod'] ?? 'Cash',
      items: rawItems
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: (d['subtotal'] ?? 0).toDouble(),
      deliveryCharge: (d['deliveryCharge'] ?? 0).toDouble(),
      total: (d['total'] ?? 0).toDouble(),
      status: d['status'] ?? 'new',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'address': address,
        'fulfillmentType': fulfillmentType,
        'paymentMethod': paymentMethod,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'deliveryCharge': deliveryCharge,
        'total': total,
        'status': status,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
