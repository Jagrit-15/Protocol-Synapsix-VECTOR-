"""
Converts raw IMU sample sequences into fixed-size sliding windows suitable
for training the motion classifier and odometry models.

Expected input CSV columns (one row per sample):
  ts_ms, accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z,
  mag_x, mag_y, mag_z, label (only required for classifier training)

This matches the schema your app's RawSensorLogDb writes to SQLite, so you
can export your own recordings (mobile/lib/features/sensors/data/
raw_sensor_log_db.dart -> raw_sensor_samples table) straight into this
format via a simple SQLite-to-CSV export.
"""

import numpy as np
import pandas as pd

WINDOW_SIZE = 50   # ~1 second at 50Hz, or ~2.5s at 20Hz — tune to your sample rate
STEP_SIZE = 25      # 50% overlap between windows

FEATURE_COLUMNS = [
    "accel_x", "accel_y", "accel_z",
    "gyro_x", "gyro_y", "gyro_z",
    "mag_x", "mag_y", "mag_z",
]


def load_csv(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    missing = [c for c in FEATURE_COLUMNS if c not in df.columns]
    if missing:
        raise ValueError(f"CSV missing required columns: {missing}")
    return df.sort_values("ts_ms").reset_index(drop=True)


def make_windows(df: pd.DataFrame, window_size: int = WINDOW_SIZE,
                  step_size: int = STEP_SIZE):
    """Returns (X, meta) where X has shape (n_windows, window_size, n_features)."""
    features = df[FEATURE_COLUMNS].to_numpy(dtype=np.float32)
    n_samples = len(features)
    windows = []
    starts = []
    for start in range(0, n_samples - window_size + 1, step_size):
        windows.append(features[start:start + window_size])
        starts.append(start)
    X = np.stack(windows) if windows else np.empty((0, window_size, len(FEATURE_COLUMNS)))
    return X, starts


def make_labeled_windows(df: pd.DataFrame, window_size: int = WINDOW_SIZE,
                          step_size: int = STEP_SIZE):
    """For classifier training — requires a 'label' column. Uses the
    majority label within each window."""
    if "label" not in df.columns:
        raise ValueError("CSV must have a 'label' column for classifier training")

    X, starts = make_windows(df, window_size, step_size)
    labels = df["label"].to_numpy()
    y = []
    for start in starts:
        window_labels = labels[start:start + window_size]
        values, counts = np.unique(window_labels, return_counts=True)
        y.append(values[np.argmax(counts)])
    return X, np.array(y)


def make_odometry_windows(df: pd.DataFrame, gt_x_col: str, gt_y_col: str,
                           gt_heading_col: str, window_size: int = WINDOW_SIZE,
                           step_size: int = STEP_SIZE):
    """For odometry regression training — requires ground-truth position/
    heading columns (e.g. from a recorded GPS track or motion capture),
    and computes the true displacement across each window as the label."""
    X, starts = make_windows(df, window_size, step_size)
    gt_x = df[gt_x_col].to_numpy(dtype=np.float32)
    gt_y = df[gt_y_col].to_numpy(dtype=np.float32)
    gt_h = df[gt_heading_col].to_numpy(dtype=np.float32)

    y = []
    for start in starts:
        end = min(start + window_size, len(gt_x) - 1)
        dx = gt_x[end] - gt_x[start]
        dy = gt_y[end] - gt_y[start]
        dh = gt_h[end] - gt_h[start]
        y.append([dx, dy, dh])
    return X, np.array(y, dtype=np.float32)