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
      builder: (ctx) => AlertDialog(
        title: Text(address == null ? 'Add Address' : 'Edit Address'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Label (Home/Work)'),
                ),
                TextFormField(
                  controller: line1Ctrl,
                  decoration: const InputDecoration(labelText: 'Address line 1'),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                TextFormField(
                  controller: line2Ctrl,
                  decoration: const InputDecoration(labelText: 'Address line 2'),
                ),
                TextFormField(
                  controller: landmarkCtrl,
                  decoration: const InputDecoration(labelText: 'Landmark'),
                ),
                TextFormField(
                  controller: pincodeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pincode'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    labelCtrl.dispose();
    line1Ctrl.dispose();
    line2Ctrl.dispose();
    landmarkCtrl.dispose();
    pincodeCtrl.dispose();
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editAddress(),
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
      body: userId == null
          ? const SizedBox.shrink()
          : StreamBuilder<List<Address>>(
              stream: _firestore.addressesStream(userId),
              builder: (context, snapshot) {
                final addresses = snapshot.data ?? [];
                if (addresses.isEmpty) {
                  return const EmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'No saved addresses',
                    subtitle: 'Add an address for faster checkout',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final a = addresses[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(a.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(a.fullText),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await _editAddress(address: a);
                            } else if (v == 'delete') {
                              await _firestore.deleteAddress(userId, a.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
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
