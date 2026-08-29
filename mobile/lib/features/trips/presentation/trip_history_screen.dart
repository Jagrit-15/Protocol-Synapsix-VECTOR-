import 'package:flutter/material.dart';

import '../data/trip_repository.dart';

class TripHistoryScreen extends StatelessWidget {
  TripHistoryScreen({super.key, TripRepository? repository})
      : _repository = repository ?? TripRepository();

  final TripRepository _repository;

  @override
  Widget build(BuildContext context) {
    final trips = _repository.listTrips();
    return Scaffold(
      appBar: AppBar(title: const Text('Trip History')),
      body: ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, i) {
          final t = trips[i];
          return ListTile(
            title: Text(t.id),
            subtitle: Text(
              '${t.distanceM?.toStringAsFixed(0) ?? '?'} m  ·  '
              'DR ${(100 * (t.pctTimeDr ?? 0)).toStringAsFixed(0)}%',
            ),
            onTap: () => Navigator.of(context).pushNamed(
              '/trip-summary',
              arguments: t.id,
            ),
          );
        },
      ),
    );
  }
}
