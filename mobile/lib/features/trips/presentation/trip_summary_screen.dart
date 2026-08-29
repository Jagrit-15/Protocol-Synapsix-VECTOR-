import 'package:flutter/material.dart';

import '../data/trip_repository.dart';

class TripSummaryScreen extends StatelessWidget {
  TripSummaryScreen({super.key, this.tripId, TripRepository? repository})
      : _repository = repository ?? TripRepository();

  final String? tripId;
  final TripRepository _repository;

  @override
  Widget build(BuildContext context) {
    final id = tripId ??
        (ModalRoute.of(context)?.settings.arguments as String?) ??
        'demo-trip-1';
    final trip = _repository.getById(id);
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Summary')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: trip == null
            ? const Text('No mock trip found.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.id, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text('Distance: ${trip.distanceM?.toStringAsFixed(0)} m'),
                  Text('Max drift: ${trip.maxDriftM?.toStringAsFixed(1)} m'),
                  Text(
                    'Time in DR: ${((trip.pctTimeDr ?? 0) * 100).toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PLACEHOLDER stats — analytics_engine is not wired yet.',
                  ),
                ],
              ),
      ),
    );
  }
}
