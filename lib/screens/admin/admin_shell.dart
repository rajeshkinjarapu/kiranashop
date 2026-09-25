import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_orders_screen.dart';
import 'dashboard_screen.dart';
import 'members_list_screen.dart';
import 'products_screen.dart';
import 'settings_screen.dart';
import 'admin_reports_screen.dart';
import 'categories_manage_screen.dart';
import '../../providers/settings_provider.dart';

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
    AdminReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<OrderProvider>().pendingOrdersCount;
    final shopName = context.watch<SettingsProvider>().settings.shopName;

    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                color: Colors.blue.shade50.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Icon(Icons.storefront_rounded, color: Colors.blue.shade700, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildDrawerItem(icon: Icons.home_rounded, title: 'Home', isSelected: _index == 0, onTap: () {
                      Navigator.pop(context);
                      setState(() => _index = 0);
                    }),
                    _buildDrawerItem(icon: Icons.people_alt_rounded, title: 'Customers', isSelected: _index == 3, onTap: () {
                      Navigator.pop(context);
                      setState(() => _index = 3);
                    }),
                    _buildDrawerItem(icon: Icons.inventory_2_rounded, title: 'Products', isSelected: _index == 1, onTap: () {
                      Navigator.pop(context);
                      setState(() => _index = 1);
                    }),
                    _buildDrawerItem(icon: Icons.shopping_cart_rounded, title: 'Orders', isSelected: _index == 2, onTap: () {
                      Navigator.pop(context);
                      setState(() => _index = 2);
                    }),
                    _buildDrawerItem(icon: Icons.category_rounded, title: 'Manage Category', onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesManageScreen()));
                    }),
                    _buildDrawerItem(icon: Icons.person_rounded, title: 'Profile', onTap: () {
                      Navigator.pop(context);
                      // Profile can open settings for now
                      setState(() => _index = 4);
                    }),
                    _buildDrawerItem(icon: Icons.assignment_rounded, title: 'Stock Management', onTap: () {
                      Navigator.pop(context);
                      // Just navigate to products for now, or build a specific stock screen if it exists.
                      setState(() => _index = 1); 
                    }),
                    _buildDrawerItem(icon: Icons.bar_chart_rounded, title: 'Reports', isSelected: _index == 5, onTap: () {
                      Navigator.pop(context);
                      setState(() => _index = 5);
                    }),
                    _buildDrawerItem(icon: Icons.settings_rounded, title: 'Settings', isSelected: _index == 4, onTap: () {
                      Navigator.pop(context);
                      setState(() => _index = 4);
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildDrawerItem(
                  icon: Icons.logout_rounded, 
                  title: 'Logout', 
                  iconColor: Colors.red.shade400,
                  textColor: Colors.red.shade600,
                  onTap: () async {
                    Navigator.pop(context);
                    await context.read<AuthProvider>().signOut();
                  }
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0),
                _buildNavItem(Icons.inventory_2_outlined, 'Products', 1),
                _buildNavItem(Icons.shopping_cart_outlined, 'Orders', 2, badge: pending),
                _buildNavItem(Icons.bar_chart_rounded, 'Reports', 5),
                _buildNavItem(Icons.settings_outlined, 'Settings', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon, 
          color: iconColor ?? (isSelected ? Colors.blue.shade700 : const Color(0xFF475569)),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
            color: textColor ?? (isSelected ? Colors.blue.shade900 : const Color(0xFF334155)),
          ),
        ),
        onTap: onTap,
        dense: true,
        horizontalTitleGap: 8,
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {int badge = 0}) {
    final isActive = _index == index;
    final color = isActive ? Colors.blue.shade700 : Colors.grey.shade500;
    
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.lightBlue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
