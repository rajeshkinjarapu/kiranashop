import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { credit, payment }

class KathaTransaction {
  final String id;
  final String userId;
  final double amount;
  final String description;
  final TransactionType type;
  final DateTime? createdAt;

  const KathaTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.type,
    this.createdAt,
  });

  factory KathaTransaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return KathaTransaction(
      id: doc.id,
      userId: d['userId'] ?? '',
      amount: (d['amount'] ?? 0.0).toDouble(),
      description: d['description'] ?? '',
      type: d['type'] == 'payment' ? TransactionType.payment : TransactionType.credit,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'amount': amount,
        'description': description,
        'type': type.name,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
