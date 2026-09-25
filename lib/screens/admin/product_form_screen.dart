import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import 'categories_manage_screen.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/network_image_box.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  final _storage = StorageService();
  final _picker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _unitQtyCtrl;
  late final TextEditingController _stockCtrl;

  Category? _selectedCategory;
  String _selectedUnitType = 'kg';
  final List<String> _unitTypes = ['kg', 'g', 'L', 'ml', 'Piece', 'Packet', 'Dozen', 'Box'];
  
  bool _inStock = true;
  bool _isFeatured = false;
  bool _isActive = true;
  bool _saving = false;
  Uint8List? _pickedImageBytes;
  String _existingImageUrl = '';

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.price.toString() : '');
        
    String uQty = '';
    String uType = 'kg';
    if (p != null && p.unit.isNotEmpty) {
      final match = RegExp(r'^(\d+(?:\.\d+)?)\s*(.*)$').firstMatch(p.unit.trim());
      if (match != null) {
        uQty = match.group(1) ?? '';
        final parsedType = (match.group(2) ?? '').trim();
        // Try to match ignoring case
        final matchedType = _unitTypes.where((t) => t.toLowerCase() == parsedType.toLowerCase()).firstOrNull;
        uType = matchedType ?? 'kg';
      } else {
        // If it doesn't match the format (e.g. just "Packet"), fallback gracefully
        uQty = '1';
        final matchedType = _unitTypes.where((t) => t.toLowerCase() == p.unit.trim().toLowerCase()).firstOrNull;
        uType = matchedType ?? 'kg';
      }
    }
    
    _unitQtyCtrl = TextEditingController(text: uQty);
    _selectedUnitType = uType;
    
    _stockCtrl =
        TextEditingController(text: p != null ? p.stockQty.toString() : '0');
    _inStock = p?.inStock ?? true;
    _isFeatured = p?.isFeatured ?? false;
    _isActive = p?.isActive ?? true;
    _existingImageUrl = p?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _unitQtyCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Optimal size for high quality
      imageQuality: 85, // 85% retains excellent HD quality while keeping size around 100-150KB
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _pickedImageBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String imageUrl = _existingImageUrl;
      if (_pickedImageBytes != null) {
        // Compress and encode as Base64 to save directly in Firestore
        final base64String = base64Encode(_pickedImageBytes!);
        imageUrl = 'data:image/jpeg;base64,$base64String';
      }

      final existing = widget.product;
      final product = Product(
        id: existing?.id ?? '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        categoryId: _selectedCategory?.id ?? existing?.categoryId ?? '',
        categoryName: _selectedCategory?.name ?? existing?.categoryName ?? '',
        price: double.parse(_priceCtrl.text.trim()),
        unit: '${_unitQtyCtrl.text.trim()} $_selectedUnitType'.trim(),
        imageUrl: imageUrl,
        stockQty: int.tryParse(_stockCtrl.text.trim()) ?? 0,
        inStock: _inStock,
        isFeatured: _isFeatured,
        isActive: _isActive,
        createdAt: existing?.createdAt,
      );

      await _firestore.saveProduct(product,
          id: (existing?.id ?? '').isEmpty ? null : existing?.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories;

    if (_selectedCategory == null && widget.product != null) {
      final match = categories.where((c) => c.id == widget.product!.categoryId);
      if (match.isNotEmpty) _selectedCategory = match.first;
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.product == null ? 'Add Product' : 'Edit Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _pickedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_pickedImageBytes!,
                              fit: BoxFit.cover, width: double.infinity),
                        )
                      : _existingImageUrl.isNotEmpty
                          ? NetworkImageBox(
                              url: _existingImageUrl,
                              width: double.infinity,
                              height: 160,
                              borderRadius: BorderRadius.circular(12),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 40, color: Colors.grey.shade500),
                                const SizedBox(height: 6),
                                Text('Tap to add product image',
                                    style: TextStyle(
                                        color: Colors.grey.shade600)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Enter product name' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: categories.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: const Text(
                              'No categories available. Please add one first.',
                              style: TextStyle(color: Colors.brown, fontSize: 14),
                            ),
                          )
                        : DropdownButtonFormField<Category>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: categories
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c.name)))
                                .toList(),
                            onChanged: (c) => setState(() => _selectedCategory = c),
                            validator: (v) => v == null ? 'Select a category' : null,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.blue),
                        tooltip: 'Manage Categories',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoriesManageScreen(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                          labelText: 'Price', prefixText: '\u20B9 '),
                      validator: (v) =>
                          (double.tryParse(v?.trim() ?? '') ?? 0) <= 0
                              ? 'Enter valid price'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _unitQtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                            ],
                            decoration: const InputDecoration(labelText: 'Qty (e.g. 1)'),
                            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter quantity' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnitType,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: _unitTypes
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (u) => setState(() => _selectedUnitType = u ?? 'kg'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    const InputDecoration(labelText: 'Stock Quantity'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description', alignLabelWithHint: true),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('In Stock'),
                value: _inStock,
                onChanged: (v) => setState(() => _inStock = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Featured (show on Home)'),
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active (visible to customers)'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.product == null
                        ? 'Add Product'
                        : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
