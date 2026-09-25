import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String role; // 'admin' | 'member'
  final String password; // 6-digit password
  final DateTime? createdAt;
  final double kathaBalance; // > 0 means they owe money (Baki), < 0 means advance

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.password = '',
    this.createdAt,
    this.kathaBalance = 0.0,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      role: d['role'] ?? 'member',
      password: d['password'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      kathaBalance: (d['kathaBalance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'role': role,
        'password': password,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'kathaBalance': kathaBalance,
      };

  AppUser copyWith({String? name, String? password, double? kathaBalance}) => AppUser(
        id: id,
        name: name ?? this.name,
        phone: phone,
        role: role,
        password: password ?? this.password,
        createdAt: createdAt,
        kathaBalance: kathaBalance ?? this.kathaBalance,
      );
}
