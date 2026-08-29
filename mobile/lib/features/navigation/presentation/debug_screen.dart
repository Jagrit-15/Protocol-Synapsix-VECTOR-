import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pipeline_providers.dart';

/// Hidden debug plot of mock covariance growth/shrink.
class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(demoScenarioProvider).snapshot.covarianceHistory;
    return Scaffold(
      appBar: AppBar(title: const Text('Debug · covariance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: history.length < 2
            ? const Center(child: Text('Collecting samples…'))
            : LineChart(
                LineChartData(
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (final s in history) FlSpot(s.tSec, s.majorM),
                      ],
                      isCurved: false,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
