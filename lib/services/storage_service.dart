import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadImage({
    required Uint8List bytes,
    required String path, // e.g. 'products/abc.jpg'
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref().child(path);
    final task = await ref
        .putData(bytes, SettableMetadata(contentType: contentType))
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw Exception(
          'Image upload timed out. This is usually caused by missing CORS configuration in Firebase Storage for web.');
    });
    return task.ref.getDownloadURL();
  }

  Future<void> deleteByUrl(String url) async {
    if (url.isEmpty) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // Ignore — file may not exist.
    }
  }
}
