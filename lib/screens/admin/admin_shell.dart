import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import 'admin_orders_screen.dart';
import 'dashboard_screen.dart';
import 'members_list_screen.dart';
import 'products_screen.dart';
import 'settings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    ProductsScreen(),
    AdminOrdersScreen(),
    MembersListScreen(),
    SettingsScreen(),
  ];

  Widget _buildNavItem(IconData icon, String label, int index, {int badge = 0}) {
    final isActive = _index == index;
    final color = isActive ? Colors.blue.shade700 : Colors.grey.shade500;
    
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.redAccent,
              child: Icon(icon, color: color, size: 26),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<OrderProvider>().pendingOrdersCount;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard_rounded, 'Dashboard', 0),
                _buildNavItem(Icons.inventory_2_rounded, 'Products', 1),
                _buildNavItem(Icons.receipt_long_rounded, 'Orders', 2, badge: pending),
                _buildNavItem(Icons.people_alt_rounded, 'Members', 3),
                _buildNavItem(Icons.settings_rounded, 'Settings', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
