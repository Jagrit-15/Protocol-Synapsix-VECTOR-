// Real EKF predict/update math (Phase 2). Pure Dart, no Flutter imports,
// per Document 9's convention. Kept as free functions on EkfState so the
// math is directly unit-testable against synthetic trajectories.

import 'dart:math';

import '../../../core/utils/matrix_utils.dart';
import 'ekf_state.dart';

double _wrapRad(double a) {
  var r = a;
  while (r > pi) {
    r -= 2 * pi;
  }
  while (r < -pi) {
    r += 2 * pi;
  }
  return r;
}

class EkfTuning {
  const EkfTuning({
    this.positionProcessNoise = 0.05,
    this.headingProcessNoise = 0.001,
    this.velocityProcessNoise = 0.5,
    this.headingRateProcessNoise = 0.05,
    this.accelBiasProcessNoise = 0.0005,
    this.gyroBiasProcessNoise = 0.0001,
    this.defaultGnssAccuracyM = 8.0,
    this.headingMeasurementNoiseRad = 0.35, // ~20 deg
  });

  final double positionProcessNoise;
  final double headingProcessNoise;
  final double velocityProcessNoise;
  final double headingRateProcessNoise;
  final double accelBiasProcessNoise;
  final double gyroBiasProcessNoise;
  final double defaultGnssAccuracyM;
  final double headingMeasurementNoiseRad;
}

class ExtendedKalmanFilter {
  ExtendedKalmanFilter({EkfTuning tuning = const EkfTuning()})
      : _tuning = tuning;

  final EkfTuning _tuning;

  /// Predict: propagate state using odometry's delta as control input,
  /// corrected for current bias estimates.
  EkfState predict({
    required EkfState prev,
    required double deltaXMeas,
    required double deltaYMeas,
    required double deltaHeadingRadMeas,
    required double dtSeconds,
  }) {
    final baX = prev.x.get(idxAccelBiasX, 0);
    final baY = prev.x.get(idxAccelBiasY, 0);
    final bg = prev.x.get(idxGyroBias, 0);

    final correctedDx = deltaXMeas - baX;
    final correctedDy = deltaYMeas - baY;
    final correctedDHeading = deltaHeadingRadMeas - bg;

    final newX = prev.x.get(idxX, 0) + correctedDx;
    final newY = prev.x.get(idxY, 0) + correctedDy;
    final newHeading = _wrapRad(prev.x.get(idxHeading, 0) + correctedDHeading);
    final dt = dtSeconds <= 0 ? 1e-3 : dtSeconds;
    final newV =
        sqrt(correctedDx * correctedDx + correctedDy * correctedDy) / dt;
    final newHeadingRate = correctedDHeading / dt;

    final xNext = Matrix.columnVector([
      newX, newY, newV, newHeading, newHeadingRate, baX, baY, bg,
    ]);

    // Jacobian: position/heading depend on previous bias estimates
    // (hence the -1 off-diagonal terms). Velocity/heading_rate are fully
    // determined by the control input each tick, not by their own prior
    // value — a deliberate simplification, since neither feeds into any
    // measurement update, so it can't corrupt the position/heading estimate.
    final f = Matrix.identity(ekfStateSize);
    f.set(idxX, idxAccelBiasX, -1.0);
    f.set(idxY, idxAccelBiasY, -1.0);
    f.set(idxV, idxV, 0.0);
    f.set(idxHeading, idxGyroBias, -1.0);
    f.set(idxHeadingRate, idxHeadingRate, 0.0);

    final q = Matrix(ekfStateSize, ekfStateSize);
    q.set(idxX, idxX, _tuning.positionProcessNoise);
    q.set(idxY, idxY, _tuning.positionProcessNoise);
    q.set(idxV, idxV, _tuning.velocityProcessNoise);
    q.set(idxHeading, idxHeading, _tuning.headingProcessNoise);
    q.set(idxHeadingRate, idxHeadingRate, _tuning.headingRateProcessNoise);
    q.set(idxAccelBiasX, idxAccelBiasX, _tuning.accelBiasProcessNoise);
    q.set(idxAccelBiasY, idxAccelBiasY, _tuning.accelBiasProcessNoise);
    q.set(idxGyroBias, idxGyroBias, _tuning.gyroBiasProcessNoise);

    final pNext = (f * prev.p * f.transpose()) + q;
    return EkfState(x: xNext, p: pNext);
  }

  /// Update: correct predicted state using GNSS position (+ optional
  /// heading). No-op if GNSS absent this tick — that's what lets
  /// covariance keep growing during an outage.
  EkfState update({
    required EkfState predicted,
    double? gnssEastM,
    double? gnssNorthM,
    double? gnssAccuracyM,
    double? gnssHeadingDeg,
  }) {
    var state = predicted;

    if (gnssEastM != null && gnssNorthM != null) {
      state = _updatePosition(
        state,
        gnssEastM: gnssEastM,
        gnssNorthM: gnssNorthM,
        accuracyM: gnssAccuracyM ?? _tuning.defaultGnssAccuracyM,
      );
    }

    if (gnssHeadingDeg != null) {
      state = _updateHeading(state, gnssHeadingRad: gnssHeadingDeg * pi / 180.0);
    }

    return state;
  }

  EkfState _updatePosition(
    EkfState state, {
    required double gnssEastM,
    required double gnssNorthM,
    required double accuracyM,
  }) {
    final h = Matrix(2, ekfStateSize);
    h.set(0, idxX, 1.0);
    h.set(1, idxY, 1.0);

    final r = Matrix(2, 2);
    final variance = accuracyM * accuracyM;
    r.set(0, 0, variance);
    r.set(1, 1, variance);

    final z = Matrix.columnVector([gnssEastM, gnssNorthM]);
    final predictedZ = h * state.x;
    final y = z - predictedZ;

    final s = (h * state.p * h.transpose()) + r;
    final k = state.p * h.transpose() * s.inverse();

    final xNew = state.x + (k * y);
    final iMinusKh = Matrix.identity(ekfStateSize) - (k * h);
    final pNew = iMinusKh * state.p;

    return EkfState(x: xNew, p: pNew);
  }

  EkfState _updateHeading(EkfState state, {required double gnssHeadingRad}) {
    final h = Matrix(1, ekfStateSize);
    h.set(0, idxHeading, 1.0);

    final r = Matrix(1, 1);
    r.set(
      0,
      0,
      _tuning.headingMeasurementNoiseRad * _tuning.headingMeasurementNoiseRad,
    );

    final predictedHeading = state.x.get(idxHeading, 0);
    final innovation = _wrapRad(gnssHeadingRad - predictedHeading);
    final y = Matrix.columnVector([innovation]);

    final s = (h * state.p * h.transpose()) + r;
    final k = state.p * h.transpose() * s.inverse();

    final xNew = state.x + (k * y);
    xNew.set(idxHeading, 0, _wrapRad(xNew.get(idxHeading, 0)));

    final iMinusKh = Matrix.identity(ekfStateSize) - (k * h);
    final pNew = iMinusKh * state.p;

    return EkfState(x: xNew, p: pNew);
  }
}