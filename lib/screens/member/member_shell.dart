import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'categories_screen.dart'; // Which is now ProductsScreen
import 'home_screen.dart';
import 'profile_screen.dart';
import 'my_katha_screen.dart';

class MemberShell extends StatefulWidget {
  const MemberShell({super.key});

  @override
  State<MemberShell> createState() => _MemberShellState();
}

class _MemberShellState extends State<MemberShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    CategoriesScreen(), // This is the Products screen now
    MyKathaScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed, // To show all labels for 5 items
        selectedItemColor: const Color(0xFF10B981), // matching the image
        unselectedItemColor: Colors.grey.shade400,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: 'Products'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded), label: 'Katha'),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
