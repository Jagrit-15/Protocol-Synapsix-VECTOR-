// Real OSM graph loader. Parses assets/maps/kolkata_road_graph.json
// (built by ml/map/build_road_graph.py) into an in-memory list of
// RoadSegments, plus a coarse grid index so nearest-segment queries stay
// fast even with thousands of segments.
//
// The graph is ~290K segments / ~25MB, so the actual JSON decode + index
// build runs on a background isolate via compute() — only the raw asset
// read (rootBundle.loadString) happens on the main isolate, since that
// requires the Flutter binding. This keeps app startup from freezing the
// UI thread for several seconds.

import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

import 'road_segment.dart';

class OsmGraph {
  const OsmGraph({
    required this.segments,
    required this.gridCellSizeDeg,
    required Map<String, List<int>> gridIndex,
  }) : _gridIndex = gridIndex;

  final List<RoadSegment> segments;
  final double gridCellSizeDeg;
  final Map<String, List<int>> _gridIndex;

  int get nodeCount => segments.length * 2;
  int get edgeCount => segments.length;

  static OsmGraph empty() => const OsmGraph(
        segments: [],
        gridCellSizeDeg: 0.01,
        gridIndex: {},
      );

  static Future<OsmGraph> loadFromAsset(
    String assetPath, {
    double gridCellSizeDeg = 0.01,
  }) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    // Heavy parsing (jsonDecode + grid-index build over ~290K segments)
    // moved to a background isolate — see _parseGraphJson below.
    final parsed = await compute(
      _parseGraphJson,
      _ParseArgs(jsonStr: jsonStr, gridCellSizeDeg: gridCellSizeDeg),
    );

    return OsmGraph(
      segments: parsed.segments,
      gridCellSizeDeg: gridCellSizeDeg,
      gridIndex: parsed.gridIndex,
    );
  }

  static String _gridKey(double lat, double lon, double cellSize) {
    final gx = (lon / cellSize).floor();
    final gy = (lat / cellSize).floor();
    return '$gx,$gy';
  }

  /// Returns segment indices within a 3x3 grid-cell neighborhood of the
  /// given point — a cheap coarse filter before precise distance checks.
  List<int> nearbySegmentIndices(double lat, double lon) {
    final gx = (lon / gridCellSizeDeg).floor();
    final gy = (lat / gridCellSizeDeg).floor();
    final result = <int>[];
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final key = '${gx + dx},${gy + dy}';
        final bucket = _gridIndex[key];
        if (bucket != null) result.addAll(bucket);
      }
    }
    return result;
  }

  bool get isEmpty => segments.isEmpty;
}

/// Arguments passed into the background isolate — must be simple/sendable
/// types only (compute() serializes across the isolate boundary).
class _ParseArgs {
  const _ParseArgs({required this.jsonStr, required this.gridCellSizeDeg});
  final String jsonStr;
  final double gridCellSizeDeg;
}

class _ParseResult {
  const _ParseResult({required this.segments, required this.gridIndex});
  final List<RoadSegment> segments;
  final Map<String, List<int>> gridIndex;
}

/// Runs on a background isolate via compute(). Must be a top-level (or
/// static) function — closures/instance methods can't be sent to an
/// isolate.
_ParseResult _parseGraphJson(_ParseArgs args) {
  final data = jsonDecode(args.jsonStr) as Map<String, dynamic>;
  final rawSegments = data['segments'] as List<dynamic>;

  final segments = <RoadSegment>[];
  for (final s in rawSegments) {
    final points = s['points'] as List<dynamic>;
    if (points.length < 2) continue;
    final a = points[0] as List<dynamic>;
    final b = points[1] as List<dynamic>;
    segments.add(RoadSegment(
      id: s['id'] as String,
      aLat: (a[0] as num).toDouble(),
      aLon: (a[1] as num).toDouble(),
      bLat: (b[0] as num).toDouble(),
      bLon: (b[1] as num).toDouble(),
    ));
  }

  final gridIndex = <String, List<int>>{};
  for (var i = 0; i < segments.length; i++) {
    final seg = segments[i];
    final midLat = (seg.aLat + seg.bLat) / 2;
    final midLon = (seg.aLon + seg.bLon) / 2;
    final key = OsmGraph._gridKey(midLat, midLon, args.gridCellSizeDeg);
    gridIndex.putIfAbsent(key, () => []).add(i);
  }

  return _ParseResult(segments: segments, gridIndex: gridIndex);
}