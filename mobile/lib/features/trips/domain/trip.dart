enum PointSource { gnss, fused, drOnly }

class Trip {
  const Trip({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.distanceM,
    this.maxDriftM,
    this.pctTimeDr,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? distanceM;
  final double? maxDriftM;
  final double? pctTimeDr;
}

class TrajectoryPoint {
  const TrajectoryPoint({
    required this.ts,
    required this.lat,
    required this.lon,
    required this.source,
    this.accuracyM,
    this.covarianceMajorM,
    this.covarianceMinorM,
    this.headingDeg,
  });

  final DateTime ts;
  final double lat;
  final double lon;
  final PointSource source;
  final double? accuracyM;
  final double? covarianceMajorM;
  final double? covarianceMinorM;
  final double? headingDeg;
}
