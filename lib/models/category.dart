import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final int sortOrder;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Category(
      id: doc.id,
      name: d['name'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      sortOrder: (d['sortOrder'] ?? 0) as int,
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'imageUrl': imageUrl,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };
}
