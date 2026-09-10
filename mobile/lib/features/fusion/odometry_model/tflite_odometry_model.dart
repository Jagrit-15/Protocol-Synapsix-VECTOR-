// Real tflite_flutter wrapper for the learned odometry model. Loads a
// .tflite file trained by ml/train_odometry_model.py, which outputs 6
// values: [deltaX, deltaY, deltaHeading, logVarX, logVarY, logVarHeading].
//
// If the asset is missing (model not trained/bundled yet), load() throws
// and callers should fall back to BoundedRandomOdometryAgent — this keeps
// the demo working even without a real trained model present.

import 'dart:math';

import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteOdometryModel {
  Interpreter? _interpreter;
  static const int windowSize = 50;
  static const int featureCount = 9; // accel x/y/z, gyro x/y/z, mag x/y/z

  bool get isLoaded => _interpreter != null;

  Future<void> load(String assetPath) async {
    try {
      _interpreter = await Interpreter.fromAsset(assetPath);
    } catch (e) {
      _interpreter = null;
      rethrow;
    }
  }

  /// [features] must be shape [windowSize][featureCount], most recent
  /// sample last. Returns [deltaX, deltaY, deltaHeading, uncertainty]
  /// where uncertainty is a combined scalar derived from the model's
  /// per-axis variance outputs.
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
    final output = List.filled(1 * 6, 0.0).reshape([1, 6]);

    interpreter.run(input, output);

    final result = output[0] as List<double>;
    final deltaX = result[0];
    final deltaY = result[1];
    final deltaHeading = result[2];
    final logVarX = result[3];
    final logVarY = result[4];
    final logVarHeading = result[5];

    // Combine per-axis variance into one scalar uncertainty, matching the
    // OdometryEstimate.uncertainty contract used by BoundedRandomOdometryAgent.
    final avgVar = (exp(logVarX) + exp(logVarY) + exp(logVarHeading)) / 3.0;
    final uncertainty = sqrt(avgVar);

    return [deltaX, deltaY, deltaHeading, uncertainty];
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}