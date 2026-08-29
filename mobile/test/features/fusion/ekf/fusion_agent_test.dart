import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/fusion/ekf/fused_pose.dart';
import 'package:mobile/features/fusion/ekf/fusion_agent.dart';
import 'package:mobile/features/fusion/odometry_model/odometry_estimate.dart';

void main() {
  group('LinearBlendFusionAgent (placeholder, not real EKF)', () {
    const start = FusedPose(
      x: 0,
      y: 0,
      heading: 0,
      covarianceMajor: 6,
      covarianceMinor: 3.6,
    );
    const odo = OdometryEstimate(
      deltaX: 1,
      deltaY: 2,
      deltaHeading: 0.01,
      uncertainty: 1,
    );

    test('covariance grows when GNSS is absent', () {
      final agent = LinearBlendFusionAgent();
      final next = agent.fuse(
        previous: start,
        odometry: odo,
        gnssPresent: false,
      );
      expect(next.covarianceMajor, greaterThan(start.covarianceMajor));
      expect(next.x, closeTo(1, 1e-9));
      expect(next.y, closeTo(2, 1e-9));
    });

    test('covariance shrinks when GNSS is present', () {
      final agent = LinearBlendFusionAgent();
      final grown = agent.fuse(
        previous: start,
        odometry: odo,
        gnssPresent: false,
      );
      final recovered = agent.fuse(
        previous: grown,
        odometry: odo,
        gnssEastM: 10,
        gnssNorthM: 20,
        gnssPresent: true,
      );
      expect(recovered.covarianceMajor, lessThan(grown.covarianceMajor));
    });
  });
}
