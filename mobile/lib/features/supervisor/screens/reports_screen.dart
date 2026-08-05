import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/tr.dart';
import '../supervisor_repository.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final reportAsync =
        ref.watch(monthlyReportProvider((year: _year, month: _month)));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'supervisor.monthlyReport')),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration:
                        InputDecoration(labelText: tr(ref, 'supervisor.year')),
                    items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                        value: DateTime.now().year - i,
                        child: Text('${DateTime.now().year - i}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _year = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration:
                        InputDecoration(labelText: tr(ref, 'supervisor.month')),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                            '${DateTime(0, i + 1).month} — ${_monthName(ref, i + 1)}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _month = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reportAsync.when(
              data: (r) => _buildReport(context, ref, r),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                error: e,
                onRetry: () => ref.invalidate(
                    monthlyReportProvider((year: _year, month: _month))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(WidgetRef ref, int m) {
    const keys = [
      'month.january', 'month.february', 'month.march', 'month.april',
      'month.may', 'month.june', 'month.july', 'month.august',
      'month.september', 'month.october', 'month.november', 'month.december',
    ];
    return tr(ref, keys[m - 1]);
  }

  Widget _buildReport(BuildContext context, WidgetRef ref, MonthlyReport r) {
    final sections = <(String, List<(String, String)>)>[
      (tr(ref, 'supervisor.repWorkforce'), [
        (tr(ref, 'supervisor.totalChws'), '${r.totalChws}'),
        (tr(ref, 'supervisor.activeChws'), '${r.activeChws}'),
      ]),
      (tr(ref, 'supervisor.repPatients'), [
        (tr(ref, 'supervisor.totalRegistered'), '${r.totalPatientsRegistered}'),
        (tr(ref, 'supervisor.newThisMonth'), '${r.newPatientsThisMonth}'),
      ]),
      (tr(ref, 'supervisor.repAssessmentsRisk'), [
        (tr(ref, 'supervisor.totalAssessments'), '${r.totalAssessments}'),
        (tr(ref, 'supervisor.highRiskDetected'), '${r.highRiskDetected}'),
        (tr(ref, 'supervisor.midRiskDetected'), '${r.midRiskDetected}'),
        (tr(ref, 'supervisor.lowRiskDetected'), '${r.lowRiskDetected}'),
      ]),
      (tr(ref, 'supervisor.repReferrals'), [
        (tr(ref, 'supervisor.totalReferrals'), '${r.totalReferrals}'),
        (tr(ref, 'supervisor.completionRate'),
            '${r.referralCompletionRate.toStringAsFixed(1)}%'),
      ]),
      (tr(ref, 'supervisor.repDeliveriesPnc'), [
        (tr(ref, 'supervisor.totalDeliveries'), '${r.totalDeliveries}'),
        (tr(ref, 'supervisor.liveBirths'), '${r.liveBirths}'),
        (tr(ref, 'supervisor.stillbirths'), '${r.stillbirths}'),
        (tr(ref, 'supervisor.pnc1Completion'),
            '${r.pnc1CompletionRate.toStringAsFixed(1)}%'),
        (tr(ref, 'supervisor.pnc2Completion'),
            '${r.pnc2CompletionRate.toStringAsFixed(1)}%'),
        (tr(ref, 'supervisor.pnc3Completion'),
            '${r.pnc3CompletionRate.toStringAsFixed(1)}%'),
      ]),
      (tr(ref, 'supervisor.repMaternalHealth'), [
        (tr(ref, 'supervisor.phq2Screens'), '${r.phq2ScreensPerformed}'),
        (tr(ref, 'supervisor.phq2Positive'), '${r.phq2PositiveCount}'),
        (tr(ref, 'supervisor.growthAlertsGenerated'),
            '${r.growthAlertsGenerated}'),
        (tr(ref, 'supervisor.exclusiveBreastfeeding'),
            '${r.exclusiveBreastfeedingRate.toStringAsFixed(1)}%'),
      ]),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          r.reportingPeriod,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${r.district} · ${r.region}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 20),
        ...sections.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.$1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: s.$2
                        .map((row) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(row.$1,
                                          style: const TextStyle(
                                              fontSize: 14))),
                                  Text(row.$2,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
