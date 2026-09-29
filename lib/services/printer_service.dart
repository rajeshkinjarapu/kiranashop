import 'package:flutter/foundation.dart';
import '../core/formatters.dart';
import '../models/order_model.dart';
import '../models/shop_settings.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html if (dart.library.io) 'printer_service_stub.dart';

class PrinterService {
  static void printReceipt({
    required OrderModel order,
    required ShopSettings settings,
    required bool isCustomerCopy,
  }) {
    if (!kIsWeb) return;

    try {
      final shopName = settings.shopName.isNotEmpty
          ? settings.shopName
          : 'Kirana & General Store';
      final shopPhone = settings.phone.isNotEmpty
          ? settings.phone
          : '+91 95029 24437';
      final shopAddress = settings.address.isNotEmpty
          ? settings.address
          : 'Main Road, Market Center';

      final shortOrderId = order.id.length > 8
          ? order.id.substring(0, 8).toUpperCase()
          : (order.id.isEmpty ? 'ORD-101' : order.id.toUpperCase());

      final copyTitle = isCustomerCopy
          ? 'CUSTOMER COPY'
          : 'OWNER / SHOP COPY';

      final itemsHtml = order.items.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final item = entry.value;
        final unitStr = item.unit.isNotEmpty ? ' (${item.unit})' : '';
        return '''
        <tr>
          <td class="text-left bold" style="word-break: break-word; padding: 4px 0;">$idx. ${item.name}$unitStr</td>
          <td class="text-center" style="white-space: nowrap; padding: 4px 0;">${item.qty} × ₹${item.price.toStringAsFixed(0)}</td>
          <td class="text-right bold" style="white-space: nowrap; padding: 4px 0;">₹${item.lineTotal.toStringAsFixed(2)}</td>
        </tr>
        ''';
      }).join('');

      final receiptHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Bill #$shortOrderId - $shopName</title>
  <style>
    @page {
      size: 80mm auto;
      margin: 0;
    }
    @media print {
      html, body {
        margin: 0 !important;
        padding: 0 !important;
        background: #fff !important;
        width: 80mm !important;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
      }
      .no-print { display: none !important; }
      .receipt-container {
        box-shadow: none !important;
        border: none !important;
        padding: 2mm 1.5mm !important;
        width: 76mm !important;
        max-width: 76mm !important;
        margin: 0 auto !important;
      }
    }
    * {
      box-sizing: border-box;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }
    body {
      font-family: 'Courier New', Courier, monospace;
      font-size: 11.5px;
      line-height: 1.35;
      color: #000;
      background: #f4f4f4;
      margin: 0;
      padding: 10px;
      display: flex;
      justify-content: center;
    }
    .receipt-container {
      width: 76mm;
      background: #fff;
      padding: 12px 8px;
      margin: 0 auto;
      border: 1px solid #ccc;
    }
    .text-center { text-align: center; }
    .text-right { text-align: right; }
    .text-left { text-align: left; }
    .bold { font-weight: bold; }

    .shop-name {
      font-size: 16px;
      font-weight: 900;
      letter-spacing: 0.5px;
      margin-bottom: 3px;
      text-transform: uppercase;
      font-family: 'Courier New', Courier, monospace;
    }
    .sub-header {
      font-size: 11px;
      color: #222;
      margin: 1px 0;
    }
    .invoice-tag {
      font-size: 10.5px;
      font-weight: bold;
      letter-spacing: 1px;
      margin: 5px 0 4px 0;
    }
    .copy-box {
      border: 1.5px dashed #000;
      padding: 4px 6px;
      text-align: center;
      font-size: 11px;
      font-weight: 800;
      margin: 6px 0;
      letter-spacing: 0.5px;
    }
    .dashed-divider {
      border-top: 1px dashed #000;
      margin: 6px 0;
      width: 100%;
    }
    .meta-row {
      display: flex;
      justify-content: space-between;
      font-size: 11px;
      margin: 3px 0;
      line-height: 1.3;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
      margin: 4px 0;
    }
    th {
      border-top: 1px dashed #000;
      border-bottom: 1px dashed #000;
      padding: 5px 0;
      font-size: 11px;
      font-weight: 800;
      font-family: 'Courier New', Courier, monospace;
    }
    .total-box {
      border: 2px solid #000;
      padding: 6px 8px;
      margin: 8px 0 6px 0;
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 14px;
      font-weight: 900;
    }
    .payment-status-box {
      border: 1.5px solid #000;
      padding: 5px 8px;
      margin: 6px 0;
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
    }
    .barcode-box {
      text-align: center;
      margin: 10px 0 6px 0;
    }
    .barcode-lines {
      letter-spacing: 3px;
      font-family: 'Courier New', Courier, monospace;
      font-size: 20px;
      font-weight: 900;
      line-height: 1;
    }
    .footer-note {
      text-align: center;
      font-size: 10.5px;
      font-weight: bold;
      margin-top: 8px;
      line-height: 1.4;
    }
    .printer-stamp {
      text-align: center;
      font-size: 9px;
      color: #777;
      margin-top: 6px;
    }
  </style>
</head>
<body>
  <div class="receipt-container">
    <div class="text-center shop-name">$shopName</div>
    <div class="text-center sub-header">$shopAddress</div>
    <div class="text-center sub-header bold">Ph: $shopPhone</div>
    <div class="text-center invoice-tag">*** TAX INVOICE / CASH BILL ***</div>

    <div class="copy-box">--- $copyTitle ---</div>

    <div class="dashed-divider"></div>

    <div class="meta-row">
      <span class="bold">Bill No:</span>
      <span class="bold">#$shortOrderId</span>
    </div>
    <div class="meta-row">
      <span>Date & Time:</span>
      <span>${formatDateTime(order.createdAt ?? DateTime.now())}</span>
    </div>
    <div class="meta-row">
      <span>Customer:</span>
      <span class="bold">${order.customerName.isNotEmpty ? order.customerName : 'Customer'}</span>
    </div>
    <div class="meta-row">
      <span>Mobile:</span>
      <span>${order.customerPhone.isNotEmpty ? order.customerPhone : 'N/A'}</span>
    </div>
    <div class="meta-row">
      <span>Order Type:</span>
      <span class="bold">${order.fulfillmentType.toUpperCase()}</span>
    </div>
    <div class="meta-row">
      <span>Payment:</span>
      <span class="bold">${order.paymentMethod}</span>
    </div>
    ${order.address.isNotEmpty ? '''
    <div class="meta-row" style="align-items: flex-start;">
      <span>Address:</span>
      <span class="bold text-right" style="max-width: 60%;">${order.address}</span>
    </div>
    ''' : ''}

    <div class="dashed-divider"></div>

    <table>
      <thead>
        <tr>
          <th class="text-left" style="width: 46%;">ITEM</th>
          <th class="text-center" style="width: 30%;">QTY×RATE</th>
          <th class="text-right" style="width: 24%;">TOTAL</th>
        </tr>
      </thead>
      <tbody>
        $itemsHtml
      </tbody>
    </table>

    <div class="dashed-divider"></div>

    <div class="meta-row">
      <span>Total Items:</span>
      <span class="bold">${order.items.length} items (${order.totalQty} qty)</span>
    </div>
    <div class="meta-row">
      <span>Subtotal:</span>
      <span class="bold">₹${order.subtotal.toStringAsFixed(2)}</span>
    </div>
    <div class="meta-row">
      <span>Delivery Charge:</span>
      <span class="bold">${order.deliveryCharge > 0 ? '₹' + order.deliveryCharge.toStringAsFixed(2) : 'FREE (₹0.00)'}</span>
    </div>

    <div class="total-box">
      <span>NET TOTAL:</span>
      <span>₹${order.total.toStringAsFixed(2)}</span>
    </div>

    <div class="payment-status-box">
      <span>PAYMENT STATUS:</span>
      <span>${order.paymentMethod.contains('Katha') ? 'KATHA' : 'PAID'}</span>
    </div>

    <div class="barcode-box">
      <div class="barcode-lines">||| | |||| || ||| | ||| |||| |</div>
      <div style="font-size: 10px; font-weight: bold; letter-spacing: 2px; margin-top: 2px;">*$shortOrderId*</div>
    </div>

    <div class="footer-note">
      ${isCustomerCopy ? 'Thank You For Shopping With Us!' : '*** KITCHEN / DISPATCH TOKEN ***<br>Check items before packing & handoff'}
    </div>
    <div class="printer-stamp">
      🖨️ POS-80 Bluetooth Thermal Print Slip
    </div>
  </div>

  <script>
    window.onload = function() {
      setTimeout(function() {
        window.focus();
        window.print();
      }, 250);
    };
  </script>
</body>
</html>
''';

      // Use a hidden iframe for silent, clean print of the receipt ONLY
      final existingIframe = html.document.getElementById('__thermal_print_frame__');
      if (existingIframe != null) {
        existingIframe.remove();
      }

      final iframe = html.IFrameElement()
        ..id = '__thermal_print_frame__'
        ..style.position = 'fixed'
        ..style.right = '0'
        ..style.bottom = '0'
        ..style.width = '1px'
        ..style.height = '1px'
        ..style.border = 'none'
        ..style.opacity = '0.01'
        ..srcdoc = receiptHtml;

      html.document.body?.append(iframe);
    } catch (e) {
      debugPrint('Print receipt error: $e');
    }
  }
}
