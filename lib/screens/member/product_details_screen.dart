import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/product.dart';
import '../../widgets/add_to_cart_button.dart';
import '../../widgets/network_image_box.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkImageBox(
              url: product.imageUrl,
              width: double.infinity,
              height: 260,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (product.unit.isNotEmpty)
                    Text(
                      product.unit,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    formatMoney(product.price),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        product.inStock && product.stockQty > 0
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 16,
                        color: product.inStock && product.stockQty > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.inStock && product.stockQty > 0
                            ? 'In stock (${product.stockQty} available)'
                            : 'Out of stock',
                        style: TextStyle(
                          color: product.inStock && product.stockQty > 0
                              ? Colors.green
                              : Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (product.description.isNotEmpty) ...[
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      product.description,
                      style: TextStyle(
                          color: Colors.grey.shade700, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: product.inStock && product.stockQty > 0
              ? AddToCartButton(product: product, compact: false)
              : const SizedBox(
                  height: 44,
                  child: Center(
                    child: Text('Out of stock',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
        ),
      ),
    );
  }
}
