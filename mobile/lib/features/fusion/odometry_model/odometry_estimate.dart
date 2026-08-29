class OdometryEstimate {
  const OdometryEstimate({
    required this.deltaX,
    required this.deltaY,
    required this.deltaHeading,
    required this.uncertainty,
  });

  final double deltaX;
  final double deltaY;
  final double deltaHeading;
  final double uncertainty;
}
