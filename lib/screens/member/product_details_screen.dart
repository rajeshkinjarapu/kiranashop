import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
                    style: GoogleFonts.mandali(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  if (product.unit.isNotEmpty)
                    Text(
                      product.unit,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatMoney(product.price),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      if (product.originalPrice != null && product.originalPrice! > product.price) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            formatMoney(product.originalPrice!),
                            style: TextStyle(
                                fontSize: 16, 
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              '${(((product.originalPrice! - product.price) / product.originalPrice!) * 100).round()}% OFF',
                              style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
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
