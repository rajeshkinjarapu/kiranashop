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
import '../../providers/settings_provider.dart';
import 'package:http/http.dart' as http;

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
  late final TextEditingController _originalPriceCtrl;
  late final TextEditingController _unitQtyCtrl;
  late final TextEditingController _stockCtrl;

  Category? _selectedCategory;
  String _selectedUnitType = 'kg';
  final List<String> _unitTypes = ['kg', 'g', 'L', 'ml', 'Piece', 'Packet', 'Dozen', 'Box'];
  
  bool _inStock = true;
  bool _isFeatured = false;
  bool _isActive = true;
  bool _saving = false;
  bool _autoFilling = false;
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
    _originalPriceCtrl =
        TextEditingController(text: p?.originalPrice != null ? p!.originalPrice.toString() : '');
        
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
    _originalPriceCtrl.dispose();
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

  Future<void> _autoFillWithAI() async {
    final settings = context.read<SettingsProvider>().settings;
    if (settings.geminiApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add Gemini API key in Product Settings')));
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter product name first')));
      return;
    }

    setState(() => _autoFilling = true);
    try {
      final categories = context.read<ProductProvider>().categories;
      final categoryNames = categories.map((c) => c.name).join(', ');

      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${settings.geminiApiKey}');
      final prompt = '''
Product Name: $name
Available Categories: $categoryNames

Task:
1. Translate the product name to English (if it is in Telugu). This is for image generation.
2. Write a short, attractive 2-line product description in **Telugu** (తెలుగు).
3. If the 'Available Categories' list is not empty, pick the BEST matching category. If it is empty or none match, invent a short, appropriate category name in English (e.g. Vegetables, Spices, Fruits).

Respond ONLY in valid JSON format like this:
{
  "englishName": "...",
  "description": "...",
  "category": "..."
}
''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts":[{"text": prompt}]}]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gemini Error ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body);
      String text = data['candidates'][0]['content']['parts'][0]['text'];
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(text);

      final englishName = parsed['englishName'] ?? name;
      final desc = parsed['description'] ?? '';
      final categoryName = parsed['category'] ?? '';

      if (desc.isNotEmpty) _descCtrl.text = desc;

      if (categoryName.isNotEmpty) {
        final match = categories.where((c) => c.name.toLowerCase() == categoryName.toString().toLowerCase()).firstOrNull;
        if (match != null) {
          _selectedCategory = match;
        } else {
          // Auto create missing category!
          final newCatId = DateTime.now().millisecondsSinceEpoch.toString();
          final newCat = Category(id: newCatId, name: categoryName, imageUrl: '');
          await _firestore.saveCategory(newCat, id: newCatId);
          
          // Manually add it to the local provider list so the dropdown doesn't crash
          categories.add(newCat);
          _selectedCategory = newCat;
        }
      }

      if (settings.imageApiKey.isNotEmpty) {
        final imgUrl = Uri.parse('https://api.openai.com/v1/images/generations');
        final imgResp = await http.post(
          imgUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${settings.imageApiKey}'
          },
          body: jsonEncode({
            "model": "dall-e-3",
            "prompt": "A professional product photography shot of $englishName, high quality, isolated on a clean white background, studio lighting",
            "n": 1,
            "size": "1024x1024"
          }),
        );
        if (imgResp.statusCode == 200) {
          final imgData = jsonDecode(imgResp.body);
          final finalResp = await http.get(Uri.parse(imgData['data'][0]['url']));
          _pickedImageBytes = finalResp.bodyBytes;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OpenAI Error ${imgResp.statusCode}')));
        }
      } else {
        final p = Uri.encodeComponent("Professional product photography of $englishName grocery item, high quality, isolated on white background, studio lighting");
        final pUrl = 'https://image.pollinations.ai/prompt/$p?width=512&height=512&nologo=true';
        
        // Fetch bytes using a reliable proxy (AllOrigins) to avoid Cloudflare/CORS blocks on Web
        final proxyUrl = Uri.parse('https://api.allorigins.win/raw?url=${Uri.encodeComponent(pUrl)}');
        final pResp = await http.get(proxyUrl);
        
        if (pResp.statusCode == 200) {
          _pickedImageBytes = pResp.bodyBytes;
          _existingImageUrl = ''; // clear old url
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pollinations Error ${pResp.statusCode} (Proxy failed)')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e')));
    } finally {
      if (mounted) setState(() => _autoFilling = false);
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
        originalPrice: _originalPriceCtrl.text.trim().isNotEmpty ? double.tryParse(_originalPriceCtrl.text.trim()) : null,
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  suffixIcon: _nameCtrl.text.isNotEmpty || true
                    ? Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.purple, Colors.deepPurple]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: _autoFilling 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome, color: Colors.white),
                          tooltip: 'Auto Fill with AI',
                          onPressed: _autoFilling ? null : _autoFillWithAI,
                        ),
                      )
                    : null,
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Enter product name' : null,
              ),
              if (_nameCtrl.text.isEmpty || true) ...[
                const SizedBox(height: 6),
                const Text('💡 Enter name and click the magic wand to auto-fill everything!', style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
              const SizedBox(height: 16),
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
                      controller: _originalPriceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                          labelText: 'MRP (Optional)', prefixText: '\u20B9 '),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          labelText: 'Selling Price', prefixText: '\u20B9 '),
                      validator: (v) =>
                          (double.tryParse(v?.trim() ?? '') ?? 0) <= 0
                              ? 'Enter valid price'
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
              const SizedBox(height: 12),
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
