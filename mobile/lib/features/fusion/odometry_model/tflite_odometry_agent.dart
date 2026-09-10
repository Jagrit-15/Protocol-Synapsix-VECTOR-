// Real LearnedOdometryAgent backed by TfliteOdometryModel. Maintains a
// rolling window of recent SensorFrames and runs inference once the
// window is full. Falls back gracefully (rethrows) if the model isn't
// loaded — callers should catch and use BoundedRandomOdometryAgent
// as a fallback until a real trained model is bundled.

import '../../sensors/domain/sensor_frame.dart';
import '../motion_classifier/motion_state.dart';
import 'learned_odometry_agent.dart';
import 'odometry_estimate.dart';
import 'tflite_odometry_model.dart';

class TfliteOdometryAgent implements LearnedOdometryAgent {
  TfliteOdometryAgent({required TfliteOdometryModel model}) : _model = model;

  final TfliteOdometryModel _model;
  final List<SensorFrame> _window = [];

  @override
  OdometryEstimate estimate({
    required SensorFrame frame,
    required MotionState stateLabel,
    int tickIndex = 0,
  }) {
    _window.add(frame);
    if (_window.length > TfliteOdometryModel.windowSize) {
      _window.removeAt(0);
    }

    if (_window.length < TfliteOdometryModel.windowSize) {
      // Not enough history yet — return a zero estimate rather than
      // guessing, so early ticks don't inject fake motion into the EKF.
      return const OdometryEstimate(
        deltaX: 0,
        deltaY: 0,
        deltaHeading: 0,
        uncertainty: 1.0,
      );
    }

    final features = _window
        .map((f) => [
              f.accel.x, f.accel.y, f.accel.z,
              f.gyro.x, f.gyro.y, f.gyro.z,
              f.mag.x, f.mag.y, f.mag.z,
            ])
        .toList();

    final result = _model.run(features);
    return OdometryEstimate(
      deltaX: result[0],
      deltaY: result[1],
      deltaHeading: result[2],
      uncertainty: result[3],
    );
  }

  void reset() => _window.clear();
}