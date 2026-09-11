import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../map_matching/hmm_matcher/hmm_map_matching_agent.dart';
import '../../map_matching/osm_graph/osm_graph_provider.dart';
import '../domain/demo_scenario_controller.dart';
import '../domain/live_location_controller.dart';

final demoScenarioProvider = ChangeNotifierProvider<DemoScenarioController>((
  ref,
) {
  final graph = ref.watch(osmGraphProvider);
  final controller = DemoScenarioController(
    matcher: HmmMapMatchingAgent(graph: graph),
  );
  controller.start();
  ref.onDispose(controller.dispose);
  return controller;
});

final liveLocationProvider = ChangeNotifierProvider<LiveLocationController>((
  ref,
) {
  final controller = LiveLocationController();
  ref.onDispose(controller.dispose);
  return controller;
});