import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/thermal_bill_receipt.dart';
import '../common/thermal_receipt_screen.dart';

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
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(order.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            tooltip: 'Print Thermal Bill (Customer & Shop Copy)',
            icon: const Icon(Icons.print_rounded),
            onPressed: () => ThermalReceiptScreen.show(context, order, initialCopy: ReceiptCopyType.owner),
          ),
          IconButton(
            tooltip: 'Delete Order',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context),
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
                    'Order #${order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                OrderStatusChip(status: order.status),
              ],
            ),
            Text(formatDateTime(order.createdAt),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 12),

            // QUICK PRINT ACTION CARD FOR ADMIN / STORE
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.print_rounded, color: Colors.blue, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Bluetooth Thermal Bill',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1565C0),
                            side: const BorderSide(color: Color(0xFF1565C0)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => ThermalReceiptScreen.show(
                            context,
                            order,
                            initialCopy: ReceiptCopyType.customer,
                          ),
                          icon: const Icon(Icons.person_outline, size: 16),
                          label: const Text('Customer Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => ThermalReceiptScreen.show(
                            context,
                            order,
                            initialCopy: ReceiptCopyType.owner,
                          ),
                          icon: const Icon(Icons.store_outlined, size: 16),
                          label: const Text('Owner Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer Details',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _infoRow(Icons.person, 'Name', order.customerName),
                    const SizedBox(height: 6),
                    _infoRow(Icons.phone, 'Phone', order.customerPhone),
                    const SizedBox(height: 6),
                    _infoRow(Icons.receipt, 'Type', order.fulfillmentType),
                    if (order.address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _infoRow(Icons.location_on, 'Address', order.address),
                    ],
                    const SizedBox(height: 6),
                    _infoRow(Icons.payment, 'Payment', order.paymentMethod),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...order.items.map(
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
                    _row('Subtotal', formatMoney(order.subtotal)),
                    const SizedBox(height: 6),
                    _row('Delivery charge', formatMoney(order.deliveryCharge)),
                    const Divider(height: 20),
                    _row('Total', formatMoney(order.total), bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (order.status == 'new' || order.status == 'accepted')
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => _setStatus(context, 'cancelled'),
                        child: const Text('Cancel Order'),
                      ),
                    ),
                  if (next != null) ...[
                    if (order.status == 'new' || order.status == 'accepted')
                      const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _setStatus(context, next),
                        child: Text(next == 'delivered'
                            ? (order.fulfillmentType == 'Pickup'
                                ? 'Mark Picked Up'
                                : 'Mark Delivered')
                            : 'Mark ${orderStatusLabel(next)}'),
                      ),
                    ),
                  ],
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

  Future<void> _confirmDelete(BuildContext context) async {
    final shortId = order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete Order #$shortId? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<OrderProvider>().deleteOrder(order.id);
        if (context.mounted) {
          Navigator.pop(context); // Return from details screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order #$shortId deleted successfully'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
