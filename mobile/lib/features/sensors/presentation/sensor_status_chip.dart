import 'package:flutter/material.dart';

/// Tiny chip used by screens when live IMU/GNSS hardware is (un)available.
class SensorStatusChip extends StatelessWidget {
  const SensorStatusChip({super.key, required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        ok ? Icons.check_circle : Icons.warning_amber,
        size: 16,
        color: ok ? Colors.green : Colors.orange,
      ),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
