import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'features/map_matching/osm_graph/osm_graph.dart';
import 'services/sensor_pipeline_service.dart';
import 'services/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await AppSupabaseClient().init();

  // Start real sensor streaming + SQLite logging app-wide. Failures here
  // (e.g. permissions denied) are swallowed so the app still launches —
  // the debug screen will show sensors as unavailable instead of crashing.
  try {
    await SensorPipelineService.instance.start();
  } catch (_) {}

  // Load the Kolkata road graph once at startup. JSON parsing runs on a
  // background isolate (see OsmGraph.loadFromAsset) so this ~25MB file
  // doesn't freeze the UI thread. Falls back to an empty graph if the
  // asset is missing/corrupt, so map-matching just no-ops instead of
  // crashing the app.
  OsmGraph osmGraph;
  try {
    osmGraph = await OsmGraph.loadFromAsset('assets/maps/kolkata_road_graph.json');
  } catch (e) {
    debugPrint('Failed to load OSM graph: $e');
    osmGraph = OsmGraph.empty();
  }

  runApp(ProtocolSynapsixApp(osmGraph: osmGraph));
}