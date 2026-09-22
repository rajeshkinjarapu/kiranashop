import 'package:cloud_firestore/cloud_firestore.dart';

class ShopSettings {
  final String shopName;
  final String logoUrl;
  final String address;
  final String phone;
  final double deliveryCharge;
  final double minimumOrder;
  final String upiId;
  final bool isOpen;

  const ShopSettings({
    this.shopName = 'Kirana Shop',
    this.logoUrl = '',
    this.address = '',
    this.phone = '',
    this.deliveryCharge = 0,
    this.minimumOrder = 0,
    this.upiId = '',
    this.isOpen = true,
  });

  factory ShopSettings.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) return const ShopSettings();
    return ShopSettings(
      shopName: d['shopName'] ?? 'Kirana Shop',
      logoUrl: d['logoUrl'] ?? '',
      address: d['address'] ?? '',
      phone: d['phone'] ?? '',
      deliveryCharge: (d['deliveryCharge'] ?? 0).toDouble(),
      minimumOrder: (d['minimumOrder'] ?? 0).toDouble(),
      upiId: d['upiId'] ?? '',
      isOpen: d['isOpen'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'shopName': shopName,
        'logoUrl': logoUrl,
        'address': address,
        'phone': phone,
        'deliveryCharge': deliveryCharge,
        'minimumOrder': minimumOrder,
        'upiId': upiId,
        'isOpen': isOpen,
      };
}
