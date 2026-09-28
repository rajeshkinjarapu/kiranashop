import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/network_image_box.dart';

enum _StockFilter { all, low, out }

class ManageStockScreen extends StatefulWidget {
  const ManageStockScreen({super.key});

  @override
  State<ManageStockScreen> createState() => _ManageStockScreenState();
}

class _ManageStockScreenState extends State<ManageStockScreen> {
  final _firestore = FirestoreService();
  final _searchCtrl = TextEditingController();
  final _busyIds = <String>{};
  _StockFilter _filter = _StockFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> _filtered(List<Product> all) {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = all.where((p) => p.isActive).toList();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.categoryName.toLowerCase().contains(q))
          .toList();
    }
    switch (_filter) {
      case _StockFilter.low:
        list = list.where((p) => p.stockQty > 0 && p.stockQty <= 5).toList();
      case _StockFilter.out:
        list = list.where((p) => p.stockQty <= 0).toList();
      case _StockFilter.all:
        break;
    }
    list.sort((a, b) {
      final aOut = a.stockQty <= 0;
      final bOut = b.stockQty <= 0;
      if (aOut != bOut) return aOut ? -1 : 1;
      final aLow = a.stockQty <= 5;
      final bLow = b.stockQty <= 5;
      if (aLow != bLow) return aLow ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<void> _run(String id, Future<void> Function() action) async {
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update stock: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _editQty(Product p) async {
    final ctrl = TextEditingController(text: '${p.stockQty}');
    final next = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set stock · ${p.name}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Quantity${p.unit.isNotEmpty ? ' (${p.unit})' : ''}',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v == null) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (next == null) return;
    await _run(p.id, () => _firestore.setProductStockQty(p.id, next));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final active = provider.products.where((p) => p.isActive).toList();
    final low = active.where((p) => p.stockQty > 0 && p.stockQty <= 5).length;
    final out = active.where((p) => p.stockQty <= 0).length;
    final items = _filtered(provider.products);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Manage Stock',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0265DC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                    label: 'Items',
                    value: '${active.length}',
                    color: const Color(0xFF0265DC),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: 'Low',
                    value: '$low',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: 'Out',
                    value: '$out',
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search product or category...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == _StockFilter.all,
                  onTap: () => setState(() => _filter = _StockFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Low stock',
                  selected: _filter == _StockFilter.low,
                  onTap: () => setState(() => _filter = _StockFilter.low),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Out of stock',
                  selected: _filter == _StockFilter.out,
                  onTap: () => setState(() => _filter = _StockFilter.out),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: _searchCtrl.text.trim().isEmpty
                            ? 'No products to manage'
                            : 'No matching products',
                        subtitle: 'Add products first, then update quantities here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final p = items[i];
                          final busy = _busyIds.contains(p.id);
                          return _StockTile(
                            product: p,
                            busy: busy,
                            onMinus: () => _run(
                              p.id,
                              () => _firestore.adjustProductStock(p.id, -1),
                            ),
                            onPlus: () => _run(
                              p.id,
                              () => _firestore.adjustProductStock(p.id, 1),
                            ),
                            onEditQty: () => _editQty(p),
                            onToggleInStock: (v) => _run(
                              p.id,
                              () => _firestore.updateProductStock(p.id, v),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0265DC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF0265DC) : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final Product product;
  final bool busy;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onEditQty;
  final ValueChanged<bool> onToggleInStock;

  const _StockTile({
    required this.product,
    required this.busy,
    required this.onMinus,
    required this.onPlus,
    required this.onEditQty,
    required this.onToggleInStock,
  });

  Color get _badgeColor {
    if (product.stockQty <= 0) return const Color(0xFFEF4444);
    if (product.stockQty <= 5) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String get _badgeLabel {
    if (product.stockQty <= 0) return 'Out of stock';
    if (product.stockQty <= 5) return 'Low';
    return 'In stock';
  }

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: NetworkImageBox(
                  url: product.imageUrl,
                  width: 56,
                  height: 56,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (product.categoryName.isNotEmpty) product.categoryName,
                        if (product.unit.isNotEmpty) product.unit,
                      ].join(' • '),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _badgeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    'Visible',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch.adaptive(
                    value: product.inStock,
                    onChanged: busy ? null : onToggleInStock,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: busy || product.stockQty <= 0 ? null : onMinus,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: busy ? null : onEditQty,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            '${product.stockQty}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _QtyButton(icon: Icons.add, onTap: busy ? null : onPlus),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap quantity to type a number',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? const Color(0xFF0265DC) : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
