import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/order_model.dart';
import '../models/shop_settings.dart';

enum ReceiptCopyType {
  customer,
  owner,
}

/// Custom Clipper for serrated/torn thermal paper receipt edges
class ReceiptZigzagClipper extends CustomClipper<Path> {
  final double toothSize;
  final bool top;
  final bool bottom;

  const ReceiptZigzagClipper({
    this.toothSize = 6.0,
    this.top = true,
    this.bottom = true,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final toothCount = (size.width / toothSize).floor();
    final actualToothWidth = size.width / toothCount;

    if (top) {
      path.moveTo(0, toothSize);
      for (int i = 0; i < toothCount; i++) {
        final x = i * actualToothWidth;
        final y = (i % 2 == 0) ? 0.0 : toothSize;
        path.lineTo(x + actualToothWidth / 2, y);
      }
      path.lineTo(size.width, toothSize);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
    }

    if (bottom) {
      path.lineTo(size.width, size.height - toothSize);
      for (int i = toothCount; i >= 0; i--) {
        final x = i * actualToothWidth;
        final y = (i % 2 == 0) ? size.height : (size.height - toothSize);
        path.lineTo(x - actualToothWidth / 2, y);
      }
      path.lineTo(0, size.height - toothSize);
    } else {
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant ReceiptZigzagClipper oldClipper) =>
      oldClipper.toothSize != toothSize ||
      oldClipper.top != top ||
      oldClipper.bottom != bottom;
}

/// Dotted Line Divider for thermal receipt
class DottedLinePainter extends CustomPainter {
  final Color color;
  final double dotRadius;
  final double spacing;

  DottedLinePainter({
    this.color = const Color(0xFF4A4A4A),
    this.dotRadius = 1.0,
    this.spacing = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + spacing / 2, size.height / 2),
        paint,
      );
      startX += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ThermalDottedDivider extends StatelessWidget {
  final double height;
  final Color color;

  const ThermalDottedDivider({
    super.key,
    this.height = 16,
    this.color = const Color(0xFF666666),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: DottedLinePainter(color: color),
      ),
    );
  }
}

/// Simulated Barcode visualizer for thermal paper
class ThermalBarcodeWidget extends StatelessWidget {
  final String text;
  final double height;

  const ThermalBarcodeWidget({
    super.key,
    required this.text,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomPaint(
          size: Size(double.infinity, height),
          painter: _BarcodePainter(seed: text.hashCode),
        ),
        const SizedBox(height: 3),
        Text(
          '* $text *',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
      ],
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final int seed;
  _BarcodePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed);
    final paint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;

    double x = 16;
    final endX = size.width - 16;

    while (x < endX) {
      final width = (rand.nextInt(3) + 1.2);
      final gap = (rand.nextInt(3) + 1.5);
      if (x + width > endX) break;
      canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
      x += width + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Complete Thermal Printer Bill Receipt Component
class ThermalBillReceipt extends StatelessWidget {
  final OrderModel order;
  final ShopSettings settings;
  final ReceiptCopyType copyType;

  const ThermalBillReceipt({
    super.key,
    required this.order,
    required this.settings,
    this.copyType = ReceiptCopyType.customer,
  });

  String get _orderIdShort => order.id.length > 8
      ? order.id.substring(0, 8).toUpperCase()
      : (order.id.isEmpty ? 'ORD-101' : order.id.toUpperCase());

  @override
  Widget build(BuildContext context) {
    final isCustomerCopy = copyType == ReceiptCopyType.customer;
    final shopName = settings.shopName.isNotEmpty
        ? settings.shopName
        : 'Kirana & General Store';
    final shopPhone = settings.phone.isNotEmpty
        ? settings.phone
        : '+91 95029 24437';
    final shopAddress = settings.address.isNotEmpty
        ? settings.address
        : 'Main Road, Market Center';

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const ReceiptZigzagClipper(toothSize: 6),
          child: Container(
            color: const Color(0xFFFCFCF9), // Authentic thermal paper tint
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. RECEIPT HEADER / SHOP BRANDING
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF222222), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 26,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  shopName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shopAddress,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF444444),
                  ),
                ),
                Text(
                  'Ph: $shopPhone',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '*** TAX INVOICE / CASH BILL ***',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 8),

                // 2. COPY BADGE (CUSTOMER COPY vs OWNER COPY)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isCustomerCopy
                        ? const Color(0xFFEBF3FC)
                        : const Color(0xFFFFF3E0),
                    border: Border.all(
                      color: isCustomerCopy
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFE65100),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCustomerCopy
                            ? Icons.person_outline
                            : Icons.store_outlined,
                        size: 14,
                        color: isCustomerCopy
                            ? const Color(0xFF1565C0)
                            : const Color(0xFFE65100),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCustomerCopy
                            ? '--- CUSTOMER COPY ---'
                            : '--- OWNER / SHOP COPY ---',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isCustomerCopy
                              ? const Color(0xFF1565C0)
                              : const Color(0xFFE65100),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const ThermalDottedDivider(height: 14),

                // 3. ORDER METADATA
                _metaRow('Bill No', '#$_orderIdShort', boldVal: true),
                _metaRow('Date & Time', formatDateTime(order.createdAt ?? DateTime.now())),
                _metaRow('Customer', order.customerName.isNotEmpty ? order.customerName : 'Walk-in Customer'),
                _metaRow('Mobile', order.customerPhone.isNotEmpty ? order.customerPhone : 'N/A'),
                _metaRow('Order Type', order.fulfillmentType.toUpperCase(), boldVal: true),
                _metaRow('Payment', order.paymentMethod, boldVal: true),

                if (order.address.isNotEmpty && (order.fulfillmentType.toLowerCase() == 'delivery' || !isCustomerCopy)) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 90,
                        child: Text(
                          'Address:',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          order.address,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const ThermalDottedDivider(height: 14),

                // 4. ITEMS TABLE HEADER
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'ITEM',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'QTY×RATE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'TOTAL',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const ThermalDottedDivider(height: 8),

                // 5. ITEM ROWS
                ...order.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$idx. ${item.name}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                if (item.unit.isNotEmpty) ...[
                                  const TextSpan(text: ' '),
                                  TextSpan(
                                    text: '(${item.unit})',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF444444),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${item.qty} × ₹${item.price.toStringAsFixed(0)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            formatMoney(item.lineTotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const ThermalDottedDivider(height: 14),

                // 6. TOTALS & SUMMARY
                _summaryRow('Total Items', '${order.items.length} items (${order.totalQty} qty)'),
                _summaryRow('Subtotal', formatMoney(order.subtotal)),
                if (order.deliveryCharge > 0)
                  _summaryRow('Delivery Charge', formatMoney(order.deliveryCharge))
                else if (order.fulfillmentType.toLowerCase() == 'delivery')
                  _summaryRow('Delivery Charge', 'FREE (₹0.00)'),

                const SizedBox(height: 6),

                // NET AMOUNT BOX (Thermal Style)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NET TOTAL:',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        formatMoney(order.total),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 7. PAYMENT STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF333333), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PAYMENT: ${order.paymentMethod.toUpperCase()}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF222222),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: order.paymentMethod.contains('Katha')
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          order.paymentMethod.contains('Katha') ? 'KATHA' : 'PAID',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: order.paymentMethod.contains('Katha')
                                ? Colors.orange.shade900
                                : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 8. THERMAL BARCODE
                ThermalBarcodeWidget(text: _orderIdShort),

                const SizedBox(height: 8),

                // 9. FOOTER MESSAGE & BLUETOOTH PRINTER METADATA
                Text(
                  isCustomerCopy
                      ? 'Thank You For Shopping With Us! Please Visit Again!'
                      : '*** KITCHEN / DISPATCH TOKEN ***\nCheck items before packing & handoff',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bluetooth_connected_rounded, size: 12, color: Color(0xFF666666)),
                      SizedBox(width: 4),
                      Text(
                        'Bluetooth POS-80 Thermal Print Engine',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: Color(0xFF777777),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value, {bool boldVal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFF444444),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: boldVal ? FontWeight.w800 : FontWeight.w500,
              color: const Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}
