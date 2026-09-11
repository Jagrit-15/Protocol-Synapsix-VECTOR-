// Live location controller — reads real GNSS fixes directly from the
// app-wide SensorPipelineService (already running real sensors + GPS via
// SensorDataSource, started in main.dart) and exposes the latest fix for
// the map to render.
//
// Deliberately bypasses the EKF/fusion/odometry/map-matching pipeline —
// Phase 3's odometry model isn't trained yet, so this shows raw GNSS
// position only. Swap this out once Phase 3 completes and a full live
// pipeline (mirroring DemoScenarioController's tick logic but fed real
// frames) makes sense.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../services/sensor_pipeline_service.dart';
import '../../sensors/domain/sensor_frame.dart';

class LiveLocationController extends ChangeNotifier {
  LiveLocationController({SensorPipelineService? service})
      : _service = service ?? SensorPipelineService.instance {
    _subscription = _service.frames.listen(_onFrame);
  }

  final SensorPipelineService _service;
  StreamSubscription<SensorFrame>? _subscription;

  double? lat;
  double? lon;
  double? accuracyM;
  double? headingDeg;

  bool get hasFix => lat != null && lon != null;

  void _onFrame(SensorFrame frame) {
    final gnss = frame.gnss;
    if (gnss == null) return; // no fix this tick — keep last known position
    lat = gnss.lat;
    lon = gnss.lon;
    accuracyM = gnss.accuracyM;
    headingDeg = gnss.headingDeg;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}