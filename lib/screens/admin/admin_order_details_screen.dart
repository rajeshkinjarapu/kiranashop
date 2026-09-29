import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/order_status_chip.dart';
import '../shared/receipt_screen.dart';

class AdminOrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const AdminOrderDetailsScreen({super.key, required this.order});

  String? _nextStatus(String status) {
    final idx = AppConstants.orderStatusFlow.indexOf(status);
    if (idx == -1 || idx >= AppConstants.orderStatusFlow.length - 1) {
      return null;
    }
    return AppConstants.orderStatusFlow[idx + 1];
  }

  Future<void> _setStatus(BuildContext context, String status) async {
    await context.read<OrderProvider>().updateStatus(order, status);
    // Don't pop the screen automatically, let the user see the updated status
  }

  @override
  Widget build(BuildContext context) {
    // Get the latest order state dynamically
    final latestOrder = context.watch<OrderProvider>().allOrders.firstWhere(
          (o) => o.id == order.id,
          orElse: () => order,
        );


    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          if (latestOrder.status == 'delivered' || latestOrder.status == 'ready')
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'View Receipt',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ReceiptScreen(order: latestOrder)),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${latestOrder.id.length > 6 ? latestOrder.id.substring(0, 6).toUpperCase() : latestOrder.id.toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                OrderStatusChip(status: latestOrder.status),
              ],
            ),
            Text(formatDateTime(latestOrder.createdAt),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _infoRow(Icons.person, 'Name', latestOrder.customerName),
                    const SizedBox(height: 6),
                    _infoRow(Icons.phone, 'Phone', latestOrder.customerPhone),
                    const SizedBox(height: 6),
                    _infoRow(Icons.receipt, 'Type', latestOrder.fulfillmentType),
                    if (latestOrder.address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _infoRow(Icons.location_on, 'Address', latestOrder.address),
                    ],
                    const SizedBox(height: 6),
                    _infoRow(Icons.payment, 'Payment', latestOrder.paymentMethod),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...latestOrder.items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      NetworkImageBox(
                        url: item.imageUrl,
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text('${item.qty} × ${formatMoney(item.price)}',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(formatMoney(item.lineTotal),
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _row('Subtotal', formatMoney(latestOrder.subtotal)),
                    const SizedBox(height: 6),
                    _row('Delivery charge', formatMoney(latestOrder.deliveryCharge)),
                    const Divider(height: 20),
                    _row('Total', formatMoney(latestOrder.total), bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Order Status',
                style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: latestOrder.status,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF1E3A8A)),
                          items: [
                            ...AppConstants.orderStatusFlow.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(
                                  orderStatusLabel(status),
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                              );
                            }),
                            const DropdownMenuItem(
                              value: 'cancelled',
                              child: Text(
                                'Cancelled',
                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                              ),
                            ),
                          ],
                          onChanged: (newStatus) {
                            if (newStatus != null && newStatus != latestOrder.status) {
                              _setStatus(context, newStatus);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
