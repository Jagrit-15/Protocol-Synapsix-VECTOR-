/// PLACEHOLDER OSM graph loader. Real slice will parse a local extract.
class OsmGraph {
  const OsmGraph({this.nodeCount = 0, this.edgeCount = 0});

  final int nodeCount;
  final int edgeCount;

  static OsmGraph empty() => const OsmGraph();
}
