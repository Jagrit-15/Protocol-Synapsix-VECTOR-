import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/coordinate_transforms.dart';

void main() {
  group('CoordinateTransforms (placeholder equirectangular)', () {
    test('origin maps to zero east/north', () {
      final enu = CoordinateTransforms.latLonToEnu(
        lat: 28.6139,
        lon: 77.2090,
        originLat: 28.6139,
        originLon: 77.2090,
      );
      expect(enu.eastM, closeTo(0, 1e-9));
      expect(enu.northM, closeTo(0, 1e-9));
    });

    test('round-trip lat/lon through ENU', () {
      const lat = 28.6200;
      const lon = 77.2150;
      final enu = CoordinateTransforms.latLonToEnu(
        lat: lat,
        lon: lon,
        originLat: 28.6139,
        originLon: 77.2090,
      );
      final geo = CoordinateTransforms.enuToLatLon(
        eastM: enu.eastM,
        northM: enu.northM,
        originLat: 28.6139,
        originLon: 77.2090,
      );
      expect(geo.lat, closeTo(lat, 1e-9));
      expect(geo.lon, closeTo(lon, 1e-9));
    });
  });
}
