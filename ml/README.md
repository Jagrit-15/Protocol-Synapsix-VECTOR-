# ML Training (`ml/`)

Training scripts for the motion classifier and odometry models.

## Files

- `train_motion_classifier.py` — Trains CNN to classify motion state from IMU windows
- `train_odometry_model.py` — Trains regression model with heteroscedastic uncertainty
- `data/windowing.py` — Sliding window feature extraction
- `requirements.txt` — Python dependencies

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Train motion classifier (requires labeled CSV with 'label' column)
python train_motion_classifier.py --csv ../data/classifier_data.csv --out ../mobile/assets/models/motion_classifier.tflite

# Train odometry model (requires ground-truth position columns)
python train_odometry_model.py --csv ../data/odometry_data.csv --gt-x gt_x --gt-y gt_y --gt-heading gt_heading --out ../mobile/assets/models/odometry_model.tflite
```

## Data Collection

See `docs/phase3_training_guide.md` for the complete workflow:
1. Record sensor data using the Flutter app (Sensor Debug screen)
2. Export recordings to CSV
3. Combine and label recordings for classifier training
4. Compute ground-truth coordinates for odometry training

## Output

Trained `.tflite` models go to `mobile/assets/models/` (gitignored — never commit binaries).

## Requirements

- Python 3.8+
- TensorFlow 2.16+
- NumPy, Pandas, scikit-learn

See `requirements.txt` for pinned versions.