import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/navigation/presentation/debug_screen.dart';
import 'features/navigation/presentation/home_map_screen.dart';
import 'features/navigation/presentation/onboarding_screen.dart';
import 'features/navigation/presentation/turn_by_turn_screen.dart';
import 'features/sensors/presentation/sensor_debug_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/trips/presentation/trip_history_screen.dart';
import 'features/trips/presentation/trip_summary_screen.dart';

class ProtocolSynapsixApp extends StatelessWidget {
  const ProtocolSynapsixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.light(),
        initialRoute: '/onboarding',
        routes: {
          '/onboarding': (_) => const OnboardingScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeMapScreen(),
          '/navigate': (_) => const TurnByTurnScreen(),
          '/trips': (_) => TripHistoryScreen(),
          '/trip-summary': (_) => TripSummaryScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/debug': (_) => const DebugScreen(),
          '/sensor-debug': (_) => const SensorDebugScreen(),
        },
      ),
    );
  }
}