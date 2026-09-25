import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/katha_transaction.dart';
import '../../widgets/empty_state.dart';

class MyKathaScreen extends StatelessWidget {
  const MyKathaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(title: const Text('My Katha Book')),
      body: Column(
        children: [
          // Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: Colors.white70, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Amount to Pay', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        formatMoney(user.kathaBalance),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<KathaTransaction>>(
              stream: FirestoreService().kathaStream(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final txns = snapshot.data ?? [];
                if (txns.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No Transactions',
                    subtitle: 'Your katha transactions will appear here',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: txns.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final t = txns[i];
                    final isGive = t.type == 'give'; // Admin gave goods (customer owes money)
                    
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isGive ? Colors.red.shade50 : Colors.green.shade50,
                        child: Icon(
                          isGive ? Icons.shopping_cart_outlined : Icons.payments_outlined,
                          color: isGive ? Colors.red.shade600 : Colors.green.shade600,
                        ),
                      ),
                      title: Text(t.description.isEmpty ? (isGive ? 'Purchased Items' : 'Payment Made') : t.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(formatDateTime(t.createdAt)),
                      trailing: Text(
                        '${isGive ? '+' : '-'}${formatMoney(t.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isGive ? Colors.red.shade700 : Colors.green.shade700,
                          fontSize: 15,
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
    );
  }
}
