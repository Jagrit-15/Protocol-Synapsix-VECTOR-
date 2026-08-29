class Vector3 {
  const Vector3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

class GnssFix {
  const GnssFix({
    required this.lat,
    required this.lon,
    required this.accuracyM,
    this.headingDeg,
  });

  final double lat;
  final double lon;
  final double accuracyM;
  final double? headingDeg;
}

/// Timestamped, aligned IMU + optional GNSS sample.
class SensorFrame {
  const SensorFrame({
    required this.timestamp,
    required this.accel,
    required this.gyro,
    required this.mag,
    this.baroHpa,
    this.gnss,
  });

  final DateTime timestamp;
  final Vector3 accel;
  final Vector3 gyro;
  final Vector3 mag;
  final double? baroHpa;
  final GnssFix? gnss;
}
