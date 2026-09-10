// Real MotionClassifierAgent backed by TfliteMotionModel. Maintains a
// rolling window of recent SensorFrames and runs inference once the
// window is full. Falls back gracefully (rethrows) if the model isn't
// loaded — callers should catch and use ScriptedMotionClassifierAgent
// as a fallback until a real trained model is bundled.

import '../../sensors/domain/sensor_frame.dart';
import 'motion_classifier_agent.dart';
import 'motion_state.dart';
import 'tflite_motion_model.dart';

class TfliteMotionClassifierAgent implements MotionClassifierAgent {
  TfliteMotionClassifierAgent({required TfliteMotionModel model})
      : _model = model;

  final TfliteMotionModel _model;
  final List<SensorFrame> _window = [];

  @override
  MotionClassification classify(List<SensorFrame> window, {int tickIndex = 0}) {
    // Build up our own rolling window from the incoming frames
    _window.addAll(window);
    if (_window.length > TfliteMotionModel.windowSize) {
      _window.removeRange(
        0,
        _window.length - TfliteMotionModel.windowSize,
      );
    }

    if (_window.length < TfliteMotionModel.windowSize) {
      // Not enough history yet — return a neutral classification
      return const MotionClassification(
        stateLabel: MotionState.stationary,
        confidence: 0.5,
      );
    }

    // Extract features: [accel, gyro, mag] × [x, y, z]
    final features = _window
        .map((f) => [
              f.accel.x,
              f.accel.y,
              f.accel.z,
              f.gyro.x,
              f.gyro.y,
              f.gyro.z,
              f.mag.x,
              f.mag.y,
              f.mag.z,
            ])
        .toList();

    final probs = _model.run(features);

    // Find the class with highest probability
    double maxProb = probs[0];
    int maxIdx = 0;
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIdx = i;
      }
    }

    return MotionClassification(
      stateLabel: MotionState.values[maxIdx],
      confidence: maxProb,
    );
  }

  void reset() => _window.clear();
}