import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/shop_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/storage_service.dart';

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
      maxWidth: 512,
      imageQuality: 85,
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
        logoUrl = await _storage.uploadImage(
          bytes: _pickedLogoBytes!,
          path: 'shop/logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
      if (!mounted) return;

      final settings = ShopSettings(
        shopName: _shopNameCtrl.text.trim(),
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
      appBar: AppBar(title: const Text('Shop Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: InkWell(
                  onTap: _pickLogo,
                  borderRadius: BorderRadius.circular(50),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _pickedLogoBytes != null
                        ? MemoryImage(_pickedLogoBytes!)
                        : (logoUrl.isNotEmpty
                            ? NetworkImage(logoUrl) as ImageProvider
                            : null),
                    child: _pickedLogoBytes == null && logoUrl.isEmpty
                        ? Icon(Icons.add_a_photo,
                            color: Colors.grey.shade500, size: 32)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                  child: Text('Shop Logo',
                      style: TextStyle(color: Colors.grey, fontSize: 12))),
              const SizedBox(height: 20),
              TextFormField(
                controller: _shopNameCtrl,
                decoration: const InputDecoration(labelText: 'Shop Name'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Enter shop name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Shop Address', alignLabelWithHint: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  counterText: '',
                ),
                validator: (v) => (v?.trim().length ?? 0) != 10
                    ? 'Enter a valid 10-digit number'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _deliveryCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Delivery Charge', prefixText: '\u20B9 '),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minOrderCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Minimum Order', prefixText: '\u20B9 '),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _upiCtrl,
                decoration: const InputDecoration(
                    labelText: 'UPI ID', hintText: 'shopname@upi'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Shop Open'),
                subtitle: Text(_isOpen
                    ? 'Customers can place orders'
                    : 'Ordering is paused'),
                value: _isOpen,
                onChanged: (v) => setState(() => _isOpen = v),
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
                    : const Text('Save Settings'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () => context.read<AuthProvider>().signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
