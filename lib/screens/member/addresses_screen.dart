import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/address.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _firestore = FirestoreService();

  Future<void> _editAddress({Address? address}) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final labelCtrl = TextEditingController(text: address?.label ?? 'Home');
    final line1Ctrl = TextEditingController(text: address?.line1 ?? '');
    final line2Ctrl = TextEditingController(text: address?.line2 ?? '');
    final landmarkCtrl = TextEditingController(text: address?.landmark ?? '');
    final pincodeCtrl = TextEditingController(text: address?.pincode ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.location_on, color: Colors.blue.shade700, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        address == null ? 'Add Address' : 'Edit Address',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildAddressField(labelCtrl, 'Label (e.g. Home, Work)', Icons.label_outline),
                  const SizedBox(height: 16),
                  _buildAddressField(line1Ctrl, 'House/Flat No. & Building', Icons.home_outlined, 
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                  const SizedBox(height: 16),
                  _buildAddressField(line2Ctrl, 'Area, Street, Village', Icons.map_outlined),
                  const SizedBox(height: 16),
                  _buildAddressField(landmarkCtrl, 'Landmark (Optional)', Icons.place_outlined),
                  const SizedBox(height: 16),
                  _buildAddressField(pincodeCtrl, 'Pincode', Icons.pin_drop_outlined, isNumber: true),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          foregroundColor: Colors.black54,
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final newAddress = Address(
                            id: address?.id ?? '',
                            label: labelCtrl.text.trim(),
                            line1: line1Ctrl.text.trim(),
                            line2: line2Ctrl.text.trim(),
                            landmark: landmarkCtrl.text.trim(),
                            pincode: pincodeCtrl.text.trim(),
                            isDefault: address?.isDefault ?? false,
                          );
                          await _firestore.saveAddress(userId, newAddress,
                              id: address?.id.isEmpty == true ? null : address?.id);
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    labelCtrl.dispose();
    line1Ctrl.dispose();
    line2Ctrl.dispose();
    landmarkCtrl.dispose();
    pincodeCtrl.dispose();
    if (saved == true && mounted) setState(() {});
  }

  Widget _buildAddressField(TextEditingController controller, String label, IconData icon, {String? Function(String?)? validator, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Addresses', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editAddress(),
        icon: const Icon(Icons.add),
        label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: userId == null
          ? const SizedBox.shrink()
          : StreamBuilder<List<Address>>(
              stream: _firestore.addressesStream(userId),
              builder: (context, snapshot) {
                final addresses = snapshot.data ?? [];
                if (addresses.isEmpty && snapshot.connectionState == ConnectionState.active) {
                  return const EmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'No saved addresses',
                    subtitle: 'Add an address for faster checkout',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final a = addresses[i];
                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    a.label.toLowerCase() == 'home' ? Icons.home : (a.label.toLowerCase() == 'work' ? Icons.work : Icons.location_on),
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    a.label,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      await _editAddress(address: a);
                                    } else if (v == 'delete') {
                                      await _firestore.deleteAddress(userId, a.id);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              a.fullText,
                              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
