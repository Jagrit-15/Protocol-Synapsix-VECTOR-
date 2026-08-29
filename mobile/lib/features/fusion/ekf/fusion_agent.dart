// TODO(agentic-workflow): replace with real implementation — see Fusion Agent / EKF spec
//
// Real job: error-state EKF/UKF that fuses GNSS (when present) with learned
// odometry. Output {x, y, heading, covarianceMajor, covarianceMinor}. Pure
// Dart — this file must never import Flutter widgets.
//
// DEMO: simple linear blend of GNSS vs dead-reckoned pose. Covariance grows
// while GNSS is absent and shrinks when GNSS is present. No Kalman math.

import '../odometry_model/odometry_estimate.dart';
import 'fused_pose.dart';

abstract class FusionAgent {
  FusedPose fuse({
    required FusedPose previous,
    required OdometryEstimate odometry,
    double? gnssEastM,
    double? gnssNorthM,
    double? gnssHeadingDeg,
    required bool gnssPresent,
  });
}

class LinearBlendFusionAgent implements FusionAgent {
  LinearBlendFusionAgent({
    this.tightCovarianceM = 6.0,
    this.maxCovarianceM = 85.0,
    this.growPerStepM = 3.5,
    this.shrinkPerStepM = 12.0,
  });

  final double tightCovarianceM;
  final double maxCovarianceM;
  final double growPerStepM;
  final double shrinkPerStepM;

  @override
  FusedPose fuse({
    required FusedPose previous,
    required OdometryEstimate odometry,
    double? gnssEastM,
    double? gnssNorthM,
    double? gnssHeadingDeg,
    required bool gnssPresent,
  }) {
    final predictedX = previous.x + odometry.deltaX;
    final predictedY = previous.y + odometry.deltaY;
    final predictedHeading = previous.heading + odometry.deltaHeading;

    double x = predictedX;
    double y = predictedY;
    double heading = predictedHeading;
    double covMajor = previous.covarianceMajor;
    double covMinor = previous.covarianceMinor;

    if (gnssPresent && gnssEastM != null && gnssNorthM != null) {
      const gnssWeight = 0.8;
      x = gnssWeight * gnssEastM + (1 - gnssWeight) * predictedX;
      y = gnssWeight * gnssNorthM + (1 - gnssWeight) * predictedY;
      heading = gnssHeadingDeg ?? predictedHeading;
      covMajor =
          (covMajor - shrinkPerStepM).clamp(tightCovarianceM, maxCovarianceM);
      covMinor = (covMinor - shrinkPerStepM * 0.6)
          .clamp(tightCovarianceM * 0.6, maxCovarianceM);
    } else {
      covMajor =
          (covMajor + growPerStepM).clamp(tightCovarianceM, maxCovarianceM);
      covMinor = (covMinor + growPerStepM * 0.55)
          .clamp(tightCovarianceM * 0.6, maxCovarianceM);
    }

    return FusedPose(
      x: x,
      y: y,
      heading: heading,
      covarianceMajor: covMajor,
      covarianceMinor: covMinor,
    );
  }
}
