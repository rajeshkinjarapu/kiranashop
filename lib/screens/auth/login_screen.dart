import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _mode = 'customer'; // customer | admin

  final _memberFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _memberLogin() async {
    if (!_memberFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.memberLogin(_phoneController.text.trim());
    if (!mounted) return;
    if (result == 'not_registered') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Number not registered. Please register first.')),
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              RegisterScreen(initialPhone: _phoneController.text.trim()),
        ),
      );
    }
    // On success RootRouter automatically navigates to Member Home.
  }

  void _adminLogin() {
    if (!_adminFormKey.currentState!.validate()) return;
    context
        .read<AuthProvider>()
        .adminLogin(_usernameController.text, _passwordController.text);
    // On success RootRouter automatically navigates to Admin Dashboard.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 96,
                  width: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront,
                      size: 56, color: AppTheme.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kirana Shop',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'customer',
                        label: Text('Customer'),
                        icon: Icon(Icons.person)),
                    ButtonSegment(
                        value: 'admin',
                        label: Text('Admin'),
                        icon: Icon(Icons.admin_panel_settings)),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                const SizedBox(height: 24),
                if (_mode == 'customer')
                  _buildCustomerForm(auth)
                else
                  _buildAdminForm(auth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerForm(AuthProvider auth) {
    return Form(
      key: _memberFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              prefixText: '+91 ',
              counterText: '',
              prefixIcon: Icon(Icons.phone_android),
            ),
            validator: (v) {
              if ((v?.trim().length ?? 0) != 10) {
                return 'Enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (auth.error != null) ...[
            Text(auth.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: auth.busy ? null : _memberLogin,
            child: auth.busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Login'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            child: const Text('New customer? Register here'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminForm(AuthProvider auth) {
    return Form(
      key: _adminFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Enter username' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                (v?.isEmpty ?? true) ? 'Enter password' : null,
          ),
          const SizedBox(height: 16),
          if (auth.error != null) ...[
            Text(auth.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: _adminLogin,
            child: const Text('Admin Login'),
          ),
        ],
      ),
    );
  }
}
