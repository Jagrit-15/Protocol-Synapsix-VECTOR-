// Real FusionAgent implementation backed by ExtendedKalmanFilter. Same
// interface as your existing LinearBlendFusionAgent, so it can be
// swapped into DemoScenarioController by changing one constructor
// argument — see usage note at the bottom.
// RADIANS. If it's actually in degrees, change every `deltaHeadingRadMeas:
// odometry.deltaHeading` below to `odometry.deltaHeading * pi / 180.0`,
// and change `gnssHeadingDeg` passthrough accordingly. Check
// odometry_estimate.dart to confirm before relying on this in a demo.


import '../odometry_model/odometry_estimate.dart';
import 'ekf_state.dart';
import 'extended_kalman_filter.dart';
import 'fused_pose.dart';
import 'fusion_agent.dart';

class ExtendedKalmanFusionAgent implements FusionAgent {
  ExtendedKalmanFusionAgent({
    EkfTuning tuning = const EkfTuning(),
    Duration tickDuration = const Duration(milliseconds: 500),
  })  : _ekf = ExtendedKalmanFilter(tuning: tuning),
        _dtSeconds = tickDuration.inMilliseconds / 1000.0,
        _state = EkfState.initial();

  final ExtendedKalmanFilter _ekf;
  final double _dtSeconds;

  // Persists across calls on this instance — richer than FusedPose alone
  // can carry (full 8-dim state + covariance). `previous` is intentionally
  // unused; it only exists to satisfy the shared interface. Safe as long
  // as one instance is reused every tick (as DemoScenarioController
  // already does with its `_fusion` field).
  EkfState _state;

  @override
  FusedPose fuse({
    required FusedPose previous,
    required OdometryEstimate odometry,
    double? gnssEastM,
    double? gnssNorthM,
    double? gnssHeadingDeg,
    required bool gnssPresent,
  }) {
    final predicted = _ekf.predict(
      prev: _state,
      deltaXMeas: odometry.deltaX,
      deltaYMeas: odometry.deltaY,
      deltaHeadingRadMeas: odometry.deltaHeading, // ⚠️ see unit-check note above
      dtSeconds: _dtSeconds,
    );

    final updated = gnssPresent
        ? _ekf.update(
            predicted: predicted,
            gnssEastM: gnssEastM,
            gnssNorthM: gnssNorthM,
            gnssHeadingDeg: gnssHeadingDeg,
          )
        : predicted;

    _state = updated;

    return FusedPose(
      x: updated.posX,
      y: updated.posY,
      heading: updated.headingRad,
      covarianceMajor: updated.covarianceMajorM,
      covarianceMinor: updated.covarianceMinorM,
    );
  }

  void reset() {
    _state = EkfState.initial();
  }
}

// USAGE (not applied automatically — your demo keeps working as-is):
// In DemoScenarioController's constructor, change:
//   _fusion = fusion ?? LinearBlendFusionAgent(),
// to:
//   _fusion = fusion ?? ExtendedKalmanFusionAgent(),