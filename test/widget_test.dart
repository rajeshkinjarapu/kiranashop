import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_shop/core/constants.dart';
import 'package:kirana_shop/core/formatters.dart';
import 'package:kirana_shop/models/order_model.dart';

void main() {
  test('orderStatusLabel returns readable labels', () {
    expect(orderStatusLabel('new'), 'New');
    expect(orderStatusLabel('accepted'), 'Accepted');
    expect(orderStatusLabel('preparing'), 'Preparing');
    expect(orderStatusLabel('ready'), 'Ready');
    expect(orderStatusLabel('delivered'), 'Delivered');
    expect(orderStatusLabel('cancelled'), 'Cancelled');
  });

  test('formatMoney formats INR', () {
    expect(formatMoney(100), contains('100'));
    expect(formatMoney(1234.5), contains('1,234.50'));
  });

  test('OrderModel totalQty sums item quantities', () {
    const order = OrderModel(
      id: 'o1',
      userId: 'u1',
      customerName: 'Test',
      customerPhone: '+919999999999',
      items: [
        OrderItem(productId: 'p1', name: 'Rice', price: 50, qty: 2),
        OrderItem(productId: 'p2', name: 'Oil', price: 100, qty: 1),
      ],
      subtotal: 200,
      total: 200,
    );
    expect(order.totalQty, 3);
  });
}
