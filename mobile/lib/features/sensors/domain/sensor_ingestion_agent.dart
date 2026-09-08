// Sensor Ingestion Agent (real implementation).
//
// Subscribes to accel/gyro/mag/GNSS via SensorDataSource's continuous
// streams, and emits a timestamp-aligned SensorFrame at a fixed rate
// (AppConstants.pipelineTick) via the `frames` stream.
//
// DEMO: if [mockOverride] is provided to ingest(), it is returned untouched
// — this keeps the existing demo-scenario override path working.

import 'dart:async';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_exception.dart';
import '../data/sensor_data_source.dart';
import 'sensor_frame.dart';

abstract class SensorIngestionAgent {
  Future<SensorFrame> ingest({SensorFrame? mockOverride});

  /// Continuous stream of timestamp-aligned frames, emitted at a fixed tick
  /// rate. Call start() before listening.
  Stream<SensorFrame> get frames;

  Future<void> start();
  Future<void> stop();
}

class PassthroughSensorIngestionAgent implements SensorIngestionAgent {
  PassthroughSensorIngestionAgent({SensorDataSource? dataSource})
      : _dataSource = dataSource ?? SensorDataSource();

  final SensorDataSource _dataSource;
  final StreamController<SensorFrame> _controller =
      StreamController<SensorFrame>.broadcast();
  Timer? _ticker;

  @override
  Stream<SensorFrame> get frames => _controller.stream;

  @override
  Future<void> start() async {
    try {
      await _dataSource.start();
    } catch (e) {
      throw SensorException('Failed to start sensor streams', cause: e);
    }

    _ticker?.cancel();
    _ticker = Timer.periodic(AppConstants.pipelineTick, (_) {
      if (!_controller.isClosed) {
        _controller.add(_dataSource.currentFrame());
      }
    });
  }

  @override
  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    await _dataSource.dispose();
  }

  @override
  Future<SensorFrame> ingest({SensorFrame? mockOverride}) async {
    if (mockOverride != null) {
      return mockOverride;
    }
    try {
      return _dataSource.currentFrame();
    } catch (e) {
      throw SensorException('Failed to read sensors', cause: e);
    }
  }
}