"""
Trains the motion-state classifier (Phase 3, checklist item 2):
stationary / walking / driving_straight / driving_turn / braking /
possible_tunnel — a small CNN on IMU windows, matching your
MotionState enum in mobile/lib/features/fusion/motion_classifier/motion_state.dart.

Usage:
  python train_motion_classifier.py --csv path/to/labeled_recording.csv \
      --out ../mobile/assets/models/motion_classifier.tflite

The CSV must have a 'label' column with values matching MOTION_LABELS below
EXACTLY (case-sensitive) — these must match your Dart MotionState enum.
"""

import argparse

import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

from data.windowing import load_csv, make_labeled_windows, WINDOW_SIZE, FEATURE_COLUMNS

# Must match mobile/lib/features/fusion/motion_classifier/motion_state.dart exactly
MOTION_LABELS = [
    "stationary",
    "walking",
    "drivingStraight",
    "drivingTurn",
    "braking",
    "possibleTunnel",
]


def build_model(window_size: int, n_features: int, n_classes: int) -> tf.keras.Model:
    inputs = tf.keras.Input(shape=(window_size, n_features))
    x = tf.keras.layers.Conv1D(16, 5, activation="relu")(inputs)
    x = tf.keras.layers.MaxPooling1D(2)(x)
    x = tf.keras.layers.Conv1D(32, 5, activation="relu")(x)
    x = tf.keras.layers.GlobalAveragePooling1D()(x)
    x = tf.keras.layers.Dense(16, activation="relu")(x)
    outputs = tf.keras.layers.Dense(n_classes, activation="softmax")(x)
    model = tf.keras.Model(inputs, outputs)
    model.compile(
        optimizer="adam",
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


def convert_to_tflite(model: tf.keras.Model, out_path: str):
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]  # post-training quantization
    tflite_model = converter.convert()
    with open(out_path, "wb") as f:
        f.write(tflite_model)
    size_kb = len(tflite_model) / 1024
    print(f"Wrote {out_path} ({size_kb:.1f} KB)")
    if size_kb > 2048:
        print("WARNING: model exceeds 2 MB target from buildlist Phase 3.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", required=True)
    parser.add_argument("--out", default="../mobile/assets/models/motion_classifier.tflite")
    parser.add_argument("--epochs", type=int, default=30)
    args = parser.parse_args()

    df = load_csv(args.csv)
    X, y_raw = make_labeled_windows(df)

    encoder = LabelEncoder()
    encoder.fit(MOTION_LABELS)  # fixed order, matches Dart enum index order
    y = encoder.transform(y_raw)

    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    model = build_model(WINDOW_SIZE, len(FEATURE_COLUMNS), len(MOTION_LABELS))
    model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=args.epochs,
        batch_size=32,
    )

    convert_to_tflite(model, args.out)
    print(f"Label order (must match Dart MotionState enum): {MOTION_LABELS}")


if __name__ == "__main__":
    main()