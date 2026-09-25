import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
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
  final _memberPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureMemberPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _memberPasswordController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _memberLogin() async {
    if (!_memberFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.memberLogin(
      _phoneController.text.trim(),
      _memberPasswordController.text.trim(),
    );
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
    } else if (result == 'invalid_password') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password. Please try again.')),
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
    final settings = context.watch<SettingsProvider>().settings;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Premium Gradient Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.height * 0.4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (settings.logoUrl.isNotEmpty)
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                          image: DecorationImage(
                            image: settings.logoUrl.startsWith('data:image/') 
                              ? MemoryImage(Uri.parse(settings.logoUrl).data!.contentAsBytes()) as ImageProvider
                              : NetworkImage(settings.logoUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_basket_rounded, size: 56, color: Colors.white),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      settings.shopName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Quality Groceries, Delivered Fast.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          
          // Form Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 160),
                child: Card(
                  elevation: 12,
                  shadowColor: AppTheme.primaryDark.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Welcome',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26, 
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to access your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14, 
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SegmentedButton<String>(
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            selectedForegroundColor: AppTheme.primary,
                          ),
                          segments: const [
                            ButtonSegment(
                              value: 'customer',
                              label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                              icon: Icon(Icons.person),
                            ),
                            ButtonSegment(
                              value: 'admin',
                              label: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                              icon: Icon(Icons.admin_panel_settings),
                            ),
                          ],
                          selected: {_mode},
                          onSelectionChanged: (s) => setState(() => _mode = s.first),
                        ),
                        const SizedBox(height: 32),
                        if (_mode == 'customer')
                          _buildCustomerForm(auth)
                        else
                          _buildAdminForm(auth),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              hintText: 'Enter your 10-digit number',
              prefixText: '+91 ',
              counterText: '',
              prefixIcon: const Icon(Icons.phone_android, color: AppTheme.primary),
              filled: true,
              fillColor: Colors.grey.shade50,
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
              if ((v?.trim().length ?? 0) != 10) {
                return 'Enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _memberPasswordController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            obscureText: _obscureMemberPassword,
            decoration: InputDecoration(
              labelText: 'Password (6 digits)',
              hintText: 'Enter 6-digit PIN',
              counterText: '',
              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureMemberPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscureMemberPassword = !_obscureMemberPassword),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
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
              if ((v?.trim().length ?? 0) != 6) {
                return 'Enter a valid 6-digit password';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          if (auth.error != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                auth.error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: auth.busy ? null : _memberLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: auth.busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("New customer? ", style: TextStyle(color: Colors.black54)),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text('Register here', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
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
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primary),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Enter username' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            validator: (v) =>
                (v?.isEmpty ?? true) ? 'Enter password' : null,
          ),
          const SizedBox(height: 24),
          if (auth.error != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                auth.error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: _adminLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Admin Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
