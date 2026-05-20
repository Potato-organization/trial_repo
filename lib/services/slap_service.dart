import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../constants.dart';
import 'slap_impact_detector.dart';

class SlapService {
  SlapService._internal();
  static final SlapService _instance = SlapService._internal();
  factory SlapService() => _instance;

  StreamSubscription<AccelerometerEvent>? _subscription;
  StreamController<SlapImpact>? _controller;
  bool _active = false;
  double _sensitivity = AppConstants.defaultSlapSensitivity;

  Stream<SlapImpact> get onSlap {
    _controller ??= StreamController<SlapImpact>.broadcast();
    return _controller!.stream;
  }

  void start({double sensitivity = AppConstants.defaultSlapSensitivity}) {
    if (_active) return;
    _active = true;
    _sensitivity = sensitivity.clamp(0.0, 1.0);
    _controller ??= StreamController<SlapImpact>.broadcast();

    final detector = SlapImpactDetector(
      impactThreshold: _impactThresholdFor(_sensitivity),
      jerkThreshold: _jerkThresholdFor(_sensitivity),
      cooldown: AppConstants.slapDebounce,
    );

    _subscription = accelerometerEventStream().listen((event) {
      final impact = detector.addSample(
        event.x,
        event.y,
        event.z,
        DateTime.now(),
      );
      if (impact != null) {
        _controller?.add(impact);
      }
    });
  }

  void updateSensitivity(double sensitivity) {
    final nextSensitivity = sensitivity.clamp(0.0, 1.0);
    if ((_sensitivity - nextSensitivity).abs() < 0.001) return;
    _sensitivity = nextSensitivity;
    if (_active) {
      stop();
      start(sensitivity: _sensitivity);
    }
  }

  void stop() {
    _active = false;
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stop();
    _controller?.close();
    _controller = null;
  }

  double _impactThresholdFor(double sensitivity) {
    return 30.0 - (sensitivity * 14.0);
  }

  double _jerkThresholdFor(double sensitivity) {
    return 15.0 - (sensitivity * 8.0);
  }
}
