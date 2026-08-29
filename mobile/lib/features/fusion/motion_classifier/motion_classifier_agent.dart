// TODO(agentic-workflow): replace with real implementation — see Motion Classifier Agent spec
//
// Real job: run a TFLite motion model over a SensorFrame window and emit
// {stateLabel, confidence}. Labels: stationary, walking, driving_straight,
// driving_turn, braking, possible_tunnel.
//
// DEMO: ignore IMU contents. Cycle a scripted label sequence on a timer
// (driven by [tickIndex]) so the GNSS-loss tunnel scenario is visible.

import '../../sensors/domain/sensor_frame.dart';
import 'motion_state.dart';

abstract class MotionClassifierAgent {
  MotionClassification classify(List<SensorFrame> window, {int tickIndex = 0});
}

class ScriptedMotionClassifierAgent implements MotionClassifierAgent {
  static const _script = <MotionState>[
    MotionState.stationary,
    MotionState.walking,
    MotionState.drivingStraight,
    MotionState.drivingTurn,
    MotionState.braking,
    MotionState.possibleTunnel,
  ];

  @override
  MotionClassification classify(
    List<SensorFrame> window, {
    int tickIndex = 0,
  }) {
    // Advance label every ~4 seconds at 2 Hz ticks.
    final label = _script[((tickIndex + window.length) ~/ 8) % _script.length];
    return MotionClassification(stateLabel: label, confidence: 0.92);
  }
}
