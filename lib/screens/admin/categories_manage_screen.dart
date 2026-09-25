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
        title: Row(
          children: [
            Icon(
              category == null ? Icons.add_circle_outline : Icons.edit_outlined,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(category == null ? 'Add Category' : 'Edit Category'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Fresh Vegetables',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sort Order',
                    hintText: '0 = first, 1 = second...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
                  id: (category?.id ?? '').isEmpty ? null : category?.id);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0265DC),
              foregroundColor: Colors.white,
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Delete Category'),
          ],
        ),
        content: Text('Are you sure you want to delete "${category.name}"?\nThis action cannot be undone.',
            style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
      appBar: AppBar(
        title: const Text('Manage Categories', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editCategory(),
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('New Category', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: categories.isEmpty
          ? const EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              subtitle: 'e.g. Grocery, Rice & Grains, Dairy, Snacks',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = categories[i];
                return Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade100),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.category, color: Theme.of(context).primaryColor),
                      ),
                      title: Text(c.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('Sort order: ${c.sortOrder}', style: TextStyle(color: Colors.grey.shade600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                              tooltip: 'Edit',
                              onPressed: () => _editCategory(category: c),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () => _deleteCategory(c),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
