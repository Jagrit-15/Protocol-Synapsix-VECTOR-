// Subscribes to a SensorIngestionAgent's frame stream and writes each frame
// to local SQLite. Writes are batched to avoid a disk write on every tick.

import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../domain/sensor_frame.dart';
import '../domain/sensor_ingestion_agent.dart';
import 'raw_sensor_log_db.dart';

class RawSensorLogger {
  RawSensorLogger({
    required SensorIngestionAgent agent,
    this.batchSize = 20,
  }) : _agent = agent;

  final SensorIngestionAgent _agent;
  final int batchSize;

  StreamSubscription<SensorFrame>? _sub;
  final List<SensorFrame> _pending = [];

  bool get isLogging => _sub != null;

  /// Begin logging every frame emitted by the agent's [frames] stream.
  /// Does NOT call agent.start() itself — call that separately so logging
  /// can be attached/detached independently of sensor streaming lifecycle.
  void start() {
    _sub?.cancel();
    _sub = _agent.frames.listen(_onFrame);
  }

  void _onFrame(SensorFrame frame) {
    _pending.add(frame);
    if (_pending.length >= batchSize) {
      _flush();
    }
  }

  Future<void> _flush() async {
    if (_pending.isEmpty) return;
    final toWrite = List<SensorFrame>.from(_pending);
    _pending.clear();

    final db = await RawSensorLogDb.instance.database;
    final batch = db.batch();
    for (final frame in toWrite) {
      batch.insert('raw_sensor_samples', {
        'ts_ms': frame.timestamp.millisecondsSinceEpoch,
        'accel_x': frame.accel.x,
        'accel_y': frame.accel.y,
        'accel_z': frame.accel.z,
        'gyro_x': frame.gyro.x,
        'gyro_y': frame.gyro.y,
        'gyro_z': frame.gyro.z,
        'mag_x': frame.mag.x,
        'mag_y': frame.mag.y,
        'mag_z': frame.mag.z,
        'baro_hpa': frame.baroHpa,
        'gnss_lat': frame.gnss?.lat,
        'gnss_lon': frame.gnss?.lon,
        'gnss_accuracy_m': frame.gnss?.accuracyM,
        'gnss_heading_deg': frame.gnss?.headingDeg,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Stop logging. Flushes any remaining buffered frames first.
  Future<void> stop() async {
    await _flush();
    await _sub?.cancel();
    _sub = null;
  }

  /// Fetch the most recent [limit] samples, newest first — useful for the
  /// debug screen or exporting training data later.
  Future<List<Map<String, Object?>>> recent({int limit = 100}) async {
    final db = await RawSensorLogDb.instance.database;
    return db.query(
      'raw_sensor_samples',
      orderBy: 'ts_ms DESC',
      limit: limit,
    );
  }

  /// Total row count — handy for a "N samples logged" indicator in the UI.
  Future<int> count() async {
    final db = await RawSensorLogDb.instance.database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as c FROM raw_sensor_samples');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}