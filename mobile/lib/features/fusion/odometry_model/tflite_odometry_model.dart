// PLACEHOLDER tflite_flutter wrapper for learned odometry.
// Real interpreter load/run lands in a later slice. Model files are gitignored.

import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteOdometryModel {
  Interpreter? _interpreter;

  Future<void> load(String assetPath) async {
    _interpreter = assetPath.isEmpty ? null : null;
  }

  List<double> run(List<double> features) {
    if (_interpreter == null) {
      return const [0.0, 0.0, 0.0, 1.0];
    }
    return const [0.0, 0.0, 0.0, 1.0];
  }
}
