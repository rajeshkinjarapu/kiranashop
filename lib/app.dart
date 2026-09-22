import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/member/member_shell.dart';

class KiranaShopApp extends StatelessWidget {
  const KiranaShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kirana Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const RootRouter(),
    );
  }
}

/// Routes by auth state and role: admin -> AdminShell, member -> MemberShell.
class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        final user = auth.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final orders = context.read<OrderProvider>();
        if (user.isAdmin) {
          orders.listenAllOrders();
          return const AdminShell();
        } else {
          orders.listenUserOrders(user.id);
          return const MemberShell();
        }
    }
  }
}
