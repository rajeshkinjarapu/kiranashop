import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation — uses dart:html FileUploadInputElement
Future<Map<String, dynamic>?> pickFileWeb(List<String> allowedExtensions) async {
  final completer = Completer<Map<String, dynamic>?>();

  final input = html.FileUploadInputElement()
    ..accept = allowedExtensions.map((e) => '.$e').join(',');

  // Listen before click
  input.onChange.listen((event) {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoad.listen((_) {
        final result = reader.result;
        if (result is List<int>) {
          completer.complete({'name': file.name, 'bytes': result});
        } else {
          // convert Uint8List / ByteBuffer
          final bytes = (result as dynamic).asUint8List() as List<int>;
          completer.complete({'name': file.name, 'bytes': bytes});
        }
      });
      reader.onError.listen((_) {
        if (!completer.isCompleted) completer.complete(null);
      });
    } else {
      if (!completer.isCompleted) completer.complete(null);
    }
  });

  input.click();

  // Timeout after 5 minutes
  Future.delayed(const Duration(minutes: 5), () {
    if (!completer.isCompleted) completer.complete(null);
  });

  return completer.future;
}
