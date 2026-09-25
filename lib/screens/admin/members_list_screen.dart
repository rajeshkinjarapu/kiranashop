import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';
import 'katha_book_screen.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light background
      appBar: AppBar(
        title: const Text('Total Customers',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: firestore.membersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allMembers = snapshot.data ?? [];
                
                final members = allMembers.where((m) {
                  return m.name.toLowerCase().contains(_searchQuery) ||
                      m.phone.contains(_searchQuery);
                }).toList();

                if (allMembers.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No Members Yet',
                    subtitle: 'Registered customers will appear here.',
                  );
                }

                if (members.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No results found',
                    subtitle: 'Try a different search query.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final m = members[i];
                    final isBaki = m.kathaBalance > 0;
                    final isAdvance = m.kathaBalance < 0;

                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KathaBookScreen(user: m),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            title: Text(m.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                            subtitle: Row(
                              children: [
                                const Icon(Icons.phone_android_rounded, size: 14, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text(m.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${m.kathaBalance.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isBaki
                                        ? Colors.red.shade700
                                        : (isAdvance ? Colors.green.shade700 : Colors.grey.shade600),
                                  ),
                                ),
                                Text(
                                  isBaki ? 'Pending' : (isAdvance ? 'Advance' : 'Cleared'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isBaki
                                        ? Colors.red.shade700
                                        : (isAdvance ? Colors.green.shade700 : Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0265DC),
      ),
    );
  }

  Future<void> _showAddCustomerDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    bool obscurePassword = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Customer', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Customer Name', border: OutlineInputBorder()),
                      validator: (v) => v!.trim().isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number', 
                        border: OutlineInputBorder(), 
                        prefixText: '+91 ',
                        counterText: '',
                      ),
                      validator: (v) => v!.trim().length < 10 ? 'Enter valid number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password (6 digits)', 
                        border: const OutlineInputBorder(),
                        counterText: '',
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                      validator: (v) => v!.trim().length != 6 ? 'Enter 6-digit PIN' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => loading = true);
                          final phone = phoneCtrl.text.trim();
                          
                          // Check if user already exists
                          final existing = await FirestoreService().findUserByPhone(phone);
                          if (existing != null) {
                            setState(() => loading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Customer with this number already exists!')),
                              );
                            }
                            return;
                          }
                          
                          // Create user
                          await FirestoreService().createUser(
                            name: nameCtrl.text.trim(), 
                            phone: phone,
                            password: passwordCtrl.text.trim(),
                          );
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Customer added successfully!')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0265DC), foregroundColor: Colors.white),
                  child: loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add Customer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
