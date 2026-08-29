import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sensors/domain/sensor_frame.dart';
import 'package:mobile/features/sensors/domain/sensor_ingestion_agent.dart';

void main() {
  test('SensorIngestionAgent passes mockOverride through untouched', () async {
    final agent = PassthroughSensorIngestionAgent();
    final frame = SensorFrame(
      timestamp: DateTime.utc(2026, 1, 1),
      accel: const Vector3(1, 2, 3),
      gyro: const Vector3(0, 0, 0),
      mag: const Vector3(0, 0, 0),
    );
    final out = await agent.ingest(mockOverride: frame);
    expect(identical(out, frame), isTrue);
  });
}
