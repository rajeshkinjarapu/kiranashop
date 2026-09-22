import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/katha_transaction.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';

class KathaBookScreen extends StatefulWidget {
  final AppUser user;

  const KathaBookScreen({super.key, required this.user});

  @override
  State<KathaBookScreen> createState() => _KathaBookScreenState();
}

class _KathaBookScreenState extends State<KathaBookScreen> {
  Future<void> _showAddTransactionDialog(TransactionType type) async {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final isCredit = type == TransactionType.credit;

    final result = await showDialog<bool>(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isCredit ? Icons.add_shopping_cart : Icons.payments,
                      color: isCredit ? Colors.red.shade600 : Colors.green.shade600,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isCredit ? 'Give Credit (Baki)' : 'Receive Payment',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.currency_rupee, color: Colors.blueGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter amount';
                    if (double.tryParse(v) == null || double.parse(v) <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: isCredit ? 'e.g. Rice, Dal, Oil' : 'e.g. Cash, UPI',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.description_outlined, color: Colors.blueGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
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
                        
                        final tx = KathaTransaction(
                          id: '',
                          userId: widget.user.id,
                          amount: double.parse(amountCtrl.text.trim()),
                          description: descCtrl.text.trim().isNotEmpty 
                              ? descCtrl.text.trim() 
                              : (isCredit ? 'Credit given' : 'Payment received'),
                          type: type,
                        );
                        
                        try {
                          await context.read<FirestoreService>().addKathaTransaction(widget.user.id, tx);
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCredit ? Colors.red.shade600 : Colors.green.shade600,
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
    );

    amountCtrl.dispose();
    descCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<AppUser>>(
        // Listen to the user's stream to get real-time balance updates
        stream: firestore.membersStream(),
        builder: (context, userSnap) {
          final currentUserData = userSnap.data?.firstWhere((u) => u.id == widget.user.id, orElse: () => widget.user) ?? widget.user;
          final balance = currentUserData.kathaBalance;
          final isBaki = balance > 0;
          final isAdvance = balance < 0;

          return Column(
            children: [
              // Header Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Total Pending Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      '₹${balance.abs().toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isBaki ? 'Customer has to pay' : (isAdvance ? 'Advance received' : 'Account is clear'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddTransactionDialog(TransactionType.credit),
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Give Credit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.red.shade200),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddTransactionDialog(TransactionType.payment),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Receive Pay'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                          foregroundColor: Colors.green.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.green.shade200),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              
              // Transactions List
              Expanded(
                child: StreamBuilder<List<KathaTransaction>>(
                  stream: firestore.kathaStream(widget.user.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final transactions = snapshot.data ?? [];
                    if (transactions.isEmpty) {
                      return const EmptyState(
                        icon: Icons.receipt_long,
                        title: 'No Transactions',
                        subtitle: 'Credit and payments will appear here.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final tx = transactions[i];
                        final isCredit = tx.type == TransactionType.credit;
                        
                        return Card(
                          elevation: 1,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade100),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCredit ? Colors.red.shade50 : Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCredit ? Icons.shopping_bag_outlined : Icons.account_balance_wallet_outlined,
                                color: isCredit ? Colors.red.shade400 : Colors.green.shade400,
                                size: 20,
                              ),
                            ),
                            title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              tx.createdAt != null ? dateFormat.format(tx.createdAt!) : 'Just now',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                            trailing: Text(
                              '${isCredit ? '-' : '+'} ₹${tx.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isCredit ? Colors.red.shade700 : Colors.green.shade700,
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
          );
        }
      ),
    );
  }
}
