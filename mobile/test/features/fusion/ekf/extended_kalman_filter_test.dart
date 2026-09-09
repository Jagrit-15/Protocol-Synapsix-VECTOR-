// Phase 2 requirement: "Unit tests for filter math against a synthetic
// straight-line and circular-motion trajectory." Tests the raw EKF
// predict/update cycle directly — no dependency on OdometryEstimate.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/fusion/ekf/ekf_state.dart';
import 'package:mobile/features/fusion/ekf/extended_kalman_filter.dart';

void main() {
  group('ExtendedKalmanFilter — straight line', () {
    test('tracks a straight-line trajectory with periodic GNSS fixes', () {
      final ekf = ExtendedKalmanFilter();
      var state = EkfState.initial();

      const dt = 0.5;
      const stepDistance = 2.0 * dt;
      const totalTicks = 40;

      double trueX = 0;
      const trueY = 0.0;

      for (var tick = 0; tick < totalTicks; tick++) {
        trueX += stepDistance;

        state = ekf.predict(
          prev: state,
          deltaXMeas: stepDistance,
          deltaYMeas: 0,
          deltaHeadingRadMeas: 0,
          dtSeconds: dt,
        );

        if (tick.isEven) {
          state = ekf.update(
            predicted: state,
            gnssEastM: trueX,
            gnssNorthM: trueY,
            gnssAccuracyM: 3.0,
          );
        }
      }

      expect(state.posX, closeTo(trueX, 2.0));
      expect(state.posY, closeTo(trueY, 2.0));
      expect(state.covarianceMajorM, lessThan(6.0));
    });

    test('covariance grows during outage, shrinks on reacquire', () {
      final ekf = ExtendedKalmanFilter();
      var state = EkfState.initial();
      const dt = 0.5;

      for (var i = 0; i < 6; i++) {
        state = ekf.predict(
          prev: state,
          deltaXMeas: 1.0,
          deltaYMeas: 0,
          deltaHeadingRadMeas: 0,
          dtSeconds: dt,
        );
        state = ekf.update(
          predicted: state,
          gnssEastM: (i + 1) * 1.0,
          gnssNorthM: 0,
          gnssAccuracyM: 3.0,
        );
      }
      final covAfterGnss = state.covarianceMajorM;

      for (var i = 0; i < 40; i++) {
        state = ekf.predict(
          prev: state,
          deltaXMeas: 1.0,
          deltaYMeas: 0,
          deltaHeadingRadMeas: 0,
          dtSeconds: dt,
        );
      }
      final covAfterOutage = state.covarianceMajorM;
      expect(covAfterOutage, greaterThan(covAfterGnss));

      state = ekf.update(
        predicted: state,
        gnssEastM: state.posX,
        gnssNorthM: state.posY,
        gnssAccuracyM: 3.0,
      );
      expect(state.covarianceMajorM, lessThan(covAfterOutage));
    });
  });

  group('ExtendedKalmanFilter — circular motion', () {
    test('tracks a circular trajectory back near its start point', () {
      final ekf = ExtendedKalmanFilter();
      var state = EkfState.initial();

      const dt = 0.5;
      const radiusM = 20.0;
      const speedMPerSec = 2.0;
      final totalTime = (2 * pi * radiusM) / speedMPerSec;
      final totalTicks = (totalTime / dt).round();
      final headingRatePerTick = 2 * pi / totalTicks;

      double trueX = 0;
      double trueY = 0;
      double trueHeading = 0;

      for (var tick = 0; tick < totalTicks; tick++) {
        const stepDistance = speedMPerSec * dt;
        trueHeading += headingRatePerTick;
        trueX += stepDistance * cos(trueHeading);
        trueY += stepDistance * sin(trueHeading);

        state = ekf.predict(
          prev: state,
          deltaXMeas: stepDistance * cos(trueHeading),
          deltaYMeas: stepDistance * sin(trueHeading),
          deltaHeadingRadMeas: headingRatePerTick,
          dtSeconds: dt,
        );

        if (tick % 4 == 0) {
          state = ekf.update(
            predicted: state,
            gnssEastM: trueX,
            gnssNorthM: trueY,
            gnssAccuracyM: 3.0,
          );
        }
      }

      expect(trueX, closeTo(0, 1.0));
      expect(trueY, closeTo(0, 1.0));
      expect(state.posX, closeTo(0, 3.0));
      expect(state.posY, closeTo(0, 3.0));
    });
  });
}