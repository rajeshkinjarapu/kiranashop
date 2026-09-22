import 'package:flutter/material.dart';

import '../core/constants.dart';

class OrderStatusChip extends StatelessWidget {
  final String status;

  const OrderStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      'new' => (Colors.blue.shade700, Colors.blue.shade50),
      'accepted' => (Colors.purple.shade700, Colors.purple.shade50),
      'preparing' => (Colors.orange.shade800, Colors.orange.shade50),
      'ready' => (Colors.teal.shade700, Colors.teal.shade50),
      'delivered' => (Colors.green.shade700, Colors.green.shade50),
      'cancelled' => (Colors.red.shade700, Colors.red.shade50),
      _ => (Colors.grey.shade700, Colors.grey.shade200),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
