// Rotates vectors between the phone's device frame and a locally-level
// world/ENU frame, using a roll/pitch/yaw attitude estimate. This is the
// "device frame → vehicle frame → world frame using attitude estimation"
// step from the Blueprint (Document 3, Pre-processing).

import 'dart:math';

class AttitudeTransforms {
  /// Rotates a device-frame vector into the world ENU frame using the
  /// standard ZYX (yaw-pitch-roll) rotation convention.
  static ({double east, double north, double up}) deviceToWorld({
    required double x,
    required double y,
    required double z,
    required double rollRad,
    required double pitchRad,
    required double yawRad,
  }) {
    final cr = cos(rollRad), sr = sin(rollRad);
    final cp = cos(pitchRad), sp = sin(pitchRad);
    final cy = cos(yawRad), sy = sin(yawRad);

    final r00 = cy * cp;
    final r01 = cy * sp * sr - sy * cr;
    final r02 = cy * sp * cr + sy * sr;
    final r10 = sy * cp;
    final r11 = sy * sp * sr + cy * cr;
    final r12 = sy * sp * cr - cy * sr;
    final r20 = -sp;
    final r21 = cp * sr;
    final r22 = cp * cr;

    return (
      east: r00 * x + r01 * y + r02 * z,
      north: r10 * x + r11 * y + r12 * z,
      up: r20 * x + r21 * y + r22 * z,
    );
  }

  /// Estimates roll/pitch from a gravity-dominated accelerometer reading.
  /// Not valid during hard braking/acceleration (accel vector no longer
  /// gravity-aligned) — an inherent limitation of accel-only tilt sensing.
  static ({double rollRad, double pitchRad}) rollPitchFromAccel({
    required double accelX,
    required double accelY,
    required double accelZ,
  }) {
    final roll = atan2(accelY, accelZ);
    final pitch = atan2(-accelX, sqrt(accelY * accelY + accelZ * accelZ));
    return (rollRad: roll, pitchRad: pitch);
  }
}