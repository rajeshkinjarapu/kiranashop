import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/shop_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/storage_service.dart';
import 'categories_manage_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = StorageService();
  final _picker = ImagePicker();

  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _deliveryCtrl;
  late final TextEditingController _minOrderCtrl;
  late final TextEditingController _upiCtrl;

  bool _isOpen = true;
  bool _saving = false;
  bool _initialized = false;
  Uint8List? _pickedLogoBytes;

  @override
  void initState() {
    super.initState();
    _shopNameCtrl = TextEditingController();
    _ownerNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _deliveryCtrl = TextEditingController();
    _minOrderCtrl = TextEditingController();
    _upiCtrl = TextEditingController();
  }

  void _initFromSettings(ShopSettings s) {
    if (_initialized) return;
    _initialized = true;
    _shopNameCtrl.text = s.shopName;
    _ownerNameCtrl.text = s.ownerName;
    _addressCtrl.text = s.address;
    _phoneCtrl.text = s.phone.replaceFirst('+91', '');
    _deliveryCtrl.text = s.deliveryCharge.toString();
    _minOrderCtrl.text = s.minimumOrder.toString();
    _upiCtrl.text = s.upiId;
    _isOpen = s.isOpen;
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _deliveryCtrl.dispose();
    _minOrderCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }
  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256, // Small size for logo base64
      imageQuality: 50, // Low quality for base64 storage efficiency
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _pickedLogoBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final current = context.read<SettingsProvider>().settings;
      String logoUrl = current.logoUrl;
      if (_pickedLogoBytes != null) {
        final base64String = base64Encode(_pickedLogoBytes!);
        logoUrl = 'data:image/jpeg;base64,$base64String';
      }
      if (!mounted) return;

      final settings = ShopSettings(
        shopName: _shopNameCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        logoUrl: logoUrl,
        address: _addressCtrl.text.trim(),
        phone: '+91${_phoneCtrl.text.trim()}',
        deliveryCharge: double.tryParse(_deliveryCtrl.text.trim()) ?? 0,
        minimumOrder: double.tryParse(_minOrderCtrl.text.trim()) ?? 0,
        upiId: _upiCtrl.text.trim(),
        isOpen: _isOpen,
      );
      await context.read<SettingsProvider>().save(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
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
    final settingsProvider = context.watch<SettingsProvider>();
    if (!settingsProvider.loading) {
      _initFromSettings(settingsProvider.settings);
    }
    final logoUrl = settingsProvider.settings.logoUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Shop Settings', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: InkWell(
                  onTap: _pickLogo,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      image: _pickedLogoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_pickedLogoBytes!),
                              fit: BoxFit.cover,
                            )
                          : (logoUrl.isNotEmpty
                              ? DecorationImage(
                                  image: logoUrl.startsWith('data:image/') 
                                    ? MemoryImage(Uri.parse(logoUrl).data!.contentAsBytes()) as ImageProvider
                                    : NetworkImage(logoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: _pickedLogoBytes == null && logoUrl.isEmpty
                        ? Icon(Icons.add_a_photo_outlined,
                            color: Colors.grey.shade400, size: 36)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                  child: Text('Shop Logo',
                      style: TextStyle(color: Colors.grey, fontSize: 13))),
              const SizedBox(height: 32),
              
              _buildTextField(
                controller: _shopNameCtrl,
                label: 'Shop Name',
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ownerNameCtrl,
                label: 'Shop Owner Name',
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressCtrl,
                label: 'Shop Address',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Mobile Number',
                prefixText: '+91 ',
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                validator: (v) => (v?.trim().length ?? 0) != 10 ? 'Enter 10 digits' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _deliveryCtrl,
                      label: 'Delivery Charge',
                      prefixText: '₹ ',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _minOrderCtrl,
                      label: 'Minimum Order',
                      prefixText: '₹ ',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _upiCtrl,
                label: 'UPI ID',
              ),
              const SizedBox(height: 24),
              
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF1E3A8A),
                title: const Text('Shop Open', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16)),
                subtitle: Text(
                  _isOpen ? 'Customers can place orders' : 'Ordering is paused',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                ),
                value: _isOpen,
                onChanged: (v) => setState(() => _isOpen = v),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Colors.grey.shade300, height: 1),
              ),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.category, color: Colors.blueGrey, size: 28),
                title: const Text('Manage Categories', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16)),
                subtitle: Text('Add or edit product categories', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesManageScreen()),
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
        ),
      ),
    );
  }
}

