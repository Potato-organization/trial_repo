import 'dart:math';

class SlapImpact {
  const SlapImpact({
    required this.timestamp,
    required this.force,
    required this.magnitude,
    required this.jerk,
  });

  final DateTime timestamp;
  final double force;
  final double magnitude;
  final double jerk;
}

class SlapImpactDetector {
  SlapImpactDetector({
    required this.impactThreshold,
    required this.jerkThreshold,
    required this.cooldown,
  });

  final double impactThreshold;
  final double jerkThreshold;
  final Duration cooldown;

  double? _lastMagnitude;
  DateTime? _lastImpactAt;

  SlapImpact? addSample(double x, double y, double z, DateTime timestamp) {
    final magnitude = sqrt(x * x + y * y + z * z);
    final jerk = _lastMagnitude == null
        ? 0.0
        : (magnitude - _lastMagnitude!).abs();
    _lastMagnitude = magnitude;

    final isImpact = magnitude >= impactThreshold && jerk >= jerkThreshold;
    if (!isImpact) return null;

    final cooldownElapsed =
        _lastImpactAt == null ||
        timestamp.difference(_lastImpactAt!) >= cooldown;
    if (!cooldownElapsed) {
      return null;
    }

    _lastImpactAt = timestamp;
    return SlapImpact(
      timestamp: timestamp,
      force: _forceFor(magnitude: magnitude, jerk: jerk),
      magnitude: magnitude,
      jerk: jerk,
    );
  }

  bool didSlap(double x, double y, double z, DateTime timestamp) {
    return addSample(x, y, z, timestamp) != null;
  }

  double _forceFor({required double magnitude, required double jerk}) {
    final impactRange = max(impactThreshold, 1.0);
    final jerkRange = max(jerkThreshold, 1.0);
    final impactStrength = (magnitude - impactThreshold) / impactRange;
    final jerkStrength = (jerk - jerkThreshold) / jerkRange;
    return ((impactStrength + jerkStrength) / 2).clamp(0.0, 1.0).toDouble();
  }
}
