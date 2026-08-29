// PLACEHOLDER wrapper around sensors_plus + geolocator.
// Demo path never requires this to succeed — DemoScenarioController injects frames.

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../domain/sensor_frame.dart';

class SensorDataSource {
  Future<SensorFrame> readOnce() async {
    Vector3 accel = const Vector3(0, 0, 9.81);
    Vector3 gyro = const Vector3(0, 0, 0);
    Vector3 mag = const Vector3(0, 0, 0);
    GnssFix? gnss;

    try {
      final event = await accelerometerEventStream().first.timeout(
            const Duration(milliseconds: 200),
          );
      accel = Vector3(event.x, event.y, event.z);
    } catch (_) {
      // Hardware unavailable in emulator / desktop — keep zeros.
    }

    try {
      final event = await gyroscopeEventStream().first.timeout(
            const Duration(milliseconds: 200),
          );
      gyro = Vector3(event.x, event.y, event.z);
    } catch (_) {}

    try {
      final event = await magnetometerEventStream().first.timeout(
            const Duration(milliseconds: 200),
          );
      mag = Vector3(event.x, event.y, event.z);
    } catch (_) {}

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(milliseconds: 400),
        ),
      );
      gnss = GnssFix(
        lat: pos.latitude,
        lon: pos.longitude,
        accuracyM: pos.accuracy,
        headingDeg: pos.heading,
      );
    } catch (_) {}

    return SensorFrame(
      timestamp: DateTime.now(),
      accel: accel,
      gyro: gyro,
      mag: mag,
      gnss: gnss,
    );
  }
}
