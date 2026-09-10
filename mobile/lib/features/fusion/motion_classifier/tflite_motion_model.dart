// Real tflite_flutter wrapper for the motion classifier. Loads a .tflite
// file trained by ml/train_motion_classifier.py, which outputs 6 softmax
// probabilities (one per motion class).
//
// If the asset is missing (model not trained/bundled yet), load() throws
// and callers should fall back to ScriptedMotionClassifierAgent.

import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteMotionModel {
  Interpreter? _interpreter;
  static const int windowSize = 50;
  static const int featureCount = 9; // accel x/y/z, gyro x/y/z, mag x/y/z
  static const int numClasses = 6;

  bool get isLoaded => _interpreter != null;

  Future<void> load(String assetPath) async {
    try {
      _interpreter = await Interpreter.fromAsset(assetPath);
    } catch (e) {
      _interpreter = null;
      rethrow;
    }
  }

  /// Runs inference on a window of sensor data. Input shape: [50][9].
  /// Returns softmax probabilities for each class:
  /// [stationary, walking, drivingStraight, drivingTurn, braking, possibleTunnel]
  List<double> run(List<List<double>> features) {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('Model not loaded — call load() first.');
    }
    if (features.length != windowSize ||
        features.any((row) => row.length != featureCount)) {
      throw ArgumentError(
        'Expected [$windowSize][$featureCount] input, '
        'got [${features.length}][${features.isEmpty ? 0 : features.first.length}]',
      );
    }

    final input = [features];
    final output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

    interpreter.run(input, output);

    return List<double>.from(output[0]);
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}