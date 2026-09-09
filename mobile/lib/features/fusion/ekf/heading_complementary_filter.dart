// Baseline heading estimator (Phase 2). Blends fast, drift-prone gyro
// integration with a slower, drift-free correction source (e.g.
// magnetometer). This is a comparison baseline — the EKF supersedes it
// once GNSS is available.

import 'dart:math';

class HeadingComplementaryFilter {
  HeadingComplementaryFilter({this.alpha = 0.98, double initialHeadingRad = 0})
      : _headingRad = initialHeadingRad;

  /// Weight given to the gyro-integrated estimate each step.
  final double alpha;

  double _headingRad;
  double get headingRad => _headingRad;
  double get headingDeg => _headingRad * 180.0 / pi;

  /// [referenceHeadingRad] is an independent heading source for this tick
  /// (e.g. magnetometer-derived), used to correct gyro drift. Pass null
  /// on ticks with no correction signal — falls back to pure gyro
  /// integration.
  void update({
    required double gyroZRad,
    required double dtSeconds,
    double? referenceHeadingRad,
  }) {
    final gyroOnly = _headingRad + gyroZRad * dtSeconds;

    if (referenceHeadingRad == null) {
      _headingRad = gyroOnly;
      return;
    }

    var corrected = referenceHeadingRad;
    while (corrected - gyroOnly > pi) {
      corrected -= 2 * pi;
    }
    while (corrected - gyroOnly < -pi) {
      corrected += 2 * pi;
    }

    _headingRad = alpha * gyroOnly + (1 - alpha) * corrected;
  }

  void reset({double headingRad = 0}) {
    _headingRad = headingRad;
  }
}