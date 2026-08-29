enum GnssStatus { good, degraded, deadReckoningActive }

extension GnssStatusLabel on GnssStatus {
  String get label => switch (this) {
        GnssStatus.good => 'Good',
        GnssStatus.degraded => 'Degraded',
        GnssStatus.deadReckoningActive => 'Dead-Reckoning Active',
      };
}
