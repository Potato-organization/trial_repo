import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'constants.dart';

/// Singleton foreground shake detector.
///
/// BackgroundService runs in a separate Dart isolate and maintains its own
/// accelerometer subscription — sharing a singleton across isolates is not
/// possible. This service handles the *foreground* case only.
class ShakeService {
  ShakeService._internal();
  static final ShakeService _instance = ShakeService._internal();
  factory ShakeService() => _instance;

  StreamSubscription<AccelerometerEvent>? _subscription;
  final StreamController<void> _controller = StreamController<void>.broadcast();
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  bool _active = false;

  /// Emits `void` every time a shake that passes [sensitivity] is detected.
  Stream<void> get onShake => _controller.stream;

  void start(double sensitivity) {
    if (_active) return;
    _active = true;
    _subscription = accelerometerEventStream().listen((event) {
      final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (mag > sensitivity) {
        final now = DateTime.now();
        if (now.difference(_lastShake) > AppConstants.shakeDebounce) {
          _lastShake = now;
          _controller.add(null);
        }
      }
    });
  }

  void stop() {
    _active = false;
    _subscription?.cancel();
    _subscription = null;
  }

  /// Restart with updated sensitivity without skipping any events.
  void updateSensitivity(double sensitivity) {
    if (_active) {
      stop();
      start(sensitivity);
    }
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
