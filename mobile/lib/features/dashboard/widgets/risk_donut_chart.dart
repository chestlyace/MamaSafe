import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/tr.dart';

class RiskDonutChart extends ConsumerWidget {
  final int highRisk;
  final int midRisk;
  final int lowRisk;
  final int totalAssessments;

  const RiskDonutChart({
    super.key,
    required this.highRisk,
    required this.midRisk,
    required this.lowRisk,
    required this.totalAssessments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = [
      if (highRisk > 0) highRisk,
      if (midRisk > 0) midRisk,
      if (lowRisk > 0) lowRisk,
    ];
    if (values.isEmpty) {
      return Center(
        child: Text(tr(ref, 'dashboard.noAssessments'),
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    final colors = [
      AppColors.error,
      AppColors.warning,
      AppColors.success,
    ];

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 48,
              sections: List.generate(values.length, (i) {
                return PieChartSectionData(
                  value: values[i].toDouble(),
                  color: colors[i],
                  radius: 36,
                  title: '',
                );
              }),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$totalAssessments',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(tr(ref, 'dashboard.assessments'),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
