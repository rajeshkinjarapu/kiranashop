import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/shop_settings.dart';
import '../../providers/settings_provider.dart';
import 'categories_manage_screen.dart';
import 'offers_manage_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _deliveryCtrl;
  late final TextEditingController _minOrderCtrl;
  late final TextEditingController _upiCtrl;
  late final TextEditingController _geminiApiKeyCtrl;

  bool _isOpen = true;
  bool _saving = false;
  bool _showApiKey = false; // toggle API key visibility
  bool _initialized = false;
  Uint8List? _pickedLogoBytes;
  Uint8List? _pickedOwnerPhotoBytes;

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
    _geminiApiKeyCtrl = TextEditingController();
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
    _geminiApiKeyCtrl.text = s.geminiApiKey;
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
    _geminiApiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickOwnerPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 384,
      imageQuality: 60,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _pickedOwnerPhotoBytes = bytes);
    }
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      imageQuality: 50,
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

      String ownerPhotoUrl = current.ownerPhotoUrl;
      if (_pickedOwnerPhotoBytes != null) {
        final base64String = base64Encode(_pickedOwnerPhotoBytes!);
        ownerPhotoUrl = 'data:image/jpeg;base64,$base64String';
      }

      if (!mounted) return;

      final settings = ShopSettings(
        shopName: _shopNameCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        logoUrl: logoUrl,
        ownerPhotoUrl: ownerPhotoUrl,
        address: _addressCtrl.text.trim(),
        phone: '+91${_phoneCtrl.text.trim()}',
        deliveryCharge: double.tryParse(_deliveryCtrl.text.trim()) ?? 0,
        minimumOrder: double.tryParse(_minOrderCtrl.text.trim()) ?? 0,
        upiId: _upiCtrl.text.trim(),
        geminiApiKey: _geminiApiKeyCtrl.text.trim(),
        isOpen: _isOpen,
      );
      await context.read<SettingsProvider>().save(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings & Photos saved successfully!'),
            backgroundColor: Colors.green,
          ),
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

  ImageProvider? _getImageProvider(Uint8List? pickedBytes, String networkOrDataUrl) {
    if (pickedBytes != null) {
      return MemoryImage(pickedBytes);
    }
    if (networkOrDataUrl.isNotEmpty) {
      if (networkOrDataUrl.startsWith('data:image/')) {
        try {
          return MemoryImage(Uri.parse(networkOrDataUrl).data!.contentAsBytes());
        } catch (_) {
          return null;
        }
      } else {
        return NetworkImage(networkOrDataUrl);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    if (!settingsProvider.loading) {
      _initFromSettings(settingsProvider.settings);
    }
    final currentSettings = settingsProvider.settings;

    final ownerImgProvider = _getImageProvider(_pickedOwnerPhotoBytes, currentSettings.ownerPhotoUrl);
    final logoImgProvider = _getImageProvider(_pickedLogoBytes, currentSettings.logoUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Shop & Profile Settings', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── PHOTO UPLOAD SECTION (Owner Photo & Shop Logo) ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 1. OWNER / PERSONAL PHOTO
                    Column(
                      children: [
                        Stack(
                          children: [
                            InkWell(
                              onTap: _pickOwnerPhoto,
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blue.shade700, width: 2.5),
                                  image: ownerImgProvider != null
                                      ? DecorationImage(
                                          image: ownerImgProvider,
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: ownerImgProvider == null
                                    ? Icon(Icons.person_rounded,
                                        color: Colors.blue.shade300, size: 48)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickOwnerPhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0265DC),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Owner Photo',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),

                    Container(height: 80, width: 1, color: Colors.grey.shade200),

                    // 2. SHOP LOGO
                    Column(
                      children: [
                        Stack(
                          children: [
                            InkWell(
                              onTap: _pickLogo,
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: 2),
                                  image: logoImgProvider != null
                                      ? DecorationImage(
                                          image: logoImgProvider,
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: logoImgProvider == null
                                    ? Icon(Icons.storefront_rounded,
                                        color: Colors.grey.shade400, size: 44)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickLogo,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Shop Logo',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

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
                label: 'UPI ID (e.g. 9502924437@ybl)',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _geminiApiKeyCtrl,
                label: 'Gemini AI API Key (for Auto Product Filling)',
                obscureText: !_showApiKey,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showApiKey ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 20,
                  ),
                  tooltip: _showApiKey ? 'Hide key' : 'Show key',
                  onPressed: () => setState(() => _showApiKey = !_showApiKey),
                ),
              ),
              const SizedBox(height: 20),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF1E3A8A),
                title: const Text('Shop Open', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _isOpen ? 'Customers can place orders' : 'Ordering is paused',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                value: _isOpen,
                onChanged: (v) => setState(() => _isOpen = v),
              ),

              const SizedBox(height: 24),
              const Divider(height: 32),
              
              // ── CATEGORIES & OFFERS SHORTCUTS ──
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.category_outlined, color: Colors.blue),
                ),
                title: const Text('Manage Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Add, edit, or reorder item categories', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesManageScreen()),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.local_offer_outlined, color: Colors.orange),
                ),
                title: const Text('Manage Offers & Banners', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Create promotional banners on home screen', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OffersManageScreen()),
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0265DC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Save Settings & Photo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        counterText: '',
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: Color(0xFF0265DC), width: 1.5),
        ),
      ),
    );
  }
}
