// Naive dead reckoning: double-integrates raw accelerometer for position,
// integrates gyro for heading. Deliberately unfiltered and uncorrected —
// this is the buildlist's "before" baseline, meant to be shown next to
// the EKF's output to demonstrate improvement.

import '../../sensors/domain/sensor_frame.dart';

class NaiveDrState {
  const NaiveDrState({
    required this.x,
    required this.y,
    required this.headingRad,
    required this.velocityX,
    required this.velocityY,
  });

  final double x;
  final double y;
  final double headingRad;
  final double velocityX;
  final double velocityY;

  static const zero = NaiveDrState(
    x: 0,
    y: 0,
    headingRad: 0,
    velocityX: 0,
    velocityY: 0,
  );
}

class NaiveDoubleIntegrationDr {
  NaiveDrState _state = NaiveDrState.zero;
  DateTime? _lastTimestamp;

  NaiveDrState get state => _state;

  /// Assumes accel x/y are roughly world-aligned already — a known
  /// simplification kept on purpose so this baseline stays "naive."
  void step(SensorFrame frame) {
    final now = frame.timestamp;
    final last = _lastTimestamp;
    _lastTimestamp = now;
    if (last == null) return;

    final dt = now.difference(last).inMicroseconds / 1e6;
    if (dt <= 0 || dt > 2.0) return;

    final headingRad = _state.headingRad + frame.gyro.z * dt;
    final velocityX = _state.velocityX + frame.accel.x * dt;
    final velocityY = _state.velocityY + frame.accel.y * dt;
    final x = _state.x + velocityX * dt;
    final y = _state.y + velocityY * dt;

    _state = NaiveDrState(
      x: x,
      y: y,
      headingRad: headingRad,
      velocityX: velocityX,
      velocityY: velocityY,
    );
  }

  void reset() {
    _state = NaiveDrState.zero;
    _lastTimestamp = null;
  }
}