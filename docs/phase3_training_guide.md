# Phase 3: ML Model Training Guide

Complete workflow for collecting sensor data, training models, and deploying them to the Flutter app.

## Prerequisites

- Flutter app running on a physical device (emulator lacks real IMU sensors)
- Python 3.8+ with TensorFlow 2.16+
- Mobile device with GPS enabled for outdoor recordings

## Step 1: Collect Training Data

### For Motion Classifier (stationary/walking/driving/etc.)

1. Open the app and navigate to **Sensor Debug** screen (via the debug menu or route `/sensor-debug`)

2. Ensure the sensor pipeline is running (green "Pipeline running" chip)

3. **Record each motion class:**
   
   For each of the 6 motion classes, record at least 2-3 minutes:
   
   - **stationary**: Stand still or sit
   - **walking**: Walk at normal pace
   - **drivingStraight**: Drive on a straight road
   - **drivingTurn**: Make turns while driving
   - **braking**: Brake and slow down repeatedly
   - **possibleTunnel**: Drive in conditions where GPS might drop (optional for initial training)

4. **Recording workflow:**
   - Tap **"Start recording"** (button turns red)
   - Perform the motion for 2-3 minutes
   - Tap **"Label"** and select the correct motion class
   - Tap **"Stop recording"**
   - Repeat for each motion class

5. **Export the recordings:**
   - Each recording appears in the list with its label
   - Tap the download icon (📥) on each recording
   - Share/save the CSV files to your computer
   - Name them descriptively: `walking.csv`, `driving_straight.csv`, etc.

### For Odometry Model (displacement estimation)

The odometry model requires ground-truth position data. Two options:

**Option A: Outdoor recording with GPS (recommended)**
1. Record while walking or driving in an area with good GPS reception
2. The GNSS data is logged automatically alongside IMU
3. After stopping the recording, you'll need to compute ground truth (see Step 2)

**Option B: Combine multiple motion classifier recordings**
- Merge several labeled recordings into one CSV
- This provides more training data but ground truth will be less accurate

## Step 2: Prepare CSV Files

### Motion Classifier CSV

The exported CSVs should already have this format:

```csv
ts_ms,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,mag_x,mag_y,mag_z,label
1234567890,0.12,0.45,9.81,0.01,0.02,0.01,20.3,0.5,40.2,walking
...
```

**Combine multiple recordings:**
```bash
# On Windows (PowerShell)
Get-Content walking.csv, driving_straight.csv, driving_turn.csv | 
  Select-Object -Skip 3 | 
  Out-File -Encoding utf8 combined_classifier.csv

# Manually add header as first line:
ts_ms,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,mag_x,mag_y,mag_z,label
```

**Quality checks:**
- At least 50 samples per class (ideally 500+)
- No NaN or infinite values
- All 6 classes represented
- Reasonable class balance (no class should be <10% of total)

### Odometry CSV with Ground Truth

For recordings with GNSS data, you need to convert lat/lon to local ENU coordinates:

```python
# compute_ground_truth.py (create this helper script)
import pandas as pd
import numpy as np
import math

def lat_lon_to_enu(lat, lon, origin_lat, origin_lon):
    """Convert lat/lon to local East-North-Up meters"""
    meters_per_deg_lat = 111320.0
    meters_per_deg_lon = 111320.0 * math.cos(math.radians(origin_lat))
    
    east_m = (lon - origin_lon) * meters_per_deg_lon
    north_m = (lat - origin_lat) * meters_per_deg_lat
    return east_m, north_m

def process_odometry_csv(input_csv, output_csv):
    df = pd.read_csv(input_csv)
    
    # Use first GPS fix as origin
    origin_lat = df['gnss_lat'].iloc[0]
    origin_lon = df['gnss_lon'].iloc[0]
    
    # Compute local coordinates for each sample
    east, north = zip(*[
        lat_lon_to_enu(row['gnss_lat'], row['gnss_lon'], origin_lat, origin_lon)
        for _, row in df.iterrows()
    ])
    
    df['gt_x'] = east
    df['gt_y'] = north
    df['gt_heading'] = df['gnss_heading_deg']
    
    # Save with ground truth columns
    df.to_csv(output_csv, index=False)
    print(f"Wrote {output_csv} with {len(df)} samples")

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python compute_ground_truth.py input.csv output.csv")
        sys.exit(1)
    process_odometry_csv(sys.argv[1], sys.argv[2])
```

Run it:
```bash
python compute_ground_truth.py recording_with_gps.csv odometry_training.csv
```

## Step 3: Train the Motion Classifier

```bash
cd ml
python train_motion_classifier.py \
  --csv ../data/combined_classifier.csv \
  --out ../mobile/assets/models/motion_classifier.tflite \
  --epochs 30
```

**Expected output:**
```
Epoch 30/30
... training progress ...
Wrote ../mobile/assets/models/motion_classifier.tflite (45.2 KB)
Label order (must match Dart MotionState enum): ['stationary', 'walking', 'drivingStraight', 'drivingTurn', 'braking', 'possibleTunnel']
```

**Check the results:**
- Model size < 2 MB ✓
- Validation accuracy > 80% (ideally > 90%)
- No single class dominates the confusion matrix

## Step 4: Train the Odometry Model

```bash
python train_odometry_model.py \
  --csv ../data/odometry_training.csv \
  --gt-x gt_x \
  --gt-y gt_y \
  --gt-heading gt_heading \
  --out ../mobile/assets/models/odometry_model.tflite \
  --epochs 40
```

**Expected output:**
```
Epoch 40/40
... training progress ...
Wrote ../mobile/assets/models/odometry_model.tflite (67.8 KB)
```

**Check the results:**
- Model size < 2 MB ✓
- Validation loss decreasing consistently
- No NaN losses (if you see NaN, your ground truth may have issues)

## Step 5: Deploy Models to Flutter

The models are already in the correct location (`mobile/assets/models/`), but you need to implement the TFLite wrappers.

### 5.1: Implement Motion Classifier TFLite Wrapper

Edit `mobile/lib/features/fusion/motion_classifier/tflite_motion_model.dart`:

```dart
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteMotionModel {
  Interpreter? _interpreter;
  static const int windowSize = 50;
  static const int featureCount = 9;
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

  /// Returns probabilities for each class [0..5]
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

    return (output[0] as List<double>);
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
```

### 5.2: Wire the Classifier into the Agent

Create `mobile/lib/features/fusion/motion_classifier/tflite_motion_classifier_agent.dart`:

```dart
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
    _window.addAll(window);
    if (_window.length > TfliteMotionModel.windowSize) {
      _window.removeRange(0, _window.length - TfliteMotionModel.windowSize);
    }

    if (_window.length < TfliteMotionModel.windowSize) {
      return const MotionClassification(
        stateLabel: MotionState.stationary,
        confidence: 0.5,
      );
    }

    final features = _window
        .map((f) => [
              f.accel.x, f.accel.y, f.accel.z,
              f.gyro.x, f.gyro.y, f.gyro.z,
              f.mag.x, f.mag.y, f.mag.z,
            ])
        .toList();

    final probs = _model.run(features);
    final maxIdx = probs.indexOf(probs.reduce((a, b) => a > b ? a : b));

    return MotionClassification(
      stateLabel: MotionState.values[maxIdx],
      confidence: probs[maxIdx],
    );
  }

  void reset() => _window.clear();
}
```

### 5.3: Load Models at App Startup

Update `mobile/lib/main.dart` or your fusion initialization:

```dart
// Initialize models
final motionModel = TfliteMotionModel();
final odometryModel = TfliteOdometryModel();

try {
  await motionModel.load('assets/models/motion_classifier.tflite');
  await odometryModel.load('assets/models/odometry_model.tflite');
  print('✓ Models loaded successfully');
} catch (e) {
  print('⚠ Models not found, using fallback agents: $e');
}
```

## Step 6: Test and Measure Latency

Run the app on a physical device and measure inference time:

```dart
final stopwatch = Stopwatch()..start();
final classification = motionClassifier.classify(window);
stopwatch.stop();
print('Motion classifier latency: ${stopwatch.elapsedMilliseconds}ms');

stopwatch.reset();
stopwatch.start();
final odometry = odometryAgent.estimate(frame: frame, stateLabel: classification.stateLabel);
stopwatch.stop();
print('Odometry latency: ${stopwatch.elapsedMilliseconds}ms');
```

**Target:** < 50ms total inference time (both models combined)

## Troubleshooting

### "CSV missing required columns"
- Ensure exported CSV has exactly these columns: `ts_ms,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,mag_x,mag_y,mag_z,label`
- No extra spaces, correct spelling, lowercase

### "Not enough samples" / "Not enough windows"
- Each recording needs at least 50 samples (25 seconds at 2Hz sampling)
- For training, aim for 100+ windows per class (200+ samples)

### Model size > 2 MB
- Reduce epochs or model complexity in training scripts
- Use post-training quantization (already enabled in scripts)

### High validation loss for odometry
- Ground truth GPS might be noisy
- Try smoothing GPS coordinates before computing ground truth
- Record in open areas with good GPS reception

### TFLite model won't load
- Check that `assets/models/` is listed in `pubspec.yaml` under `flutter: assets:`
- Run `flutter clean && flutter pub get`
- Verify `.tflite` files are NOT in `.gitignore`

### Inference latency > 50ms
- Test on release build, not debug
- Profile on actual target device
- Consider reducing window size (but requires retraining)

## Summary Checklist

- [ ] Recorded 2-3 minutes per motion class (6 classes)
- [ ] Exported and combined CSVs
- [ ] Computed ground truth for odometry CSV
- [ ] Trained motion classifier successfully
- [ ] Trained odometry model successfully
- [ ] Both models < 2 MB
- [ ] Implemented TFLite wrappers in Flutter
- [ ] Loaded models at app startup
- [ ] Verified inference latency < 50ms on target device
- [ ] Tested end-to-end: sensor → classifier → odometry → fusion

## Next Steps (Phase 4+)

After training and deploying the models:
- Integrate real EKF fusion (replace LinearBlendFusionAgent with ExtendedKalmanFusionAgent)
- Add map matching (HMM-based OSM snap)
- Test the complete pipeline in real tunnel scenarios
- Collect more diverse training data to improve model accuracy
