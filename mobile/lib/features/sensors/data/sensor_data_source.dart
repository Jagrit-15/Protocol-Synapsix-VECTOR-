// Continuous sensor streaming with a latest-value buffer for timestamp alignment.
// Each sensor arrives at its own rate; we keep the most recent reading from
// each and combine them when a frame is requested.

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../domain/sensor_frame.dart';

class SensorDataSource {
  Vector3 _lastAccel = const Vector3(0, 0, 9.81);
  Vector3 _lastGyro = const Vector3(0, 0, 0);
  Vector3 _lastMag = const Vector3(0, 0, 0);
  GnssFix? _lastGnss;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<Position>? _gnssSub;

  bool _started = false;

  /// Begin listening to all sensor streams. Safe to call once at app/agent
  /// startup. Individual sensor failures (unavailable hardware) are caught
  /// so one missing sensor doesn't block the others.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      _accelSub = accelerometerEventStream().listen((event) {
        _lastAccel = Vector3(event.x, event.y, event.z);
      });
    } catch (_) {
      // Hardware unavailable — keep last known (or default) value.
    }

    try {
      _gyroSub = gyroscopeEventStream().listen((event) {
        _lastGyro = Vector3(event.x, event.y, event.z);
      });
    } catch (_) {}

    try {
      _magSub = magnetometerEventStream().listen((event) {
        _lastMag = Vector3(event.x, event.y, event.z);
      });
    } catch (_) {}

    try {
      final hasPermission = await _ensureLocationPermission();
      if (hasPermission) {
        _gnssSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        ).listen((pos) {
          _lastGnss = GnssFix(
            lat: pos.latitude,
            lon: pos.longitude,
            accuracyM: pos.accuracy,
            headingDeg: pos.heading,
          );
        });
      }
    } catch (_) {}
  }

  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Returns the most recently buffered reading from each sensor, combined
  /// into one timestamp-aligned frame. This is the "alignment buffer" —
  /// sensors arrive at different rates, so we snapshot whatever is freshest
  /// from each at the moment this is called.
  SensorFrame currentFrame() {
    return SensorFrame(
      timestamp: DateTime.now(),
      accel: _lastAccel,
      gyro: _lastGyro,
      mag: _lastMag,
      gnss: _lastGnss,
    );
  }

  Future<void> dispose() async {
    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    await _magSub?.cancel();
    await _gnssSub?.cancel();
    _started = false;
  }
}