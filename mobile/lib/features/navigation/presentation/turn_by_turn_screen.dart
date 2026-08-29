import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared_widgets/gnss_status_badge.dart';
import 'pipeline_providers.dart';

class TurnByTurnScreen extends ConsumerWidget {
  const TurnByTurnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(demoScenarioProvider).snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Turn-by-Turn')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GnssStatusBadge(status: snap.gnssStatus),
            const SizedBox(height: 24),
            Text(
              'Continue straight',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            const Text('PLACEHOLDER maneuver — no real routing yet.'),
            const SizedBox(height: 24),
            Text('Motion: ${snap.motion.stateLabel.name}'),
            Text(
              'Position ${snap.snapped.lat.toStringAsFixed(5)}, '
              '${snap.snapped.lon.toStringAsFixed(5)}',
            ),
          ],
        ),
      ),
    );
  }
}
