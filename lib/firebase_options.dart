import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDtzLM_FDyvq_QZDrub_OVquRw7loil1VU',
    appId: '1:993487197686:android:6d6f405c93b58b270fa3d7',
    messagingSenderId: '993487197686',
    projectId: 'kirana-shop-f2406',
    authDomain: 'kirana-shop-f2406.firebaseapp.com',
    storageBucket: 'kirana-shop-f2406.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtzLM_FDyvq_QZDrub_OVquRw7loil1VU',
    appId: '1:993487197686:android:6d6f405c93b58b270fa3d7',
    messagingSenderId: '993487197686',
    projectId: 'kirana-shop-f2406',
    storageBucket: 'kirana-shop-f2406.firebasestorage.app',
  );
}
