/// Ground-truth label used when a recording is exported for classifier
/// training. The string values deliberately match the Python training script
/// and the MotionState enum order.
enum SensorRecordingLabel {
  stationary('stationary'),
  walking('walking'),
  drivingStraight('drivingStraight'),
  drivingTurn('drivingTurn'),
  braking('braking'),
  possibleTunnel('possibleTunnel');

  const SensorRecordingLabel(this.csvValue);

  final String csvValue;
}
