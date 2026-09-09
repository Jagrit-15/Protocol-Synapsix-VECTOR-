// State vector per Document 3 (Blueprint), Section 5:
//   x = [position_x, position_y, velocity, heading, heading_rate,
//        accel_bias_x, accel_bias_y, gyro_bias]
// Position in local ENU meters, heading in radians.

import 'dart:math';

import '../../../core/utils/matrix_utils.dart';

const int ekfStateSize = 8;
const int idxX = 0;
const int idxY = 1;
const int idxV = 2;
const int idxHeading = 3;
const int idxHeadingRate = 4;
const int idxAccelBiasX = 5;
const int idxAccelBiasY = 6;
const int idxGyroBias = 7;

class EkfState {
  EkfState({required this.x, required this.p});

  final Matrix x; // 8x1 state
  final Matrix p; // 8x8 covariance

  static EkfState initial({double tightCovarianceM = 6.0}) {
    final x0 = List<double>.filled(ekfStateSize, 0.0);
    final p0 = Matrix.identity(ekfStateSize);
    p0.set(idxX, idxX, tightCovarianceM * tightCovarianceM);
    p0.set(idxY, idxY, tightCovarianceM * tightCovarianceM);
    p0.set(idxHeading, idxHeading, 0.3);
    p0.set(idxAccelBiasX, idxAccelBiasX, 1.0);
    p0.set(idxAccelBiasY, idxAccelBiasY, 1.0);
    p0.set(idxGyroBias, idxGyroBias, 0.1);
    return EkfState(x: Matrix.columnVector(x0), p: p0);
  }

  double get posX => x.get(idxX, 0);
  double get posY => x.get(idxY, 0);
  double get headingRad => x.get(idxHeading, 0);

  /// Simplified confidence-ellipse axes for display (sqrt of x/y variance).
  double get covarianceMajorM {
    final varX = p.get(idxX, idxX);
    final varY = p.get(idxY, idxY);
    return sqrt(varX > varY ? varX : varY);
  }

  double get covarianceMinorM {
    final varX = p.get(idxX, idxX);
    final varY = p.get(idxY, idxY);
    return sqrt(varX < varY ? varX : varY);
  }
}