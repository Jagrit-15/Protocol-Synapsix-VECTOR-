// TODO(agentic-workflow): replace with real implementation — see Map Matching Agent spec
//
// Real job: HMM (or equivalent) map-matcher that snaps fused ENU/lat-lon onto
// an OSM graph, using heading + covariance as observation noise.
//
// DEMO: return the input unchanged (no-op passthrough).

import 'snapped_position.dart';

abstract class MapMatchingAgent {
  SnappedPosition snap({
    required double lat,
    required double lon,
    double? headingDeg,
  });
}

class PassthroughMapMatchingAgent implements MapMatchingAgent {
  @override
  SnappedPosition snap({
    required double lat,
    required double lon,
    double? headingDeg,
  }) {
    return SnappedPosition(lat: lat, lon: lon);
  }
}
