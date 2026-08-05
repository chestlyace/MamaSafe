import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/storage/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/tr.dart';
import '../growth_repository.dart';

final _childRecordsProvider = FutureProvider.family<List<GrowthRecord>, String>(
    (ref, childRef) async {
  final repo = ref.watch(growthRepositoryProvider);
  return repo.getRecordsForChild(childRef);
});

class GrowthChartScreen extends ConsumerWidget {
  final String childRef;

  const GrowthChartScreen({super.key, required this.childRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(_childRecordsProvider(childRef));

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'growth.chartFor', {'child': childRef}))),
      body: recordsAsync.when(
        data: (records) {
          if (records.length < 2) {
            return Center(
              child: Text(tr(ref, 'growth.needTwoRecords')),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(ref, 'growth.weightForAgeTrend'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: _LineChart(
                    records: records,
                    getValue: (r) => r.weight,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(_childRecordsProvider(childRef))),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<GrowthRecord> records;
  final double Function(GrowthRecord) getValue;

  const _LineChart({
    required this.records,
    required this.getValue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(
        records: records,
        getValue: getValue,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<GrowthRecord> records;
  final double Function(GrowthRecord) getValue;

  _LineChartPainter({
    required this.records,
    required this.getValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padding = EdgeInsets.fromLTRB(50, 20, 20, 40);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    final values = records.map(getValue).toList();
    final ages = records.map((r) => r.ageMonths.toDouble()).toList();
    final minAge = ages.reduce(min);
    final maxAge = ages.reduce(max);
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final valRange = maxVal - minVal;
    final ageRange = maxAge - minAge;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    const textStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
    );

    for (int i = 0; i <= 4; i++) {
      final y = padding.top + chartHeight * (i / 4);
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        gridPaint,
      );
      final val = maxVal - valRange * (i / 4);
      final tp = TextPainter(
        text: TextSpan(text: val.toStringAsFixed(1), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: padding.left - 8);
      tp.paint(canvas, Offset(padding.left - tp.width - 4, y - tp.height / 2));
    }

    for (int i = 0; i < ages.length; i++) {
      if (ageRange == 0) return;
      final x = padding.left + chartWidth * ((ages[i] - minAge) / ageRange);
      canvas.drawLine(
        Offset(x, padding.top),
        Offset(x, padding.top + chartHeight),
        gridPaint,
      );
      final tp = TextPainter(
        text: TextSpan(text: '${ages[i].toInt()}m', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 40);
      tp.paint(canvas, Offset(x - tp.width / 2, padding.top + chartHeight + 4));
    }

    if (ageRange == 0 || valRange == 0) return;

    final points = <Offset>[];
    for (int i = 0; i < records.length; i++) {
      final x = padding.left + chartWidth * ((ages[i] - minAge) / ageRange);
      final y = padding.top + chartHeight * (1 - (values[i] - minVal) / valRange);
      points.add(Offset(x, y));
    }

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
    }

    canvas.drawCircle(points.last, 6, dotPaint..color = AppColors.accent);
    dotPaint.color = AppColors.primary;
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.records != records;
}
