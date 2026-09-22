import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/firestore_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  static const String _adminUsername = 'rajeshkinjarapu';
  static const String _adminPassword = 'kallu0305';

  static const AppUser _adminUser = AppUser(
    id: 'admin',
    name: 'Shop Owner',
    phone: '',
    role: 'admin',
  );

  final FirestoreService _service;
  SharedPreferences? _prefs;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  String? error;
  bool busy = false;

  AuthProvider({FirestoreService? service})
      : _service = service ?? FirestoreService() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    _prefs = await SharedPreferences.getInstance();
    final role = _prefs!.getString('session_role');
    if (role == 'admin') {
      user = _adminUser;
      status = AuthStatus.authenticated;
    } else if (role == 'member') {
      user = AppUser(
        id: _prefs!.getString('session_id') ?? '',
        name: _prefs!.getString('session_name') ?? '',
        phone: _prefs!.getString('session_phone') ?? '',
        role: 'member',
      );
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _saveSession(AppUser u) async {
    await _prefs?.setString('session_role', u.role);
    await _prefs?.setString('session_id', u.id);
    await _prefs?.setString('session_name', u.name);
    await _prefs?.setString('session_phone', u.phone);
  }

  /// Returns null on success, 'not_registered' if the number is new,
  /// or 'error' on failure.
  Future<String?> memberLogin(String phone) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final found = await _service.findUserByPhone(phone);
      if (found == null) {
        busy = false;
        notifyListeners();
        return 'not_registered';
      }
      user = found;
      status = AuthStatus.authenticated;
      await _saveSession(found);
      busy = false;
      notifyListeners();
      return null;
    } catch (e) {
      error = 'Login failed. Check your internet connection and try again.';
      busy = false;
      notifyListeners();
      return 'error';
    }
  }

  /// Registers a new member. If the number already exists, logs in instead.
  Future<bool> register(String name, String phone) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final existing = await _service.findUserByPhone(phone);
      final u = existing ??
          await _service.createUser(name: name.trim(), phone: phone);
      user = u;
      status = AuthStatus.authenticated;
      await _saveSession(u);
      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = 'Registration failed. Please try again.';
      busy = false;
      notifyListeners();
      return false;
    }
  }

  bool adminLogin(String username, String password) {
    if (username.trim() == _adminUsername && password == _adminPassword) {
      user = _adminUser;
      status = AuthStatus.authenticated;
      error = null;
      _saveSession(_adminUser);
      notifyListeners();
      return true;
    }
    error = 'Invalid admin username or password';
    notifyListeners();
    return false;
  }

  Future<void> updateName(String name) async {
    final u = user;
    if (u == null || u.isAdmin) return;
    await _service.updateUserName(u.id, name);
    user = u.copyWith(name: name);
    await _saveSession(user!);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _prefs?.remove('session_role');
    await _prefs?.remove('session_id');
    await _prefs?.remove('session_name');
    await _prefs?.remove('session_phone');
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
