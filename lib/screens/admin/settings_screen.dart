import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/shop_settings.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import 'categories_manage_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late TabController _tabController;

  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _deliveryCtrl;
  late final TextEditingController _minOrderCtrl;
  late final TextEditingController _upiCtrl;
  late final TextEditingController _geminiApiKeyCtrl;
  late final TextEditingController _imageApiKeyCtrl;

  bool _isOpen = true;
  bool _saving = false;
  bool _initialized = false;
  Uint8List? _pickedLogoBytes;
  Uint8List? _pickedOwnerPhotoBytes;
  Uint8List? _pickedQrBytes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _shopNameCtrl = TextEditingController();
    _ownerNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _deliveryCtrl = TextEditingController();
    _minOrderCtrl = TextEditingController();
    _upiCtrl = TextEditingController();
    _geminiApiKeyCtrl = TextEditingController();
    _imageApiKeyCtrl = TextEditingController();
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
    _imageApiKeyCtrl.text = s.imageApiKey;
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
    _imageApiKeyCtrl.dispose();
    _tabController.dispose();
    super.dispose();
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

  Future<void> _pickOwnerPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      imageQuality: 50,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _pickedOwnerPhotoBytes = bytes);
    }
  }

  Future<void> _pickQrCode() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 70,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _pickedQrBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final current = context.read<SettingsProvider>().settings;
      String logoUrl = current.logoUrl;
      String ownerPhotoUrl = current.ownerPhotoUrl;
      String qrCodeUrl = current.qrCodeUrl;
      
      if (_pickedLogoBytes != null) {
        final base64String = base64Encode(_pickedLogoBytes!);
        logoUrl = 'data:image/jpeg;base64,$base64String';
      }
      
      if (_pickedOwnerPhotoBytes != null) {
        final base64String = base64Encode(_pickedOwnerPhotoBytes!);
        ownerPhotoUrl = 'data:image/jpeg;base64,$base64String';
      }
      
      if (_pickedQrBytes != null) {
        final base64String = base64Encode(_pickedQrBytes!);
        qrCodeUrl = 'data:image/jpeg;base64,$base64String';
      }
      
      if (!mounted) return;

      final settings = ShopSettings(
        shopName: _shopNameCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        ownerPhotoUrl: ownerPhotoUrl,
        logoUrl: logoUrl,
        address: _addressCtrl.text.trim(),
        phone: '+91${_phoneCtrl.text.trim()}',
        deliveryCharge: double.tryParse(_deliveryCtrl.text.trim()) ?? 0,
        minimumOrder: double.tryParse(_minOrderCtrl.text.trim()) ?? 0,
        upiId: _upiCtrl.text.trim(),
        qrCodeUrl: qrCodeUrl,
        isOpen: _isOpen,
        geminiApiKey: _geminiApiKeyCtrl.text.trim(),
        imageApiKey: _imageApiKeyCtrl.text.trim(),
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
    
    final activeColors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
    ];
    final currentActiveColor = activeColors[_tabController.index];

    return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
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
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelPadding: EdgeInsets.zero,
                  indicatorColor: currentActiveColor,
                  indicatorWeight: 4,
                  tabs: [
                    _buildCustomTab(0, 'Shop', activeColors[0]),
                    _buildCustomTab(1, 'Member', activeColors[1]),
                    _buildCustomTab(2, 'Payment', activeColors[2]),
                    _buildCustomTab(3, 'Product', activeColors[3]),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildShopSettingsTab(settingsProvider.settings),
                    _buildMemberSettingsTab(),
                    _buildPaymentSettingsTab(settingsProvider.settings.qrCodeUrl),
                    _buildProductSettingsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildCustomTab(int index, String title, Color activeColor) {
    final isSelected = _tabController.index == index;
    return Tab(
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? activeColor : Colors.grey.shade600,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildShopSettingsTab(ShopSettings settings) {
    final logoUrl = settings.logoUrl;
    final ownerPhotoUrl = settings.ownerPhotoUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  InkWell(
                    onTap: _pickLogo,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        image: _pickedLogoBytes != null
                            ? DecorationImage(image: MemoryImage(_pickedLogoBytes!), fit: BoxFit.cover)
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
                          ? Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 36)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Shop Logo', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              Column(
                children: [
                  InkWell(
                    onTap: _pickOwnerPhoto,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        image: _pickedOwnerPhotoBytes != null
                            ? DecorationImage(image: MemoryImage(_pickedOwnerPhotoBytes!), fit: BoxFit.cover)
                            : (ownerPhotoUrl.isNotEmpty
                                ? DecorationImage(
                                    image: ownerPhotoUrl.startsWith('data:image/') 
                                      ? MemoryImage(Uri.parse(ownerPhotoUrl).data!.contentAsBytes()) as ImageProvider
                                      : NetworkImage(ownerPhotoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      child: _pickedOwnerPhotoBytes == null && ownerPhotoUrl.isEmpty
                          ? Icon(Icons.person_add_alt_1_outlined, color: Colors.grey.shade400, size: 36)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Owner Photo', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
          ),
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
          
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProductSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Product & Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage product-related configurations and categories.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
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
          const Text(
            'AI Features',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure API keys to auto-generate product descriptions and images.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _geminiApiKeyCtrl,
            label: 'Gemini API Key',
            hint: 'Enter your Gemini API Key for descriptions',
            icon: Icons.key_outlined,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _imageApiKeyCtrl,
            label: 'Image API Key',
            hint: 'Enter OpenAI or other Image API Key (Optional)',
            icon: Icons.image_outlined,
            isPassword: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSettingsTab() {
    return StreamBuilder<List<AppUser>>(
      stream: FirestoreService().membersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('No members found.'));
        }
        
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', 
                    style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)
                  ),
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.phone),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber.shade200)
                      ),
                      child: Text('Password: ${user.password.isEmpty ? "Not set" : user.password}', 
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                      tooltip: 'Reset Password',
                      onPressed: () => _showResetPasswordDialog(context, user),
                    ),
                    Chip(
                      label: Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      backgroundColor: user.isAdmin ? Colors.red.shade50 : Colors.green.shade50,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showResetPasswordDialog(BuildContext context, AppUser user) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set new password for ${user.name}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await FirestoreService().updateUserPassword(user.id, ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSettingsTab(String qrCodeUrl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'UPI Payment Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your UPI ID and upload a QR code image so customers can pay easily.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          _buildTextField(
            controller: _upiCtrl,
            label: 'UPI ID (e.g. number@upi)',
          ),
          const SizedBox(height: 32),
          
          const Text(
            'Shop QR Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          
          Center(
            child: InkWell(
              onTap: _pickQrCode,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  image: _pickedQrBytes != null
                      ? DecorationImage(image: MemoryImage(_pickedQrBytes!), fit: BoxFit.contain)
                      : (qrCodeUrl.isNotEmpty
                          ? DecorationImage(
                              image: qrCodeUrl.startsWith('data:image/') 
                                ? MemoryImage(Uri.parse(qrCodeUrl).data!.contentAsBytes()) as ImageProvider
                                : NetworkImage(qrCodeUrl),
                              fit: BoxFit.contain,
                            )
                          : null),
                ),
                child: _pickedQrBytes == null && qrCodeUrl.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, color: Colors.blue.shade300, size: 48),
                          const SizedBox(height: 12),
                          const Text('Tap to upload QR Code', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          if (_pickedQrBytes != null || qrCodeUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _pickQrCode,
                icon: const Icon(Icons.edit),
                label: const Text('Change QR Code'),
              ),
            ),
          ]
        ],
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
    String? hint,
    IconData? icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: validator,
      obscureText: isPassword,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade500) : null,
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
