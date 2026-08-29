/// App-wide constants. Secrets must never be hardcoded — use --dart-define or .env.
class AppConstants {
  static const String appName = 'Protocol Synapsix';
  static const String problemCode = 'SIH26168';

  /// Demo origin (New Delhi). PLACEHOLDER until live GNSS origin is wired.
  static const double demoOriginLat = 28.6139;
  static const double demoOriginLon = 77.2090;

  static const Duration pipelineTick = Duration(milliseconds: 500);
  static const Duration gnssDropoutDuration = Duration(seconds: 20);
  static const Duration gnssPresentDuration = Duration(seconds: 12);

  static const double tightCovarianceM = 6.0;
  static const double maxCovarianceM = 85.0;

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'protocol.synapsix.mobile';
}
