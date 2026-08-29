enum MotionState {
  stationary,
  walking,
  drivingStraight,
  drivingTurn,
  braking,
  possibleTunnel,
}

class MotionClassification {
  const MotionClassification({
    required this.stateLabel,
    required this.confidence,
  });

  final MotionState stateLabel;
  final double confidence;
}
