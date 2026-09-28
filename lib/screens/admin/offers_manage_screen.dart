import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/offer.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/network_image_box.dart';
import 'offer_form_screen.dart';

class OffersManageScreen extends StatefulWidget {
  const OffersManageScreen({super.key});

  @override
  State<OffersManageScreen> createState() => _OffersManageScreenState();
}

class _OffersManageScreenState extends State<OffersManageScreen> {
  final _firestore = FirestoreService();

  Future<void> _delete(Offer offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete offer'),
        content: Text('Delete "${offer.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.deleteOffer(offer.id);
    }
  }

  void _openForm({Offer? offer}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OfferFormScreen(offer: offer)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offers = context.watch<ProductProvider>().allOffers;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Manage Offers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0265DC),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Offer'),
      ),
      body: offers.isEmpty
          ? const EmptyState(
              icon: Icons.local_offer_outlined,
              title: 'No offer banners yet',
              subtitle: 'Add a banner. Active ones show on the customer home.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: offers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final o = offers[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (o.imageUrl.isNotEmpty)
                        NetworkImageBox(
                          url: o.imageUrl,
                          height: 120,
                          width: double.infinity,
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (o.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      o.subtitle,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'Order ${o.sortOrder}',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  o.isActive ? 'On' : 'Off',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: o.isActive
                                        ? Colors.green.shade700
                                        : Colors.grey,
                                  ),
                                ),
                                Switch.adaptive(
                                  value: o.isActive,
                                  onChanged: (v) =>
                                      _firestore.updateOfferActive(o.id, v),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _openForm(offer: o),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                            ),
                            TextButton.icon(
                              onPressed: () => _delete(o),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
