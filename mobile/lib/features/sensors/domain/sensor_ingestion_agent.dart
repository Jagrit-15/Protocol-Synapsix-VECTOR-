// TODO(agentic-workflow): replace with real implementation — see Sensor Ingestion Agent spec
//
// Real job: subscribe to accel/gyro/mag/baro + GNSS streams, time-align them
// onto a common clock, and emit SensorFrame at a fixed rate. Handle sensor
// dropouts, permission failures, and sample-rate mismatch.
//
// DEMO: if [mockOverride] is provided, return it untouched. Otherwise pass
// through a single sensors_plus / geolocator snapshot (or a zero frame if
// hardware is unavailable). No filtering, no interpolation.

import '../../../core/error/app_exception.dart';
import '../data/sensor_data_source.dart';
import 'sensor_frame.dart';

abstract class SensorIngestionAgent {
  Future<SensorFrame> ingest({SensorFrame? mockOverride});
}

class PassthroughSensorIngestionAgent implements SensorIngestionAgent {
  PassthroughSensorIngestionAgent({SensorDataSource? dataSource})
      : _dataSource = dataSource ?? SensorDataSource();

  final SensorDataSource _dataSource;

  @override
  Future<SensorFrame> ingest({SensorFrame? mockOverride}) async {
    if (mockOverride != null) {
      return mockOverride;
    }
    try {
      return await _dataSource.readOnce();
    } catch (e) {
      throw SensorException('Failed to read sensors', cause: e);
    }
  }
}
