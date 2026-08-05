import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../supervisor_repository.dart';

class ReferralAnalyticsScreen extends ConsumerWidget {
  const ReferralAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(referralAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'supervisor.referralAnalytics')),
        automaticallyImplyLeading: false,
      ),
      body: analyticsAsync.when(
        data: (a) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _SectionTitle(tr(ref, 'supervisor.funnel')),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _row(tr(ref, 'supervisor.totalReferrals'), '${a.totalReferrals}'),
                  _row(tr(ref, 'supervisor.sent'), '${a.sent}'),
                  _row(tr(ref, 'supervisor.received'), '${a.received}'),
                  _row(tr(ref, 'supervisor.patientArrived'), '${a.patientArrived}'),
                  _row(tr(ref, 'supervisor.completionRate'), '${a.completionRate.toStringAsFixed(1)}%'),
                  if (a.avgHoursToReceipt != null)
                    _row(tr(ref, 'supervisor.avgHoursToReceipt'), a.avgHoursToReceipt!.toStringAsFixed(1)),
                  if (a.avgHoursToArrival != null)
                    _row(tr(ref, 'supervisor.avgHoursToArrival'), a.avgHoursToArrival!.toStringAsFixed(1)),
                  _row(tr(ref, 'supervisor.highRiskReferrals'), '${a.highRiskReferrals}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(tr(ref, 'supervisor.byFacility')),
            const SizedBox(height: 12),
            if (a.byFacility.isEmpty)
              EmptyState(
                  icon: Icons.local_hospital_outlined,
                  title: tr(ref, 'supervisor.noReferralData'),
                  subtitle: tr(ref, 'supervisor.noReferralsYet'))
            else
              ...a.byFacility.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BreakdownCard(
                    title: f.facilityName,
                    total: f.total,
                    arrived: f.arrived,
                    rate: f.completionRate,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            _SectionTitle(tr(ref, 'supervisor.byChw')),
            const SizedBox(height: 12),
            if (a.byChw.isEmpty)
              EmptyState(
                  icon: Icons.person_outline,
                  title: tr(ref, 'supervisor.noReferralData'),
                  subtitle: tr(ref, 'supervisor.noReferralsYet'))
            else
              ...a.byChw.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BreakdownCard(
                    title: c.chwName,
                    total: c.total,
                    arrived: c.arrived,
                    rate: c.completionRate,
                  ),
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
            error: e,
            onRetry: () => ref.invalidate(referralAnalyticsProvider)),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BreakdownCard extends ConsumerWidget {
  final String title;
  final int total;
  final int arrived;
  final double rate;
  const _BreakdownCard({
    required this.title,
    required this.total,
    required this.arrived,
    required this.rate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _metric('$total', tr(ref, 'supervisor.metricTotal')),
              const SizedBox(width: 20),
              _metric('$arrived', tr(ref, 'supervisor.metricArrived')),
              const SizedBox(width: 20),
              _metric('${rate.toStringAsFixed(1)}%', tr(ref, 'supervisor.metricCompletion')),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 6,
              backgroundColor: AppColors.success.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
    );
  }
}
