import 'dart:async';

class TextBroadcaster {
  static final StreamController<String> _controller =
      StreamController<String>.broadcast();

  static Stream<String> getTextStream() {
    return _controller.stream;
  }

  static void addText(String text) {
    _controller.add(text);
  }
}
