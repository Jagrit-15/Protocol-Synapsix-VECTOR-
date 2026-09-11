import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'osm_graph.dart';

/// Overridden in [ProtocolSynapsixApp] with the graph loaded at startup
/// (see main.dart). Throwing here if unoverridden makes a missing
/// override fail loudly instead of silently falling back to an empty
/// graph and hiding the bug.
final osmGraphProvider = Provider<OsmGraph>((ref) {
  throw UnimplementedError('osmGraphProvider must be overridden at app startup');
});