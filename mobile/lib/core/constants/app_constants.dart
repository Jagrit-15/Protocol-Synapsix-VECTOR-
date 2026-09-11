import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide constants. Secrets must never be hardcoded — use --dart-define or .env.
class AppConstants {
  static const String appName = 'Protocol Synapsix';
  static const String problemCode = 'SIH26168';

  /// Demo origin (Kolkata — BBD Bagh area, matches a known segment in
  /// kolkata_road_graph.json so the synthetic demo path snaps to real roads).
  static const double demoOriginLat = 22.5539;
  static const double demoOriginLon = 88.3318;

  static const Duration pipelineTick = Duration(milliseconds: 500);
  static const Duration gnssDropoutDuration = Duration(seconds: 20);
  static const Duration gnssPresentDuration = Duration(seconds: 12);

  static const double tightCovarianceM = 6.0;
  static const double maxCovarianceM = 85.0;

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'protocol.synapsix.mobile';
}