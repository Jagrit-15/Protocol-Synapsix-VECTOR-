import 'sensor_recording_label.dart';

/// Metadata for a labeled sensor recording session. Each recording groups
/// a contiguous sequence of sensor samples with the same label, used later
/// for ML training data export.
class SensorRecording {
  const SensorRecording({
    required this.id,
    this.label,
    required this.startTsMs,
    this.endTsMs,
    this.sampleCount = 0,
    this.notes,
  });

  final String id;
  final SensorRecordingLabel? label;
  final int startTsMs;
  final int? endTsMs;
  final int sampleCount;
  final String? notes;

  bool get isActive => endTsMs == null;

  Duration get duration {
    final end = endTsMs ?? DateTime.now().millisecondsSinceEpoch;
    return Duration(milliseconds: end - startTsMs);
  }

  SensorRecording copyWith({
    String? id,
    SensorRecordingLabel? label,
    int? startTsMs,
    int? endTsMs,
    int? sampleCount,
    String? notes,
  }) {
    return SensorRecording(
      id: id ?? this.id,
      label: label ?? this.label,
      startTsMs: startTsMs ?? this.startTsMs,
      endTsMs: endTsMs ?? this.endTsMs,
      sampleCount: sampleCount ?? this.sampleCount,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'label': label?.csvValue,
      'start_ts_ms': startTsMs,
      'end_ts_ms': endTsMs,
      'sample_count': sampleCount,
      'notes': notes,
    };
  }

  factory SensorRecording.fromMap(Map<String, Object?> map) {
    final labelStr = map['label'] as String?;
    SensorRecordingLabel? label;
    if (labelStr != null) {
      try {
        label = SensorRecordingLabel.values.firstWhere(
          (e) => e.csvValue == labelStr,
        );
      } catch (_) {
        // Invalid label in database — leave null
      }
    }

    return SensorRecording(
      id: map['id'] as String,
      label: label,
      startTsMs: map['start_ts_ms'] as int,
      endTsMs: map['end_ts_ms'] as int?,
      sampleCount: map['sample_count'] as int? ?? 0,
      notes: map['notes'] as String?,
    );
  }
}
