import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/order_model.dart';
import '../../providers/settings_provider.dart';

class ReceiptScreen extends StatelessWidget {
  final OrderModel order;

  const ReceiptScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0265DC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'PAYMENT SUCCESSFUL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatMoney(order.total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop Details
                      Center(
                        child: Text(
                          settings.shopName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Order Details
                      _buildReceiptRow('Order ID', '#${order.id.substring(0, 8).toUpperCase()}'),
                      _buildReceiptRow('Date', formatDateTime(order.createdAt)),
                      _buildReceiptRow('Payment Method', order.paymentMethod),
                      _buildReceiptRow('Customer', order.customerName),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.grey),
                      ),
                      
                      // Items
                      const Text(
                        'ITEMS PURCHASED',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.qty} x', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.name)),
                            Text(formatMoney(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.grey),
                      ),
                      
                      // Totals
                      _buildReceiptRow('Subtotal', formatMoney(order.subtotal)),
                      _buildReceiptRow('Delivery Charge', formatMoney(order.deliveryCharge)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL AMOUNT',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              formatMoney(order.total),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0265DC)),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      const Center(
                        child: Text(
                          'Thank you for shopping with us!',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom Edge zig-zag effect (simplified as rounded)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
