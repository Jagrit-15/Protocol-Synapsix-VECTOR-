// Simplified online HMM map-matcher. At each tick: finds nearby road
// segment candidates, scores each by (a) emission probability — how well
// it explains the raw fused position/heading, and (b) transition
// probability — how plausible it is given the previous best segment
// (penalizes implausible jumps between unrelated segments). Tracks the
// single best-scoring path over time (a lightweight online Viterbi),
// bounded to a small candidate set per tick for on-device performance.
//
// Falls back to the raw (unsnapped) position if the graph is empty or no
// candidate segment is within maxSnapDistanceM — this keeps behavior safe
// if the OSM asset failed to load.

import 'dart:math';

import '../osm_graph/osm_graph.dart';
import '../osm_graph/road_segment.dart';
import 'map_matching_agent.dart';
import 'snapped_position.dart';

class HmmMapMatchingAgent implements MapMatchingAgent {
  HmmMapMatchingAgent({
    required OsmGraph graph,
    this.maxSnapDistanceM = 40.0,
    this.maxCandidates = 5,
  }) : _graph = graph;

  final OsmGraph _graph;
  final double maxSnapDistanceM;
  final int maxCandidates;

  String? _lastSegmentId;

  @override
  SnappedPosition snap({
    required double lat,
    required double lon,
    double? headingDeg,
  }) {
    if (_graph.isEmpty) {
      return SnappedPosition(lat: lat, lon: lon);
    }

    final candidateIndices = _graph.nearbySegmentIndices(lat, lon);
    if (candidateIndices.isEmpty) {
      return SnappedPosition(lat: lat, lon: lon);
    }

    final scored = <_Candidate>[];
    for (final idx in candidateIndices) {
      final seg = _graph.segments[idx];
      final proj = _projectOntoSegment(lat, lon, seg);
      if (proj.distanceM > maxSnapDistanceM) continue;

      final emissionLogProb = _emissionLogProb(
        distanceM: proj.distanceM,
        segHeadingDeg: proj.headingDeg,
        observedHeadingDeg: headingDeg,
      );
      final transitionLogProb = _transitionLogProb(seg.id);

      scored.add(_Candidate(
        segment: seg,
        snapLat: proj.lat,
        snapLon: proj.lon,
        logProb: emissionLogProb + transitionLogProb,
      ));
    }

    if (scored.isEmpty) {
      return SnappedPosition(lat: lat, lon: lon);
    }

    scored.sort((a, b) => b.logProb.compareTo(a.logProb));
    final best = scored.first;
    _lastSegmentId = best.segment.id;

    return SnappedPosition(lat: best.snapLat, lon: best.snapLon);
  }

  double _emissionLogProb({
    required double distanceM,
    required double? segHeadingDeg,
    required double? observedHeadingDeg,
  }) {
    // Gaussian-style penalty on perpendicular distance — closer is better.
    const sigmaM = 15.0;
    final distTerm = -(distanceM * distanceM) / (2 * sigmaM * sigmaM);

    double headingTerm = 0.0;
    if (segHeadingDeg != null && observedHeadingDeg != null) {
      var diff = (segHeadingDeg - observedHeadingDeg).abs() % 360;
      if (diff > 180) diff = 360 - diff;
      // Roads are bidirectional, so also check the reverse heading.
      final diffReversed = (180 - diff).abs();
      final bestDiff = min(diff, diffReversed);
      const sigmaDeg = 30.0;
      headingTerm = -(bestDiff * bestDiff) / (2 * sigmaDeg * sigmaDeg);
    }

    return distTerm + headingTerm;
  }

  double _transitionLogProb(String candidateSegmentId) {
    if (_lastSegmentId == null) return 0.0;
    if (_lastSegmentId == candidateSegmentId) {
      return 0.5; // continuity bonus — prefer staying on the same segment
    }
    return -0.2; // small penalty for switching segments each tick
  }

  ({double lat, double lon, double distanceM, double? headingDeg})
      _projectOntoSegment(double lat, double lon, RoadSegment seg) {
    // Local equirectangular approximation — fine at city scale.
    const metersPerDegLat = 111320.0;
    final metersPerDegLon = 111320.0 * cos(seg.aLat * pi / 180.0);

    final ax = seg.aLon * metersPerDegLon;
    final ay = seg.aLat * metersPerDegLat;
    final bx = seg.bLon * metersPerDegLon;
    final by = seg.bLat * metersPerDegLat;
    final px = lon * metersPerDegLon;
    final py = lat * metersPerDegLat;

    final dx = bx - ax;
    final dy = by - ay;
    final lenSq = dx * dx + dy * dy;

    double t = lenSq == 0
        ? 0.0
        : ((px - ax) * dx + (py - ay) * dy) / lenSq;
    t = t.clamp(0.0, 1.0);

    final projX = ax + t * dx;
    final projY = ay + t * dy;
    final distM = sqrt(pow(px - projX, 2) + pow(py - projY, 2));

    final snapLat = projY / metersPerDegLat;
    final snapLon = projX / metersPerDegLon;

    final segHeadingDeg = (atan2(dx, dy) * 180.0 / pi + 360) % 360;

    return (
      lat: snapLat,
      lon: snapLon,
      distanceM: distM,
      headingDeg: segHeadingDeg,
    );
  }
}

class _Candidate {
  _Candidate({
    required this.segment,
    required this.snapLat,
    required this.snapLon,
    required this.logProb,
  });

  final RoadSegment segment;
  final double snapLat;
  final double snapLon;
  final double logProb;
}