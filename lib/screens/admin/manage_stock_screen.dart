import 'package:flutter/material.dart';

class ManageStockScreen extends StatelessWidget {
  const ManageStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manage Stock', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0265DC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Stock management coming soon!'),
      ),
    );
  }
}
