import 'package:chaos/services/slap_impact_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects sharp slap impacts and cooldown', () {
    final detector = SlapImpactDetector(
      impactThreshold: 18,
      jerkThreshold: 10,
      cooldown: const Duration(milliseconds: 600),
    );

    final start = DateTime(2026, 1, 1);

    expect(
      detector.addSample(0, 0, 9.8, start),
      isNull,
      reason: 'baseline should not slap',
    );
    final impact = detector.addSample(
      0,
      0,
      28,
      start.add(const Duration(milliseconds: 100)),
    );
    expect(impact, isNotNull, reason: 'sudden high-impact sample should slap');
    expect(impact!.timestamp, start.add(const Duration(milliseconds: 100)));
    expect(impact.magnitude, 28);
    expect(impact.jerk, closeTo(18.2, 0.001));
    expect(impact.force, inInclusiveRange(0.0, 1.0));
    expect(impact.force, greaterThan(0));

    expect(
      detector.addSample(
        0,
        0,
        29,
        start.add(const Duration(milliseconds: 200)),
      ),
      isNull,
      reason: 'cooldown should suppress immediate duplicate slap',
    );
    expect(
      detector.addSample(
        0,
        0,
        9.8,
        start.add(const Duration(milliseconds: 800)),
      ),
      isNull,
      reason: 'return to baseline should not slap',
    );
    expect(
      detector.addSample(
        0,
        0,
        30,
        start.add(const Duration(milliseconds: 900)),
      ),
      isNotNull,
      reason: 'slap after cooldown should fire again',
    );
  });

  test('clamps force to normalized range for very hard impacts', () {
    final detector = SlapImpactDetector(
      impactThreshold: 18,
      jerkThreshold: 10,
      cooldown: const Duration(milliseconds: 600),
    );

    final start = DateTime(2026, 1, 1);

    expect(detector.addSample(0, 0, 9.8, start), isNull);
    final impact = detector.addSample(
      0,
      0,
      200,
      start.add(const Duration(milliseconds: 100)),
    );

    expect(impact, isNotNull);
    expect(impact!.force, 1.0);
  });

  test('ignores smooth movement that crosses impact threshold slowly', () {
    final detector = SlapImpactDetector(
      impactThreshold: 18,
      jerkThreshold: 10,
      cooldown: const Duration(milliseconds: 600),
    );

    final start = DateTime(2026, 1, 1);
    final samples = <double>[9.8, 12, 15, 18.5, 20, 21];

    for (var i = 0; i < samples.length; i += 1) {
      expect(
        detector.addSample(
          0,
          0,
          samples[i],
          start.add(Duration(milliseconds: i * 100)),
        ),
        isNull,
        reason: 'gradual motion should not count as a slap',
      );
    }
  });

  test('requires both impact and jerk thresholds', () {
    final detector = SlapImpactDetector(
      impactThreshold: 24,
      jerkThreshold: 12,
      cooldown: const Duration(milliseconds: 600),
    );

    final start = DateTime(2026, 1, 1);

    expect(detector.addSample(0, 0, 9.8, start), isNull);
    expect(
      detector.addSample(
        0,
        0,
        21,
        start.add(const Duration(milliseconds: 100)),
      ),
      isNull,
      reason: 'strong jump without enough impact should not trigger',
    );
    expect(
      detector.addSample(
        0,
        0,
        26,
        start.add(const Duration(milliseconds: 800)),
      ),
      isNull,
      reason: 'enough impact without enough jerk should not trigger',
    );
  });
}
