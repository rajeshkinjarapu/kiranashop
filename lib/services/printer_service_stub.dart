// Stub for non-web platforms (Android, iOS, Windows)
class DocumentStub {
  ElementStub? getElementById(String id) => null;
  ElementStub? body;
}

class ElementStub {
  void remove() {}
  void append(dynamic element) {}
  dynamic style;
  String? id;
}

class WindowStub {
  void print() {}
}

class IFrameElement extends ElementStub {
  dynamic contentWindow;
}

final document = DocumentStub();
final window = WindowStub();
