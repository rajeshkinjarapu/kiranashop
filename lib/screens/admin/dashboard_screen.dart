import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/order_status_chip.dart';
import '../member/notifications_screen.dart';
import 'admin_order_details_screen.dart';
import 'product_form_screen.dart';
import 'manage_stock_screen.dart';
import 'admin_reports_screen.dart';
import 'settings_screen.dart';
import '../../models/app_user.dart';
import 'members_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final products = context.watch<ProductProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final auth = context.watch<AuthProvider>();

    return Material(
      color: const Color(0xFFF8FAFC),
      child: CustomScrollView(
        slivers: [
          // ── Top Blue Header ──
          SliverToBoxAdapter(
            child: _DashboardHeader(
              shopName: settings.shopName,
              userId: auth.user?.id ?? '',
            ),
          ),

          // ── Profile Stats Card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _ProfileStatsCard(
                adminName: settings.ownerName,
                todaysSales: orders.todaysSales,
              ),
            ),
          ),

          // ── Overview Section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  _SectionTitle(
                    title: 'Overview',
                    icon: Icons.bar_chart_rounded,
                  ),
                  const SizedBox(height: 16),
                  
                  // 2x2 Grid for Stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Products',
                          value: '${products.products.length}',
                          icon: Icons.inventory_2_rounded,
                          iconColor: const Color(0xFF10B981), // Green
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StreamBuilder<List<AppUser>>(
                          stream: FirestoreService().membersStream(),
                          builder: (context, snapshot) {
                            final totalCustomers = snapshot.data?.length ?? 0;
                            return _StatCard(
                              title: 'Total Customers',
                              value: totalCustomers.toString(),
                              icon: Icons.people_alt_rounded,
                              iconColor: const Color(0xFF3B82F6), // Blue
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersListScreen()));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Orders',
                          value: '${orders.todaysOrdersCount}',
                          icon: Icons.assignment_rounded,
                          iconColor: const Color(0xFFF97316), // Orange
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Stock',
                          value: 'Low (${products.lowStockCount})',
                          icon: Icons.inventory_rounded,
                          iconColor: const Color(0xFFEF4444), // Red
                          valueColor: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Quick Actions ──
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _QuickActionsList(),

                  const SizedBox(height: 28),

                  // ── Recent Orders ──
                  _SectionTitle(
                    title: 'Recent Orders',
                    icon: Icons.receipt_long_rounded,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Recent Orders List ──
          if (orders.recentOrders.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No orders yet',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text('New orders will appear here',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final order = orders.recentOrders[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _OrderCard(order: order),
                  );
                },
                childCount: orders.recentOrders.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

// ──────────────── Top Header ────────────────

class _DashboardHeader extends StatelessWidget {
  final String shopName;
  final String userId;

  const _DashboardHeader({
    required this.shopName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0265DC),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              Text(
                shopName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              StreamBuilder<List<NotificationModel>>(
                stream: FirestoreService().notificationsStream(userId),
                builder: (context, snapshot) {
                  final notifications = snapshot.data ?? [];
                  final unreadCount = notifications.where((n) => !n.isRead).length;

                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────── Profile Stats Card ────────────────

class _ProfileStatsCard extends StatelessWidget {
  final String adminName;
  final double todaysSales;

  const _ProfileStatsCard({
    required this.adminName,
    required this.todaysSales,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0265DC).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFF0265DC), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  adminName,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 6),
                Text(
                  'Total Sales Today',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                Text(
                  formatMoney(todaysSales),
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────── Section Title ────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0F172A), size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// ──────────────── Grid Stat Card ────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? const Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ──────────────── Quick Actions List ────────────────

class _QuickActionsList extends StatelessWidget {
  const _QuickActionsList();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA(
        label: 'Add Product', 
        icon: Icons.add_box_rounded, 
        color: const Color(0xFF3B82F6),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen())),
      ),
      _QA(
        label: 'Manage Stock', 
        icon: Icons.inventory_rounded, 
        color: const Color(0xFF10B981),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageStockScreen())),
      ),
      _QA(
        label: 'View Reports', 
        icon: Icons.bar_chart_rounded, 
        color: const Color(0xFFEF4444),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen())),
      ),
      _QA(
        label: 'Settings', 
        icon: Icons.settings_rounded, 
        color: const Color(0xFF64748B),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: actions.asMap().entries.map((entry) {
          final index = entry.key;
          final a = entry.value;
          final isLast = index == actions.length - 1;
          
          return Column(
            children: [
              InkWell(
                onTap: a.onTap,
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: isLast ? const Radius.circular(16) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(a.icon, color: a.color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        a.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Container(height: 1, color: Colors.black.withValues(alpha: 0.05)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _QA {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QA({required this.label, required this.icon, required this.color, required this.onTap});
}

// ──────────────── Order Card ────────────────

class _OrderCard extends StatelessWidget {
  final dynamic order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 6
        ? order.id.substring(0, 6).toUpperCase()
        : order.id.toUpperCase();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminOrderDetailsScreen(order: order),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_rounded,
                  color: Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #$shortId',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.customerName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(order.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                OrderStatusChip(status: order.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
