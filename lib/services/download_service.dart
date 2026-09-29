/// Cross-platform file download helper.
/// On web: triggers a browser blob download.
/// On other platforms: no-op (file picker save can be used instead).
export 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';
