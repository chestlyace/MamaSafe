import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../supervisor_repository.dart';

class ChwDetailScreen extends ConsumerWidget {
  final int chwId;
  const ChwDetailScreen({super.key, required this.chwId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(chwStatsProvider(chwId));

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'supervisor.chwDetails'))),
      body: statsAsync.when(
        data: (s) => _buildContent(context, ref, s),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
            error: e, onRetry: () => ref.invalidate(chwStatsProvider(chwId))),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ChwDetailStats s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(s.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                )),
        const SizedBox(height: 4),
        Text(s.facility ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                )),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('${s.patientCount}', tr(ref, 'supervisor.miniPatients')),
            _stat('${s.assessmentCount}', tr(ref, 'supervisor.assessments')),
            _stat('${s.referralCount}', tr(ref, 'supervisor.referrals')),
            _stat('${s.referralCompletionRate.toStringAsFixed(0)}%',
                tr(ref, 'supervisor.refRate')),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle(tr(ref, 'supervisor.riskDistribution')),
        const SizedBox(height: 8),
        _riskBars(ref, s),
        const SizedBox(height: 24),
        _SectionTitle(tr(ref, 'supervisor.ancCompletion')),
        const SizedBox(height: 8),
        _completionBars(ref, s.ancCompletion, 'visit_', 8),
        const SizedBox(height: 24),
        _SectionTitle(tr(ref, 'supervisor.pncCompletion')),
        const SizedBox(height: 8),
        _completionBars(ref, s.pncCompletion, 'pnc_', 3),
        const SizedBox(height: 24),
        _SectionTitle(tr(ref, 'supervisor.weeklyActivity')),
        const SizedBox(height: 8),
        _activityTable(ref, s),
        const SizedBox(height: 24),
        _SectionTitle(tr(ref, 'supervisor.patients')),
        const SizedBox(height: 8),
        if (s.patients.isEmpty)
          EmptyState(
              icon: Icons.people_outline,
              title: tr(ref, 'supervisor.noPatients'),
              subtitle: tr(ref, 'supervisor.noPatientsSubtitle')),
        ...s.patients.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(p.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  if (p.riskLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (p.riskLevel == 'high risk'
                                ? AppColors.error
                                : p.riskLevel == 'mid risk'
                                    ? AppColors.warning
                                    : AppColors.success)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _riskLabel(ref, p.riskLevel),
                        style: TextStyle(
                            fontSize: 11,
                            color: p.riskLevel == 'high risk'
                                ? AppColors.error
                                : p.riskLevel == 'mid risk'
                                    ? AppColors.warning
                                    : AppColors.success),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton.outline(
          tr(ref, 'supervisor.deactivateChw'),
          iconLeft: Icons.block_outlined,
          onPressed: () => _toggleActive(context, ref, s, false),
        ),
      ],
    );
  }

  Future<void> _toggleActive(
      BuildContext context, WidgetRef ref, ChwDetailStats s, bool activate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            activate ? tr(ref, 'supervisor.activateChw') : tr(ref, 'supervisor.deactivateChw')),
        content: Text(
            '${activate ? tr(ref, 'supervisor.activateChw') : tr(ref, 'supervisor.deactivateChw')} ${s.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(ref, 'common.cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr(ref, 'common.confirm'))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(supervisorRepositoryProvider);
      if (activate) {
        await repo.activateUser(s.chwId);
      } else {
        await repo.deactivateUser(s.chwId);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(activate
                ? tr(ref, 'supervisor.chwActivated')
                : tr(ref, 'supervisor.chwDeactivated'))),
      );
      ref.invalidate(chwStatsProvider(s.chwId));
      ref.invalidate(chwsProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'supervisor.actionFailed'))),
      );
    }
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      );

  Widget _riskBars(WidgetRef ref, ChwDetailStats s) {
    final items = [
      (s.riskDistribution['high'] ?? 0, AppColors.error, tr(ref, 'supervisor.highRisk')),
      (s.riskDistribution['mid'] ?? 0, AppColors.warning, tr(ref, 'supervisor.midRisk')),
      (s.riskDistribution['low'] ?? 0, AppColors.success, tr(ref, 'supervisor.lowRisk')),
    ];
    final max = items.map((e) => e.$1).fold<int>(1, (a, b) => a > b ? a : b);
    return AppCard(
      child: Column(
        children: items.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 48, child: Text(e.$3, style: const TextStyle(fontSize: 13))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.$1 / max,
                      minHeight: 8,
                      backgroundColor: e.$2.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(e.$2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.$1}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _completionBars(WidgetRef ref, Map<String, double> map,
      String prefix, int count) {
    final rows = <Widget>[];
    for (var i = 1; i <= count; i++) {
      final key = '$prefix$i';
      final value = map[key] ?? 0;
      final label = prefix == 'visit_'
          ? tr(ref, 'supervisor.visitLabel', {'number': '$i'})
          : tr(ref, 'supervisor.pncLabel', {'number': '$i'});
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
                width: 64,
                child:
                    Text(label, style: const TextStyle(fontSize: 12))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${value.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ));
    }
    return AppCard(child: Column(children: rows));
  }

  Widget _activityTable(WidgetRef ref, ChwDetailStats s) {
    return AppCard(
      child: Column(
        children: s.weeklyActivity.isEmpty
            ? [Text(tr(ref, 'supervisor.noWeeklyActivity'))]
            : s.weeklyActivity.map((w) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(w.week,
                              style: const TextStyle(fontSize: 13))),
                      Text(tr(ref, 'supervisor.assessmentsCount',
                          {'count': '${w.assessments}'}),
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Text(tr(ref, 'supervisor.referralsCount',
                          {'count': '${w.referrals}'}),
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }

  String _riskLabel(WidgetRef ref, String? riskLevel) {
    switch (riskLevel) {
      case 'high risk':
        return tr(ref, 'risk.high');
      case 'mid risk':
        return tr(ref, 'risk.mid');
      case 'low risk':
        return tr(ref, 'risk.low');
      default:
        return riskLevel ?? tr(ref, 'common.unknown');
    }
  }
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
