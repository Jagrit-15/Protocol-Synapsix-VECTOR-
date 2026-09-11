// One-time utility to pre-download map tiles for a bounding box, so the
// app can render the map fully offline afterward (e.g. before a demo with
// unreliable venue wifi). Writes into the same cache store TileLayer's
// CachedTileProvider reads from, via a Dio client carrying the same
// DioCacheInterceptor — this guarantees cache-format compatibility
// instead of writing to the store's low-level API directly.

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

import '../constants/app_constants.dart';
import 'tile_cache_provider.dart';

class TilePrefetcher {
  /// Downloads all tiles covering [minLat]..[maxLat] / [minLon]..[maxLon]
  /// for each zoom level in [zoomLevels]. Calls [onProgress] with
  /// (downloaded, total) as it goes.
  static Future<void> prefetchRegion({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    List<int> zoomLevels = const [13, 14, 15, 16],
    void Function(int done, int total)? onProgress,
  }) async {
    final store = await TileCacheProvider.getStore();
    final dio = Dio()
      ..interceptors.add(
        DioCacheInterceptor(
          options: CacheOptions(
            store: store,
            policy: CachePolicy.forceCache,
            maxStale: TileCacheProvider.maxStale,
          ),
        ),
      );

    final tiles = <(int z, int x, int y)>[];
    for (final z in zoomLevels) {
      final minTile = _latLonToTile(maxLat, minLon, z);
      final maxTile = _latLonToTile(minLat, maxLon, z);
      for (var x = minTile.$1; x <= maxTile.$1; x++) {
        for (var y = minTile.$2; y <= maxTile.$2; y++) {
          tiles.add((z, x, y));
        }
      }
    }

    var done = 0;
    for (final (z, x, y) in tiles) {
      final url = AppConstants.osmTileUrl
          .replaceAll('{z}', '$z')
          .replaceAll('{x}', '$x')
          .replaceAll('{y}', '$y');
      try {
        await dio.get(url);
      } catch (_) {
        // Skip failed tiles — a few missing tiles isn't fatal.
      }
      done++;
      onProgress?.call(done, tiles.length);
    }
  }

  static (int, int) _latLonToTile(double lat, double lon, int z) {
    final latRad = lat * pi / 180.0;
    final n = pow(2, z).toDouble();
    final x = ((lon + 180.0) / 360.0 * n).floor();
    final y = ((1.0 -
                (log(tan(latRad) + 1.0 / cos(latRad)) / pi)) /
            2.0 *
            n)
        .floor();
    return (x, y);
  }
}