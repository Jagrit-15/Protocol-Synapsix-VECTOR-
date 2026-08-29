import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/navigation/domain/gnss_status.dart';

class GnssStatusBadge extends StatelessWidget {
  const GnssStatusBadge({super.key, required this.status});

  final GnssStatus status;

  Color get _color => switch (status) {
        GnssStatus.good => AppTheme.gnssGood,
        GnssStatus.degraded => AppTheme.gnssDegraded,
        GnssStatus.deadReckoningActive => AppTheme.gnssDeadReckoning,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
