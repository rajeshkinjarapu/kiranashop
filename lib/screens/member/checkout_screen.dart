import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../models/address.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _fulfillment = AppConstants.fulfillmentTypes.first; // Delivery
  String _payment = AppConstants.paymentMethods.first; // Cash
  bool _placing = false;
  List<Address> _savedAddresses = [];
  final _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.name ?? '';
    _phoneController.text = (user?.phone ?? '').replaceFirst('+91', '');
    if (user != null) {
      _firestore.addressesStream(user.id).first.then((addresses) {
        if (!mounted) return;
        setState(() => _savedAddresses = addresses);
        final def = addresses.where((a) => a.isDefault);
        final chosen = def.isNotEmpty
            ? def.first
            : (addresses.isNotEmpty ? addresses.first : null);
        if (chosen != null) _addressController.text = chosen.fullText;
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final cart = context.read<CartProvider>();
    final settings = context.read<SettingsProvider>().settings;
    final user = context.read<AuthProvider>().user;
    if (user == null || cart.items.isEmpty) return;

    if (!settings.isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop is currently closed')),
      );
      return;
    }

    final deliveryCharge =
        _fulfillment == 'Delivery' ? settings.deliveryCharge : 0.0;
    final total = cart.subtotal + deliveryCharge;

    setState(() => _placing = true);
    try {
      final order = OrderModel(
        id: '',
        userId: user.id,
        customerName: _nameController.text.trim(),
        customerPhone: '+91${_phoneController.text.trim()}',
        address:
            _fulfillment == 'Delivery' ? _addressController.text.trim() : 'Pickup from shop',
        fulfillmentType: _fulfillment,
        paymentMethod: _payment,
        items: cart.items
            .map((c) => OrderItem(
                  productId: c.product.id,
                  name: c.product.name,
                  unit: c.product.unit,
                  imageUrl: c.product.imageUrl,
                  price: c.product.price,
                  qty: c.qty,
                ))
            .toList(),
        subtotal: cart.subtotal,
        deliveryCharge: deliveryCharge,
        total: total,
      );

      final orderId = await context.read<OrderProvider>().placeOrder(order);
      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final deliveryCharge =
        _fulfillment == 'Delivery' ? settings.deliveryCharge : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Contact Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Name', prefixIcon: Icon(Icons.person)),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  counterText: '',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) => (v?.trim().length ?? 0) != 10
                    ? 'Enter a valid 10-digit number'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('Delivery / Pickup',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'Delivery',
                      label: Text('Delivery'),
                      icon: Icon(Icons.delivery_dining)),
                  ButtonSegment(
                      value: 'Pickup',
                      label: Text('Pickup'),
                      icon: Icon(Icons.store)),
                ],
                selected: {_fulfillment},
                onSelectionChanged: (s) =>
                    setState(() => _fulfillment = s.first),
              ),
              if (_fulfillment == 'Delivery') ...[
                const SizedBox(height: 12),
                if (_savedAddresses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      children: _savedAddresses
                          .map(
                            (a) => ActionChip(
                              label: Text(a.label),
                              onPressed: () =>
                                  _addressController.text = a.fullText,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address',
                    prefixIcon: Icon(Icons.location_on),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => _fulfillment == 'Delivery' &&
                          (v?.trim().isEmpty ?? true)
                      ? 'Enter delivery address'
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              const Text('Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              RadioGroup<String>(
                groupValue: _payment,
                onChanged: (v) => setState(() => _payment = v ?? _payment),
                child: Column(
                  children: AppConstants.paymentMethods
                      .map(
                        (m) => RadioListTile<String>(
                          value: m,
                          title: Text(m == 'UPI' && settings.upiId.isNotEmpty
                              ? 'UPI (${settings.upiId})'
                              : m),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _summaryRow(
                          'Items (${cart.itemCount})', formatMoney(cart.subtotal)),
                      const SizedBox(height: 6),
                      _summaryRow(
                          'Delivery charge', formatMoney(deliveryCharge)),
                      const Divider(height: 20),
                      _summaryRow('Total',
                          formatMoney(cart.subtotal + deliveryCharge),
                          bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _placing ? null : _placeOrder,
                child: _placing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}
