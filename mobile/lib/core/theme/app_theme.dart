import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0B6E4F),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static const Color gnssGood = Color(0xFF1B9E4B);
  static const Color gnssDegraded = Color(0xFFE0A100);
  static const Color gnssDeadReckoning = Color(0xFFC0392B);
}
