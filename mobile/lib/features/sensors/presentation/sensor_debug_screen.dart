import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/sensor_pipeline_service.dart';
import '../domain/sensor_frame.dart';
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
  Timer? _countTimer;

  @override
  void initState() {
    super.initState();
    _sub = _service.frames.listen((frame) {
      if (mounted) setState(() => _latest = frame);
    });
    _refreshCount();
    _countTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshCount(),
    );
  }

  Future<void> _refreshCount() async {
    final c = await _service.logger.count();
    if (mounted) setState(() => _loggedCount = c);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _countTimer?.cancel();
    super.dispose();
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
                label: '$_loggedCount samples logged',
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
          _SectionCard(
            title: 'Last frame timestamp',
            child: Text(frame?.timestamp.toIso8601String() ?? '—'),
          ),
          const SizedBox(height: 12),
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