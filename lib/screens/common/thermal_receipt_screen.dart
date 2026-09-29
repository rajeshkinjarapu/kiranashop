import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/order_model.dart';
import '../../providers/settings_provider.dart';
import '../../services/printer_service.dart';
import '../../widgets/thermal_bill_receipt.dart';

class ThermalReceiptScreen extends StatefulWidget {
  final OrderModel order;
  final ReceiptCopyType initialCopy;

  const ThermalReceiptScreen({
    super.key,
    required this.order,
    this.initialCopy = ReceiptCopyType.customer,
  });

  static Future<void> show(BuildContext context, OrderModel order, {ReceiptCopyType initialCopy = ReceiptCopyType.customer}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ThermalReceiptScreen(order: order, initialCopy: initialCopy),
      ),
    );
  }

  @override
  State<ThermalReceiptScreen> createState() => _ThermalReceiptScreenState();
}

class _ThermalReceiptScreenState extends State<ThermalReceiptScreen> {
  late ReceiptCopyType _currentCopy;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _currentCopy = widget.initialCopy;
  }

  Future<void> _handlePrint() async {
    final settings = context.read<SettingsProvider>().settings;
    // 1. Trigger isolated thermal receipt print (only receipt prints)
    PrinterService.printReceipt(
      order: widget.order,
      settings: settings,
      isCustomerCopy: _currentCopy == ReceiptCopyType.customer,
    );

    // 2. Show Bluetooth thermal printer animation dialog
    setState(() => _isPrinting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BluetoothPrintDialog(
        order: widget.order,
        copyType: _currentCopy,
      ),
    ).then((_) {
      if (mounted) setState(() => _isPrinting = false);
    });
  }

  void _shareReceiptText(BuildContext context) {
    final o = widget.order;
    final copyName = _currentCopy == ReceiptCopyType.customer
        ? 'Customer Copy'
        : 'Owner Copy';
    final itemsText = o.items
        .asMap()
        .entries
        .map((e) =>
            '${e.key + 1}. ${e.value.name} (${e.value.qty} x ${formatMoney(e.value.price)}) = ${formatMoney(e.value.lineTotal)}')
        .join('\n');

    final text = '''
🧾 *KIRANA SHOP - BILL RECEIPT ($copyName)*
-------------------------------------
*Order ID:* #${o.id.length > 8 ? o.id.substring(0, 8).toUpperCase() : o.id.toUpperCase()}
*Date:* ${formatDateTime(o.createdAt ?? DateTime.now())}
*Customer:* ${o.customerName} (${o.customerPhone})
*Order Type:* ${o.fulfillmentType}
*Payment:* ${o.paymentMethod}
${o.address.isNotEmpty ? '*Address:* ${o.address}\n' : ''}-------------------------------------
*ITEMS:*
$itemsText
-------------------------------------
*Subtotal:* ${formatMoney(o.subtotal)}
*Delivery:* ${formatMoney(o.deliveryCharge)}
*TOTAL AMOUNT:* ${formatMoney(o.total)}
-------------------------------------
_Thank You, Visit Again!_
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bill text copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: const Text('Bluetooth Thermal Bill'),
        actions: [
          IconButton(
            tooltip: 'Share / Copy Bill Text',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareReceiptText(context),
          ),
          IconButton(
            tooltip: 'Print Receipt',
            icon: const Icon(Icons.print_rounded),
            onPressed: _isPrinting ? null : _handlePrint,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // COPY SELECTOR (Customer Copy vs Owner Copy)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<ReceiptCopyType>(
                      segments: const [
                        ButtonSegment(
                          value: ReceiptCopyType.customer,
                          label: Text('Customer Copy'),
                          icon: Icon(Icons.person_pin_circle_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: ReceiptCopyType.owner,
                          label: Text('Owner Copy'),
                          icon: Icon(Icons.storefront_outlined, size: 18),
                        ),
                      ],
                      selected: {_currentCopy},
                      onSelectionChanged: (s) => setState(() => _currentCopy = s.first),
                    ),
                  ),
                ],
              ),
            ),

            // THERMAL RECEIPT DISPLAY
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    ThermalBillReceipt(
                      order: widget.order,
                      settings: settings,
                      copyType: _currentCopy,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // BOTTOM ACTION BAR
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
                      onPressed: () => _shareReceiptText(context),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Bill'),
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
                      onPressed: _isPrinting ? null : _handlePrint,
                      icon: const Icon(Icons.print_rounded),
                      label: Text(
                        _currentCopy == ReceiptCopyType.customer
                            ? 'Print Customer Bill'
                            : 'Print Owner Bill',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

/// Simulated Bluetooth Thermal Printer Dialog
class _BluetoothPrintDialog extends StatefulWidget {
  final OrderModel order;
  final ReceiptCopyType copyType;

  const _BluetoothPrintDialog({
    required this.order,
    required this.copyType,
  });

  @override
  State<_BluetoothPrintDialog> createState() => _BluetoothPrintDialogState();
}

class _BluetoothPrintDialogState extends State<_BluetoothPrintDialog>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0: connecting, 1: printing, 2: completed
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Simulation sequence
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _step = 1);
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _step = 2);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.copyType == ReceiptCopyType.customer;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bluetooth_connected_rounded, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Bluetooth Thermal Printer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.print_outlined, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device: POS-80 Bluetooth (58mm)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Mode: ${isCustomer ? "Customer Copy" : "Owner/Kitchen Copy"}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Ready',
                    style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_step == 0) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            const Text(
              'Connecting to Bluetooth Printer...',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Sending ESC/POS byte sequence',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ] else if (_step == 1) ...[
            LinearProgressIndicator(
              backgroundColor: Colors.blue.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 14),
            const Text(
              'Printing Thermal Bill Slip...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
            ),
            const SizedBox(height: 4),
            const Text(
              'Feeding thermal paper roll & cutting...',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ] else ...[
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
            const SizedBox(height: 10),
            const Text(
              'Bill Printed Successfully! 🎉',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              '${isCustomer ? "Customer" : "Owner"} receipt dispatched.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
      actions: [
        if (_step == 2)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}
