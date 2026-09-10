// Model loader service that initializes TFLite models at app startup.
// Loads motion classifier and odometry models from assets, with graceful
// fallback to scripted/random agents if models are missing.

import 'motion_classifier/tflite_motion_model.dart';
import 'motion_classifier/tflite_motion_classifier_agent.dart';
import 'motion_classifier/motion_classifier_agent.dart' as scripted;
import 'motion_classifier/motion_classifier_agent.dart';
import 'odometry_model/tflite_odometry_model.dart';
import 'odometry_model/tflite_odometry_agent.dart';
import 'odometry_model/learned_odometry_agent.dart' as random;
import 'odometry_model/learned_odometry_agent.dart';

/// Result of model loading — contains either the TFLite-backed agents
/// or the fallback implementations.
class ModelLoadResult {
  const ModelLoadResult({
    required this.motionClassifier,
    required this.odometryAgent,
    required this.motionModelLoaded,
    required this.odometryModelLoaded,
  });

  final MotionClassifierAgent motionClassifier;
  final LearnedOdometryAgent odometryAgent;
  final bool motionModelLoaded;
  final bool odometryModelLoaded;

  bool get allModelsLoaded => motionModelLoaded && odometryModelLoaded;
}

/// Loads TFLite models from assets with graceful fallback.
Future<ModelLoadResult> loadModels() async {
  final motionModel = TfliteMotionModel();
  final odometryModel = TfliteOdometryModel();

  bool motionLoaded = false;
  bool odometryLoaded = false;

  // Try loading motion classifier
  try {
    await motionModel.load('assets/models/motion_classifier.tflite');
    motionLoaded = true;
  } catch (e) {
    // Model not found — will use fallback
  }

  // Try loading odometry model
  try {
    await odometryModel.load('assets/models/odometry_model.tflite');
    odometryLoaded = true;
  } catch (e) {
    // Model not found — will use fallback
  }

  // Create agents based on what loaded
  final motionClassifier = motionLoaded
      ? TfliteMotionClassifierAgent(model: motionModel)
      : _createFallbackMotionClassifier();

  final odometryAgent = odometryLoaded
      ? TfliteOdometryAgent(model: odometryModel)
      : _createFallbackOdometryAgent();

  return ModelLoadResult(
    motionClassifier: motionClassifier,
    odometryAgent: odometryAgent,
    motionModelLoaded: motionLoaded,
    odometryModelLoaded: odometryLoaded,
  );
}

MotionClassifierAgent _createFallbackMotionClassifier() {
  return scripted.ScriptedMotionClassifierAgent();
}

LearnedOdometryAgent _createFallbackOdometryAgent() {
  return random.BoundedRandomOdometryAgent();
}