import 'dart:math';

/// PLACEHOLDER: equirectangular local ENU. Replace with WGS84 geodesic math later.
///
/// Intentionally dumb and deterministic so unit tests can lock the contract
/// before real EKF / map-matching slices land.
class CoordinateTransforms {
  static const double _metersPerDegLat = 111320.0;

  static double _metersPerDegLon(double latDeg) {
    return 111320.0 * cos(latDeg * pi / 180.0);
  }

  /// Local east/north meters relative to [originLat]/[originLon].
  static ({double eastM, double northM}) latLonToEnu({
    required double lat,
    required double lon,
    required double originLat,
    required double originLon,
  }) {
    final northM = (lat - originLat) * _metersPerDegLat;
    final eastM = (lon - originLon) * _metersPerDegLon(originLat);
    return (eastM: eastM, northM: northM);
  }

  static ({double lat, double lon}) enuToLatLon({
    required double eastM,
    required double northM,
    required double originLat,
    required double originLon,
  }) {
    final lat = originLat + northM / _metersPerDegLat;
    final lon = originLon + eastM / _metersPerDegLon(originLat);
    return (lat: lat, lon: lon);
  }
}
