// App-wide singleton wiring the real sensor pipeline: ingestion agent
// (continuous streams) + raw sensor logger (SQLite). Started once at app
// launch; the debug screen (and later, real fusion code) reads from this
// instead of each creating its own agent.

import '../features/sensors/data/raw_sensor_logger.dart';
import '../features/sensors/domain/sensor_frame.dart';
import '../features/sensors/domain/sensor_ingestion_agent.dart';

class SensorPipelineService {
  SensorPipelineService._internal()
      : agent = PassthroughSensorIngestionAgent() {
    logger = RawSensorLogger(agent: agent);
  }

  static final SensorPipelineService instance =
      SensorPipelineService._internal();

  final SensorIngestionAgent agent;
  late final RawSensorLogger logger;

  bool _started = false;
  bool get isRunning => _started;

  Future<void> start() async {
    if (_started) return;
    await agent.start();
    logger.start();
    _started = true;
  }

  Future<void> stop() async {
    if (!_started) return;
    await logger.stop();
    await agent.stop();
    _started = false;
  }

  Stream<SensorFrame> get frames => agent.frames;
}