import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;

  const Offer({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Offer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Offer(
      id: doc.id,
      title: d['title'] ?? '',
      subtitle: d['subtitle'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      isActive: d['isActive'] ?? true,
      sortOrder: (d['sortOrder'] is int)
          ? d['sortOrder'] as int
          : ((d['sortOrder'] as num?)?.toInt() ?? 0),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };
}
