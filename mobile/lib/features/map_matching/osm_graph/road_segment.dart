/// A single straight-line road segment: two lat/lon points. Built by
/// splitting each OSM way into consecutive point pairs (see
/// ml/map/build_road_graph.py) so matching only ever needs simple
/// point-to-line-segment math, not full polyline projection.
class RoadSegment {
  const RoadSegment({
    required this.id,
    required this.aLat,
    required this.aLon,
    required this.bLat,
    required this.bLon,
  });

  final String id;
  final double aLat;
  final double aLon;
  final double bLat;
  final double bLon;
}