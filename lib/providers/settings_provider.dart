import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/shop_settings.dart';
import '../services/firestore_service.dart';

class SettingsProvider extends ChangeNotifier {
  final FirestoreService _service;

  ShopSettings settings = const ShopSettings();
  bool loading = true;

  StreamSubscription<ShopSettings>? _sub;

  SettingsProvider({FirestoreService? service})
      : _service = service ?? FirestoreService() {
    _sub = _service.settingsStream().listen((data) {
      settings = data;
      loading = false;
      notifyListeners();
    }, onError: (_) {
      loading = false;
      notifyListeners();
    });
  }

  Future<void> save(ShopSettings newSettings) async {
    await _service.saveSettings(newSettings);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
