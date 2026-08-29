// PLACEHOLDER local trip cache. Real slice will use sqflite + sync.
import '../domain/trip.dart';

class TripRepository {
  final List<Trip> _trips = [
    Trip(
      id: 'demo-trip-1',
      startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      endedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 40)),
      distanceM: 4200,
      maxDriftM: 18.4,
      pctTimeDr: 0.22,
    ),
  ];

  List<Trip> listTrips() => List.unmodifiable(_trips);

  Trip? getById(String id) {
    for (final t in _trips) {
      if (t.id == id) return t;
    }
    return null;
  }
}
