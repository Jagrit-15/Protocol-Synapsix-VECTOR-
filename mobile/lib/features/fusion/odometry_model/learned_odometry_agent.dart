// TODO(agentic-workflow): replace with real implementation — see Learned Odometry Agent spec
//
// Real job: run a TFLite odometry model on SensorFrame + motion stateLabel and
// emit {deltaX, deltaY, deltaHeading, uncertainty} in local meters / radians.
//
// DEMO: return small randomized-but-bounded deltas. Seeded so demos are
// repeatable enough for UI, not a learned model.

import 'dart:math';

import '../../sensors/domain/sensor_frame.dart';
import '../motion_classifier/motion_state.dart';
import 'odometry_estimate.dart';

abstract class LearnedOdometryAgent {
  OdometryEstimate estimate({
    required SensorFrame frame,
    required MotionState stateLabel,
    int tickIndex = 0,
  });
}

class BoundedRandomOdometryAgent implements LearnedOdometryAgent {
  @override
  OdometryEstimate estimate({
    required SensorFrame frame,
    required MotionState stateLabel,
    int tickIndex = 0,
  }) {
    final rng = Random(tickIndex + 42 + frame.timestamp.millisecond);
    final step = switch (stateLabel) {
      MotionState.stationary => 0.05,
      MotionState.walking => 0.6,
      MotionState.drivingStraight => 2.4,
      MotionState.drivingTurn => 1.6,
      MotionState.braking => 0.4,
      MotionState.possibleTunnel => 2.0,
    };
    return OdometryEstimate(
      deltaX: (rng.nextDouble() - 0.15) * step,
      deltaY: (0.7 + rng.nextDouble() * 0.3) * step,
      deltaHeading: (rng.nextDouble() - 0.5) * 0.04,
      uncertainty: 0.8 + rng.nextDouble() * 0.4,
    );
  }
}
