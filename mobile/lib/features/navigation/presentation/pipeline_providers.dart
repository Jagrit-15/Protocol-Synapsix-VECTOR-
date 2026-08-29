import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/demo_scenario_controller.dart';

final demoScenarioProvider = ChangeNotifierProvider<DemoScenarioController>((
  ref,
) {
  final controller = DemoScenarioController();
  controller.start();
  ref.onDispose(controller.dispose);
  return controller;
});
