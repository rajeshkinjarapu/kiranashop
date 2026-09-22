import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String label; // Home / Work / Other
  final String line1;
  final String line2;
  final String landmark;
  final String pincode;
  final bool isDefault;

  const Address({
    required this.id,
    this.label = 'Home',
    required this.line1,
    this.line2 = '',
    this.landmark = '',
    this.pincode = '',
    this.isDefault = false,
  });

  String get fullText => [
        line1,
        if (line2.isNotEmpty) line2,
        if (landmark.isNotEmpty) 'Near $landmark',
        if (pincode.isNotEmpty) pincode,
      ].join(', ');

  factory Address.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Address(
      id: doc.id,
      label: d['label'] ?? 'Home',
      line1: d['line1'] ?? '',
      line2: d['line2'] ?? '',
      landmark: d['landmark'] ?? '',
      pincode: d['pincode'] ?? '',
      isDefault: d['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'line1': line1,
        'line2': line2,
        'landmark': landmark,
        'pincode': pincode,
        'isDefault': isDefault,
      };
}
