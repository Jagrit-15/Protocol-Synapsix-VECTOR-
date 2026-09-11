import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/utils/coordinate_transforms.dart';
import '../../fusion/ekf/fused_pose.dart';
import '../../fusion/ekf/fusion_agent.dart';
import '../../fusion/motion_classifier/motion_classifier_agent.dart';
import '../../fusion/motion_classifier/motion_state.dart';
import '../../fusion/odometry_model/learned_odometry_agent.dart';
import '../../map_matching/hmm_matcher/map_matching_agent.dart';
import '../../map_matching/hmm_matcher/snapped_position.dart';
import '../../sensors/domain/sensor_frame.dart';
import '../../sensors/domain/sensor_ingestion_agent.dart';
import 'gnss_status.dart';
import 'pipeline_snapshot.dart';

/// Drives the tunnel GNSS-loss demo end-to-end with zero real sensors/backend.
///
/// Cycle: GNSS present (tight ellipse) → GNSS drops ~20s (ellipse grows,
/// badge = Dead-Reckoning Active) → GNSS reacquires (ellipse snaps tight).
class DemoScenarioController extends ChangeNotifier {
  DemoScenarioController({
    SensorIngestionAgent? ingestion,
    MotionClassifierAgent? classifier,
    LearnedOdometryAgent? odometry,
    FusionAgent? fusion,
    MapMatchingAgent? matcher,
  })  : _ingestion = ingestion ?? PassthroughSensorIngestionAgent(),
        _classifier = classifier ?? ScriptedMotionClassifierAgent(),
        _odometry = odometry ?? BoundedRandomOdometryAgent(),
        _fusion = fusion ?? LinearBlendFusionAgent(),
        _matcher = matcher ?? PassthroughMapMatchingAgent(); // TODO: swap to HmmMapMatchingAgent once OsmGraph is loaded at app startup (async — see osm_graph.dart's loadFromAsset)

  final SensorIngestionAgent _ingestion;
  final MotionClassifierAgent _classifier;
  final LearnedOdometryAgent _odometry;
  final FusionAgent _fusion;
  final MapMatchingAgent _matcher;

  Timer? _timer;
  int _tickIndex = 0;
  FusedPose _pose = const FusedPose(
    x: 0,
    y: 0,
    heading: 0,
    covarianceMajor: AppConstants.tightCovarianceM,
    covarianceMinor: AppConstants.tightCovarianceM * 0.6,
  );
  final List<SensorFrame> _window = [];
  final List<CovarianceSample> _covHistory = [];
  String? _lastError;
  MotionClassification _lastMotion = const MotionClassification(
    stateLabel: MotionState.stationary,
    confidence: 1,
  );
  SnappedPosition _lastSnapped = const SnappedPosition(
    lat: AppConstants.demoOriginLat,
    lon: AppConstants.demoOriginLon,
  );

  PipelineSnapshot get snapshot => PipelineSnapshot(
        tickIndex: _tickIndex,
        gnssPresent: gnssPresent,
        gnssStatus: gnssStatus,
        motion: _lastMotion,
        pose: _pose,
        snapped: _lastSnapped,
        covarianceHistory: List.unmodifiable(_covHistory),
        lastError: _lastError,
      );

  bool get gnssPresent {
    final cycle =
        AppConstants.gnssPresentDuration + AppConstants.gnssDropoutDuration;
    final elapsed = AppConstants.pipelineTick * _tickIndex;
    final inCycle = Duration(
      milliseconds: elapsed.inMilliseconds % cycle.inMilliseconds,
    );
    return inCycle < AppConstants.gnssPresentDuration;
  }

  GnssStatus get gnssStatus {
    if (gnssPresent) {
      return _pose.covarianceMajor < 15 ? GnssStatus.good : GnssStatus.degraded;
    }
    return GnssStatus.deadReckoningActive;
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(AppConstants.pipelineTick, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  Future<void> _tick() async {
    try {
      final mock = _syntheticFrame();
      final frame = await _ingestion.ingest(mockOverride: mock);
      _window.add(frame);
      if (_window.length > 16) {
        _window.removeAt(0);
      }

      _lastMotion = _classifier.classify(_window, tickIndex: _tickIndex);
      if (!gnssPresent) {
        _lastMotion = MotionClassification(
          stateLabel: MotionState.possibleTunnel,
          confidence: _lastMotion.confidence,
        );
      }

      final odo = _odometry.estimate(
        frame: frame,
        stateLabel: _lastMotion.stateLabel,
        tickIndex: _tickIndex,
      );

      double? gnssEast;
      double? gnssNorth;
      if (gnssPresent && frame.gnss != null) {
        final enu = CoordinateTransforms.latLonToEnu(
          lat: frame.gnss!.lat,
          lon: frame.gnss!.lon,
          originLat: AppConstants.demoOriginLat,
          originLon: AppConstants.demoOriginLon,
        );
        gnssEast = enu.eastM;
        gnssNorth = enu.northM;
      }

      _pose = _fusion.fuse(
        previous: _pose,
        odometry: odo,
        gnssEastM: gnssEast,
        gnssNorthM: gnssNorth,
        gnssHeadingDeg: frame.gnss?.headingDeg,
        gnssPresent: gnssPresent,
      );

      final geo = CoordinateTransforms.enuToLatLon(
        eastM: _pose.x,
        northM: _pose.y,
        originLat: AppConstants.demoOriginLat,
        originLon: AppConstants.demoOriginLon,
      );
      _lastSnapped = _matcher.snap(
        lat: geo.lat,
        lon: geo.lon,
        headingDeg: _pose.heading,
      );

      final tSec =
          _tickIndex * AppConstants.pipelineTick.inMilliseconds / 1000.0;
      _covHistory.add(
        CovarianceSample(tSec: tSec, majorM: _pose.covarianceMajor),
      );
      if (_covHistory.length > 240) {
        _covHistory.removeAt(0);
      }

      _lastError = null;
      _tickIndex += 1;
      notifyListeners();
    } catch (e) {
      _lastError = e is AppException ? e.message : e.toString();
      notifyListeners();
    }
  }

  SensorFrame _syntheticFrame() {
    final meters = _tickIndex * 1.2;
    final geo = CoordinateTransforms.enuToLatLon(
      eastM: meters * 0.15,
      northM: meters,
      originLat: AppConstants.demoOriginLat,
      originLon: AppConstants.demoOriginLon,
    );
    return SensorFrame(
      timestamp: DateTime.now(),
      accel: const Vector3(0, 0, 9.81),
      gyro: const Vector3(0, 0, 0),
      mag: const Vector3(20, 0, 40),
      baroHpa: 1013,
      gnss: gnssPresent
          ? GnssFix(
              lat: geo.lat,
              lon: geo.lon,
              accuracyM: 4.5,
              headingDeg: 8,
            )
          : null,
    );
  }
}
