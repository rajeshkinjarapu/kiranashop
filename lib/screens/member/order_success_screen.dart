import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/thermal_bill_receipt.dart';
import '../common/thermal_receipt_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  final OrderModel order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  ReceiptCopyType _copyType = ReceiptCopyType.customer;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: const Text('Order Placed Successfully'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        actions: [
          IconButton(
            tooltip: 'Full Receipt Screen',
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: () => ThermalReceiptScreen.show(context, widget.order, initialCopy: _copyType),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SUCCESS BANNER & COPY TOGGLE
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Placed Successfully! 🎉',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            Text(
                              'Bluetooth thermal bill ready for printing',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // COPY SWITCH
                  SegmentedButton<ReceiptCopyType>(
                    segments: const [
                      ButtonSegment(
                        value: ReceiptCopyType.customer,
                        label: Text('Customer Copy'),
                        icon: Icon(Icons.person_outline, size: 16),
                      ),
                      ButtonSegment(
                        value: ReceiptCopyType.owner,
                        label: Text('Owner Copy'),
                        icon: Icon(Icons.store_outlined, size: 16),
                      ),
                    ],
                    selected: {_copyType},
                    onSelectionChanged: (s) => setState(() => _copyType = s.first),
                  ),
                ],
              ),
            ),

            // THERMAL RECEIPT PREVIEW
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ThermalBillReceipt(
                  order: widget.order,
                  settings: settings,
                  copyType: _copyType,
                ),
              ),
            ),

            // BOTTOM BAR ACTIONS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Shop More'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => ThermalReceiptScreen.show(context, widget.order, initialCopy: _copyType),
                      icon: const Icon(Icons.print_rounded),
                      label: const Text(
                        'Print Thermal Bill 🖨️',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
