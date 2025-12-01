import 'dart:async';

/// Utility class to debounce function calls
/// Usage:
/// ```dart
/// final debouncer = Debouncer(milliseconds: 300);
/// debouncer.run(() => print('Debounced!'));
/// ```
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
