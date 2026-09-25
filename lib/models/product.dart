import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final double price;
  final double? originalPrice;
  final String unit; // e.g. '1 kg', '500 g', '1 L', '1 pc'
  final String imageUrl;
  final int stockQty;
  final bool inStock;
  final bool isFeatured;
  final bool isActive;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.name,
    this.description = '',
    this.categoryId = '',
    this.categoryName = '',
    required this.price,
    this.originalPrice,
    this.unit = '',
    this.imageUrl = '',
    this.stockQty = 0,
    this.inStock = true,
    this.isFeatured = false,
    this.isActive = true,
    this.createdAt,
  });

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Product(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      categoryId: d['categoryId'] ?? '',
      categoryName: d['categoryName'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      originalPrice: d['originalPrice'] != null ? (d['originalPrice']).toDouble() : null,
      unit: d['unit'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      stockQty: (d['stockQty'] ?? 0) as int,
      inStock: d['inStock'] ?? true,
      isFeatured: d['isFeatured'] ?? false,
      isActive: d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'price': price,
        'originalPrice': originalPrice,
        'unit': unit,
        'imageUrl': imageUrl,
        'stockQty': stockQty,
        'inStock': inStock,
        'isFeatured': isFeatured,
        'isActive': isActive,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  Product copyWith({
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    double? price,
    double? originalPrice,
    String? unit,
    String? imageUrl,
    int? stockQty,
    bool? inStock,
    bool? isFeatured,
    bool? isActive,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        price: price ?? this.price,
        originalPrice: originalPrice ?? this.originalPrice,
        unit: unit ?? this.unit,
        imageUrl: imageUrl ?? this.imageUrl,
        stockQty: stockQty ?? this.stockQty,
        inStock: inStock ?? this.inStock,
        isFeatured: isFeatured ?? this.isFeatured,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
