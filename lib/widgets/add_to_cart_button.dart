import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

/// Shows "+ Add" or a qty stepper (- qty +) based on current cart qty.
class AddToCartButton extends StatelessWidget {
  final Product product;
  final bool compact;

  const AddToCartButton({super.key, required this.product, this.compact = true});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.qtyOf(product.id);

    if (qty == 0) {
      return SizedBox(
        height: compact ? 34 : 44,
        width: compact ? 84 : double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => cart.add(product),
          child: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Container(
      height: compact ? 34 : 44,
      width: compact ? 104 : null,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stepperIcon(context, Icons.remove, () => cart.decrement(product)),
          Text(
            '$qty',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          _stepperIcon(context, Icons.add, () => cart.add(product)),
        ],
      ),
    );
  }

  Widget _stepperIcon(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
