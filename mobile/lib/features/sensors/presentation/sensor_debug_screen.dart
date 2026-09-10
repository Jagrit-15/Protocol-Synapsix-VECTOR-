import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../services/sensor_pipeline_service.dart';
import '../domain/sensor_frame.dart';
import '../domain/sensor_recording.dart';
import '../domain/sensor_recording_label.dart';
import 'sensor_status_chip.dart';

class SensorDebugScreen extends StatefulWidget {
  const SensorDebugScreen({super.key});

  @override
  State<SensorDebugScreen> createState() => _SensorDebugScreenState();
}

class _SensorDebugScreenState extends State<SensorDebugScreen> {
  final _service = SensorPipelineService.instance;

  StreamSubscription<SensorFrame>? _sub;
  SensorFrame? _latest;
  int _loggedCount = 0;
  List<SensorRecording> _recordings = [];
  Timer? _refreshTimer;

  SensorRecordingLabel _selectedLabel = SensorRecordingLabel.stationary;
  String? _lastExportPath;

  @override
  void initState() {
    super.initState();
    _sub = _service.frames.listen((frame) {
      if (mounted) setState(() => _latest = frame);
    });
    _refresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refresh(),
    );
  }

  Future<void> _refresh() async {
    final c = await _service.logger.count();
    final recs = await _service.logger.recordingManager.listRecordings(limit: 20);
    if (mounted) {
      setState(() {
        _loggedCount = c;
        _recordings = recs;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool get _isRecording => _service.logger.recordingManager.activeRecording != null;

  Future<void> _toggleRecording() async {
    final manager = _service.logger.recordingManager;
    if (_isRecording) {
      final active = manager.activeRecording!;
      await manager.stopRecording();
      // Auto-compute ground truth if this recording has GNSS data — safe
      // to attempt, throws StateError (caught) if no GNSS fixes were
      // captured, which is expected for indoor/stationary/walking tests.
      try {
        await manager.computeGroundTruth(active.id);
      } catch (_) {}
    } else {
      await manager.startRecording(label: _selectedLabel);
    }
    if (mounted) setState(() {});
    await _refresh();
  }

  Future<void> _exportRecording(SensorRecording recording) async {
    final csv = await _service.logger.recordingManager.exportToCsv(
      recording.id,
      includeGroundTruth: true,
    );

    final dir = await getApplicationDocumentsDirectory();
    final filename = '${recording.id}.csv';
    final path = p.join(dir.path, filename);
    await File(path).writeAsString(csv);

    setState(() => _lastExportPath = path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to $path')),
      );
    }
  }

  Future<void> _deleteRecording(SensorRecording recording) async {
    await _service.logger.recordingManager.deleteRecording(recording.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _latest;
    final hasAccel = frame != null;
    final hasGnss = frame?.gnss != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SensorStatusChip(
                label: _service.isRunning ? 'Pipeline running' : 'Stopped',
                ok: _service.isRunning,
              ),
              SensorStatusChip(label: 'IMU', ok: hasAccel),
              SensorStatusChip(label: 'GNSS', ok: hasGnss),
              SensorStatusChip(
                label: '$_loggedCount raw samples',
                ok: _loggedCount > 0,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Accelerometer (m/s²)',
            child: _Vector3Row(frame?.accel),
          ),
          _SectionCard(
            title: 'Gyroscope (rad/s)',
            child: _Vector3Row(frame?.gyro),
          ),
          _SectionCard(
            title: 'Magnetometer (µT)',
            child: _Vector3Row(frame?.mag),
          ),
          _SectionCard(
            title: 'GNSS',
            child: hasGnss
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lat: ${frame!.gnss!.lat.toStringAsFixed(6)}'),
                      Text('Lon: ${frame.gnss!.lon.toStringAsFixed(6)}'),
                      Text(
                        'Accuracy: ${frame.gnss!.accuracyM.toStringAsFixed(1)} m',
                      ),
                      Text(
                        'Heading: ${frame.gnss!.headingDeg?.toStringAsFixed(1) ?? '—'}°',
                      ),
                    ],
                  )
                : const Text('No GNSS fix yet'),
          ),
          const Divider(height: 32),
          Text(
            'Training Data Recording',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Label',
            child: DropdownButton<SensorRecordingLabel>(
              value: _selectedLabel,
              isExpanded: true,
              onChanged: _isRecording
                  ? null
                  : (v) => setState(() => _selectedLabel = v!),
              items: SensorRecordingLabel.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.csvValue),
                      ))
                  .toList(),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleRecording,
                  icon: Icon(
                    _isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                    color: _isRecording ? Colors.red : null,
                  ),
                  label: Text(
                    _isRecording
                        ? 'Stop recording (${_selectedLabel.csvValue})'
                        : 'Start recording',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Past recordings',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (_recordings.isEmpty)
            const Text('No recordings yet')
          else
            ..._recordings.map((r) => Card(
                  child: ListTile(
                    title: Text(r.label?.csvValue ?? 'unlabeled'),
                    subtitle: Text(
                      '${r.sampleCount} samples · '
                      '${r.duration.inSeconds}s'
                      '${r.isActive ? ' · recording…' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.upload_file),
                          onPressed: r.isActive
                              ? null
                              : () => _exportRecording(r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteRecording(r),
                        ),
                      ],
                    ),
                  ),
                )),
          if (_lastExportPath != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              'Last export: $_lastExportPath',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_service.isRunning) {
                      await _service.stop();
                    } else {
                      await _service.start();
                    }
                    if (mounted) setState(() {});
                  },
                  child: Text(
                    _service.isRunning ? 'Stop pipeline' : 'Start pipeline',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _Vector3Row extends StatelessWidget {
  const _Vector3Row(this.v);

  final Vector3? v;

  @override
  Widget build(BuildContext context) {
    if (v == null) return const Text('—');
    return Text(
      'x: ${v!.x.toStringAsFixed(3)}   '
      'y: ${v!.y.toStringAsFixed(3)}   '
      'z: ${v!.z.toStringAsFixed(3)}',
    );
  }
}