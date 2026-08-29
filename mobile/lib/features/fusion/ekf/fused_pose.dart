class FusedPose {
  const FusedPose({
    required this.x,
    required this.y,
    required this.heading,
    required this.covarianceMajor,
    required this.covarianceMinor,
  });

  final double x;
  final double y;
  final double heading;
  final double covarianceMajor;
  final double covarianceMinor;
}
