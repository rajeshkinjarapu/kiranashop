import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../providers/order_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_status_chip.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final active = provider.activeOrders;
    final previous = provider.previousOrders;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Active'), Tab(text: 'Previous')],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(orders: active, emptyText: 'No active orders'),
            _OrderList(orders: previous, emptyText: 'No previous orders'),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<dynamic> orders;
  final String emptyText;

  const _OrderList({required this.orders, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyState(icon: Icons.receipt_long_outlined, title: emptyText);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final order = orders[i];
        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            title: Text(
              'Order #${order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${formatDateTime(order.createdAt)}\n${order.totalQty} items • ${formatMoney(order.total)}',
            ),
            isThreeLine: true,
            trailing: OrderStatusChip(status: order.status),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => OrderDetailsScreen(order: order)),
            ),
          ),
        );
      },
    );
  }
}
