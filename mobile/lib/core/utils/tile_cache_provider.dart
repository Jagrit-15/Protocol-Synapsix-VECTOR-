// Wraps flutter_map's TileLayer with an on-disk HTTP cache, so previously
// viewed tiles render with zero network — the basis for offline map use.
// First view of any tile still needs internet; use TilePrefetcher to
// pre-seed a region before going fully offline (e.g. before a demo).
//
// Both the map's CachedTileProvider and TilePrefetcher's Dio client read
// from/write to the same FileCacheStore instance, so tiles fetched by
// either one are immediately visible to the other.

import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:path_provider/path_provider.dart';

class TileCacheProvider {
  static FileCacheStore? _store;
  static const Duration maxStale = Duration(days: 30);

  /// Returns the shared cache store, creating it on first call.
  static Future<FileCacheStore> _getStore() async {
    if (_store != null) return _store!;
    final dir = await getApplicationDocumentsDirectory();
    _store = FileCacheStore('${dir.path}/map_tile_cache');
    return _store!;
  }

  /// Returns a CachedTileProvider for use as TileLayer's tileProvider.
  static Future<CachedTileProvider> build() async {
    final store = await _getStore();
    return CachedTileProvider(
      store: store,
      maxStale: maxStale,
    );
  }

  /// Returns the shared cache store directly — used by TilePrefetcher to
  /// pre-populate the same cache the map reads from.
  static Future<FileCacheStore> getStore() => _getStore();
}