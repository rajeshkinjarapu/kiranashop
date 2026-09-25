import 'package:cloud_firestore/cloud_firestore.dart';

class ShopSettings {
  final String shopName;
  final String ownerName;
  final String ownerPhotoUrl;
  final String logoUrl;
  final String address;
  final String phone;
  final double deliveryCharge;
  final double minimumOrder;
  final String upiId;
  final String qrCodeUrl;
  final bool isOpen;
  final String geminiApiKey;
  final String imageApiKey;

  const ShopSettings({
    this.shopName = 'Kirana Shop',
    this.ownerName = 'Shop Owner',
    this.ownerPhotoUrl = '',
    this.logoUrl = '',
    this.address = '',
    this.phone = '',
    this.deliveryCharge = 0,
    this.minimumOrder = 0,
    this.upiId = '',
    this.qrCodeUrl = '',
    this.isOpen = true,
    this.geminiApiKey = '',
    this.imageApiKey = '',
  });

  factory ShopSettings.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) return const ShopSettings();
    return ShopSettings(
      shopName: d['shopName'] ?? 'Kirana Shop',
      ownerName: d['ownerName'] ?? 'Shop Owner',
      ownerPhotoUrl: d['ownerPhotoUrl'] ?? '',
      logoUrl: d['logoUrl'] ?? '',
      address: d['address'] ?? '',
      phone: d['phone'] ?? '',
      deliveryCharge: (d['deliveryCharge'] ?? 0).toDouble(),
      minimumOrder: (d['minimumOrder'] ?? 0).toDouble(),
      upiId: d['upiId'] ?? '',
      qrCodeUrl: d['qrCodeUrl'] ?? '',
      isOpen: d['isOpen'] ?? true,
      geminiApiKey: d['geminiApiKey'] ?? '',
      imageApiKey: d['imageApiKey'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'shopName': shopName,
        'ownerName': ownerName,
        'ownerPhotoUrl': ownerPhotoUrl,
        'logoUrl': logoUrl,
        'address': address,
        'phone': phone,
        'deliveryCharge': deliveryCharge,
        'minimumOrder': minimumOrder,
        'upiId': upiId,
        'qrCodeUrl': qrCodeUrl,
        'isOpen': isOpen,
        'geminiApiKey': geminiApiKey,
        'imageApiKey': imageApiKey,
      };
}
