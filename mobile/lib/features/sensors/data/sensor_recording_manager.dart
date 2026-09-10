// Recording manager for labeled sensor data collection. Handles starting/
// stopping recordings, assigning labels, and associating samples with
// recording sessions for later export to training CSVs.

import 'package:sqflite/sqflite.dart';

import '../../../core/utils/coordinate_transforms.dart';
import '../domain/sensor_recording.dart';
import '../domain/sensor_recording_label.dart';
import 'raw_sensor_log_db.dart';

class SensorRecordingManager {
  SensorRecording? _activeRecording;

  SensorRecording? get activeRecording => _activeRecording;

  /// Start a new recording session. If a recording is already active, stops
  /// it first. Returns the new recording ID.
  Future<String> startRecording({
    SensorRecordingLabel? label,
    String? notes,
  }) async {
    // Stop any active recording first
    if (_activeRecording != null) {
      await stopRecording();
    }

    final id = 'rec_${DateTime.now().millisecondsSinceEpoch}';
    final recording = SensorRecording(
      id: id,
      label: label,
      startTsMs: DateTime.now().millisecondsSinceEpoch,
      notes: notes,
    );

    final db = await RawSensorLogDb.instance.database;
    await db.insert('recordings', recording.toMap());

    _activeRecording = recording;
    return id;
  }

  /// Stop the active recording and update its metadata.
  Future<void> stopRecording() async {
    final recording = _activeRecording;
    if (recording == null) return;

    final db = await RawSensorLogDb.instance.database;
    final endTsMs = DateTime.now().millisecondsSinceEpoch;

    // Count samples in this recording
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM raw_sensor_samples WHERE recording_id = ?',
      [recording.id],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;

    await db.update(
      'recordings',
      {
        'end_ts_ms': endTsMs,
        'sample_count': count,
      },
      where: 'id = ?',
      whereArgs: [recording.id],
    );

    _activeRecording = null;
  }

  /// Update the label of an existing recording. Works for both active and
  /// completed recordings.
  Future<void> setLabel(String recordingId, SensorRecordingLabel label) async {
    final db = await RawSensorLogDb.instance.database;
    await db.update(
      'recordings',
      {'label': label.csvValue},
      where: 'id = ?',
      whereArgs: [recordingId],
    );

    // Also update all samples in this recording
    await db.update(
      'raw_sensor_samples',
      {'label': label.csvValue},
      where: 'recording_id = ?',
      whereArgs: [recordingId],
    );

    if (_activeRecording?.id == recordingId) {
      _activeRecording = _activeRecording!.copyWith(label: label);
    }
  }

  /// List all recordings, most recent first.
  Future<List<SensorRecording>> listRecordings({int? limit}) async {
    final db = await RawSensorLogDb.instance.database;
    final maps = await db.query(
      'recordings',
      orderBy: 'start_ts_ms DESC',
      limit: limit,
    );
    return maps.map(SensorRecording.fromMap).toList();
  }

  /// Get a specific recording by ID.
  Future<SensorRecording?> getRecording(String id) async {
    final db = await RawSensorLogDb.instance.database;
    final maps = await db.query(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : SensorRecording.fromMap(maps.first);
  }

  /// Delete a recording and all its samples.
  Future<void> deleteRecording(String id) async {
    final db = await RawSensorLogDb.instance.database;
    await db.delete('raw_sensor_samples', where: 'recording_id = ?', whereArgs: [id]);
    await db.delete('recordings', where: 'id = ?', whereArgs: [id]);

    if (_activeRecording?.id == id) {
      _activeRecording = null;
    }
  }

  /// Compute and store ground-truth local coordinates for a recording's
  /// samples. Uses the first GNSS fix in the recording as the origin,
  /// then converts all subsequent GNSS fixes to local ENU (x, y) and
  /// heading. This must be called after a recording is stopped and before
  /// export, and only works for recordings with GNSS data.
  Future<void> computeGroundTruth(String recordingId) async {
    final db = await RawSensorLogDb.instance.database;

    // Get all samples in this recording that have GNSS data
    final samples = await db.query(
      'raw_sensor_samples',
      where: 'recording_id = ? AND gnss_lat IS NOT NULL',
      whereArgs: [recordingId],
      orderBy: 'ts_ms ASC',
    );

    if (samples.isEmpty) {
      throw StateError('Recording $recordingId has no GNSS data');
    }

    // Use first fix as origin
    final origin = samples.first;
    final originLat = origin['gnss_lat'] as double;
    final originLon = origin['gnss_lon'] as double;

    // Convert each sample to local coordinates
    final batch = db.batch();
    for (final sample in samples) {
      final lat = sample['gnss_lat'] as double;
      final lon = sample['gnss_lon'] as double;
      final headingDeg = sample['gnss_heading_deg'] as double?;

      final local = CoordinateTransforms.latLonToEnu(
        lat: lat,
        lon: lon,
        originLat: originLat,
        originLon: originLon,
      );

      batch.update(
        'raw_sensor_samples',
        {
          'gt_x': local.eastM,
          'gt_y': local.northM,
          'gt_heading': headingDeg,
        },
        where: 'id = ?',
        whereArgs: [sample['id']],
      );
    }

    await batch.commit(noResult: true);
  }

  /// Export a recording to CSV format matching the Python training script
  /// schema. Returns the CSV content as a string.
  ///
  /// For classifier training: requires label to be set.
  /// For odometry training: requires ground truth to be computed first
  /// via computeGroundTruth().
  Future<String> exportToCsv(
    String recordingId, {
    bool includeGroundTruth = false,
  }) async {
    final recording = await getRecording(recordingId);
    if (recording == null) {
      throw ArgumentError('Recording $recordingId not found');
    }

    final db = await RawSensorLogDb.instance.database;
    final samples = await db.query(
      'raw_sensor_samples',
      where: 'recording_id = ?',
      whereArgs: [recordingId],
      orderBy: 'ts_ms ASC',
    );

    if (samples.isEmpty) {
      throw StateError('Recording $recordingId has no samples');
    }

    // Build CSV header
    final header = [
      'ts_ms',
      'accel_x', 'accel_y', 'accel_z',
      'gyro_x', 'gyro_y', 'gyro_z',
      'mag_x', 'mag_y', 'mag_z',
      if (recording.label != null) 'label',
      if (includeGroundTruth) ...[
        'gt_x',
        'gt_y',
        'gt_heading',
      ],
    ].join(',');

    final rows = <String>[header];

    for (final sample in samples) {
      final row = [
        sample['ts_ms'],
        sample['accel_x'],
        sample['accel_y'],
        sample['accel_z'],
        sample['gyro_x'],
        sample['gyro_y'],
        sample['gyro_z'],
        sample['mag_x'],
        sample['mag_y'],
        sample['mag_z'],
        if (recording.label != null) recording.label!.csvValue,
        if (includeGroundTruth) ...[
          sample['gt_x'] ?? '',
          sample['gt_y'] ?? '',
          sample['gt_heading'] ?? '',
        ],
      ].join(',');
      rows.add(row);
    }

    return rows.join('\n');
  }
}
