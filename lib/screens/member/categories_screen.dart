import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/product_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _selectedCatId = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final categories = provider.categories;
    
    final products = _selectedCatId.isEmpty
        ? provider.activeProducts.where((p) => p.inStock).toList()
        : provider.byCategory(_selectedCatId);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Column(
        children: [
          // Category Filter Bar
          if (categories.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildCatChip('All', ''),
                  ...categories.map((c) => _buildCatChip(c.name, c.id)),
                ],
              ),
            ),
            
          // Products Grid
          Expanded(
            child: products.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products found',
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
          ),
        ],
      ),
    );
  }

  Widget _buildCatChip(String label, String id) {
    final isSelected = _selectedCatId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCatId = id),
        selectedColor: AppTheme.primary.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primary : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
