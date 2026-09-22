import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String role; // 'admin' | 'member'
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      role: d['role'] ?? 'member',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'role': role,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  AppUser copyWith({String? name}) => AppUser(
        id: id,
        name: name ?? this.name,
        phone: phone,
        role: role,
        createdAt: createdAt,
      );
}
