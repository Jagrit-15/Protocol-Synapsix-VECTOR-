"""
Converts raw Overpass API OSM JSON (way + node data) into a lightweight
road-segment graph for offline on-device map-matching.

Usage:
  python build_road_graph.py --input raw_kolkata_osm.json \
      --output ../../mobile/assets/maps/kolkata_road_graph.json

Output schema (consumed by lib/features/map_matching/osm_graph/osm_graph.dart):
{
  "segments": [
    {
      "id": "way_12345_0",
      "points": [[lat, lon], [lat, lon], ...]
    },
    ...
  ]
}
Each OSM way is split into one segment per consecutive node pair (so every
segment is a simple 2-point line), which keeps the Dart-side nearest-point
math trivial (no polyline projection needed, just point-to-segment math).
"""

import argparse
import json


def build_graph(raw: dict) -> dict:
    nodes = {}
    ways = []

    for el in raw.get("elements", []):
        if el["type"] == "node":
            nodes[el["id"]] = (el["lat"], el["lon"])
        elif el["type"] == "way":
            ways.append(el)

    segments = []
    for way in ways:
        node_ids = way.get("nodes", [])
        way_id = way["id"]
        seg_index = 0
        for i in range(len(node_ids) - 1):
            a = nodes.get(node_ids[i])
            b = nodes.get(node_ids[i + 1])
            if a is None or b is None:
                continue
            segments.append({
                "id": f"way_{way_id}_{seg_index}",
                "points": [[a[0], a[1]], [b[0], b[1]]],
            })
            seg_index += 1

    return {"segments": segments}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as f:
        raw = json.load(f)

    graph = build_graph(raw)

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(graph, f)

    print(f"Wrote {len(graph['segments'])} segments to {args.output}")


if __name__ == "__main__":
    main()