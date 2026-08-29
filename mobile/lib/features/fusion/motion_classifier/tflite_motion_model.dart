// PLACEHOLDER tflite_flutter wrapper for the motion classifier.
// Real interpreter load/run lands in a later slice. Model files are gitignored.

import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteMotionModel {
  Interpreter? _interpreter;

  Future<void> load(String assetPath) async {
    // PLACEHOLDER: Interpreter.fromAsset(assetPath)
    _interpreter = assetPath.isEmpty ? null : null;
  }

  List<double> run(List<double> window) {
    if (_interpreter == null) {
      return List<double>.filled(6, 0);
    }
    return List<double>.filled(6, 0);
  }
}
