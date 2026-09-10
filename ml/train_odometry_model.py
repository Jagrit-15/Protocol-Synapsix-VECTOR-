"""
Trains the learned odometry/displacement estimator (Phase 3, checklist
items 4-5): predicts (deltaX, deltaY, deltaHeading) from an IMU window,
with a heteroscedastic uncertainty output (the model predicts its own
variance, not just a point estimate).

Requires ground-truth position track alongside your IMU recording (e.g.
from GPS during an outdoor test walk/drive) — see windowing.py's
make_odometry_windows().

Usage:
  python train_odometry_model.py --csv path/to/gt_recording.csv \
      --gt-x gt_x --gt-y gt_y --gt-heading gt_heading \
      --out ../mobile/assets/models/odometry_model.tflite
"""

import argparse

import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split

from data.windowing import load_csv, make_odometry_windows, WINDOW_SIZE, FEATURE_COLUMNS


def negative_log_likelihood(y_true, y_pred):
    """Heteroscedastic loss: y_pred has 6 outputs — 3 means + 3 log-variances.
    Penalizes confident-but-wrong predictions more than uncertain-but-wrong
    ones, which is what teaches the model to output honest uncertainty."""
    mean = y_pred[:, :3]
    log_var = y_pred[:, 3:]
    precision = tf.exp(-log_var)
    return tf.reduce_mean(
        0.5 * precision * tf.square(y_true - mean) + 0.5 * log_var
    )


def build_model(window_size: int, n_features: int) -> tf.keras.Model:
    inputs = tf.keras.Input(shape=(window_size, n_features))
    x = tf.keras.layers.Conv1D(24, 5, activation="relu")(inputs)
    x = tf.keras.layers.MaxPooling1D(2)(x)
    x = tf.keras.layers.Conv1D(48, 5, activation="relu")(x)
    x = tf.keras.layers.GlobalAveragePooling1D()(x)
    x = tf.keras.layers.Dense(32, activation="relu")(x)
    # 3 mean outputs (deltaX, deltaY, deltaHeading) + 3 log-variance outputs
    outputs = tf.keras.layers.Dense(6, activation="linear")(x)
    model = tf.keras.Model(inputs, outputs)
    model.compile(optimizer="adam", loss=negative_log_likelihood)
    return model


def convert_to_tflite(model: tf.keras.Model, out_path: str):
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    with open(out_path, "wb") as f:
        f.write(tflite_model)
    size_kb = len(tflite_model) / 1024
    print(f"Wrote {out_path} ({size_kb:.1f} KB)")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", required=True)
    parser.add_argument("--gt-x", required=True)
    parser.add_argument("--gt-y", required=True)
    parser.add_argument("--gt-heading", required=True)
    parser.add_argument("--out", default="../mobile/assets/models/odometry_model.tflite")
    parser.add_argument("--epochs", type=int, default=40)
    args = parser.parse_args()

    df = load_csv(args.csv)
    X, y = make_odometry_windows(df, args.gt_x, args.gt_y, args.gt_heading)

    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    model = build_model(WINDOW_SIZE, len(FEATURE_COLUMNS))
    model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=args.epochs,
        batch_size=32,
    )

    convert_to_tflite(model, args.out)


if __name__ == "__main__":
    main()