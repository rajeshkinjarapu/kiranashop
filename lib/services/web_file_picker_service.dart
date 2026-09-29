/// Cross-platform file picker service.
/// Web: uses dart:html FileUploadInputElement directly.
/// Other platforms: returns null (caller should use FilePicker package).
export 'web_file_picker_stub.dart'
    if (dart.library.html) 'web_file_picker_web.dart';
