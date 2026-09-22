import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/product_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';

class ProductListScreen extends StatelessWidget {
  final String? categoryId;
  final String categoryName;

  const ProductListScreen({
    super.key,
    this.categoryId,
    this.categoryName = 'Products',
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = categoryId == null
        ? provider.activeProducts.where((p) => p.inStock).toList()
        : provider.byCategory(categoryId!);

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: products.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products in this category',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) => ProductCard(product: products[i]),
            ),
    );
  }
}
