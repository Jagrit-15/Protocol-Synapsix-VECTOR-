import '../../fusion/ekf/fused_pose.dart';
import '../../fusion/motion_classifier/motion_state.dart';
import '../../map_matching/hmm_matcher/snapped_position.dart';
import 'gnss_status.dart';

class CovarianceSample {
  const CovarianceSample({required this.tSec, required this.majorM});

  final double tSec;
  final double majorM;
}

class PipelineSnapshot {
  const PipelineSnapshot({
    required this.tickIndex,
    required this.gnssPresent,
    required this.gnssStatus,
    required this.motion,
    required this.pose,
    required this.snapped,
    required this.covarianceHistory,
    this.lastError,
  });

  final int tickIndex;
  final bool gnssPresent;
  final GnssStatus gnssStatus;
  final MotionClassification motion;
  final FusedPose pose;
  final SnappedPosition snapped;
  final List<CovarianceSample> covarianceHistory;
  final String? lastError;
}
