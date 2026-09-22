import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';

class CategoriesManageScreen extends StatefulWidget {
  const CategoriesManageScreen({super.key});

  @override
  State<CategoriesManageScreen> createState() => _CategoriesManageScreenState();
}

class _CategoriesManageScreenState extends State<CategoriesManageScreen> {
  final _firestore = FirestoreService();

  Future<void> _editCategory({Category? category}) async {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final orderCtrl = TextEditingController(
        text: (category?.sortOrder ?? 0).toString());
    final formKey = GlobalKey<FormState>();

    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              TextFormField(
                controller: orderCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Sort Order (0 = first)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newCategory = Category(
                id: category?.id ?? '',
                name: nameCtrl.text.trim(),
                imageUrl: category?.imageUrl ?? '',
                sortOrder: int.tryParse(orderCtrl.text.trim()) ?? 0,
                isActive: category?.isActive ?? true,
              );
              await _firestore.saveCategory(newCategory,
                  id: category?.id.isEmpty == true ? null : category?.id);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    orderCtrl.dispose();
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${category.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editCategory(),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: categories.isEmpty
          ? const EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              subtitle: 'e.g. Grocery, Rice & Grains, Dairy, Snacks',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = categories[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Sort order: ${c.sortOrder}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editCategory(category: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 20, color: Colors.red),
                          onPressed: () => _deleteCategory(c),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
