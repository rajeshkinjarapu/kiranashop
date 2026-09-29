import 'dart:async';

/// Stub for non-web platforms — returns null (use FilePicker instead)
Future<Map<String, dynamic>?> pickFileWeb(List<String> allowedExtensions) async {
  return null;
}
