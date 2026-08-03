import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/storage/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../../assessment/assessment_repository.dart';
import '../../auth/auth_repository.dart';
import '../../auth/user.dart';
import '../../maternity/maternity_repository.dart';
import '../../patients/patient_repository.dart';
import '../../referrals/referral_repository.dart';
import '../dashboard_repository.dart';
import '../widgets/risk_donut_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Color _riskColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return AppColors.error;
      case 'mid':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _riskLabel(WidgetRef ref, String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return tr(ref, 'risk.high');
      case 'mid':
        return tr(ref, 'risk.mid');
      case 'low':
        return tr(ref, 'risk.low');
      default:
        return riskLevel.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final assessmentsAsync = ref.watch(assessmentsProvider);
    final patientsAsync = ref.watch(patientsProvider);
    final pregnanciesAsync = ref.watch(pregnanciesProvider);
    final referralsAsync = ref.watch(referralsProvider);
    final summaryAsync = ref.watch(homeDashboardProvider);
    final escalationsAsync = ref.watch(recentEscalationsProvider);

    final isSupervisor = authState.user?.role == UserRole.supervisor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MamaSafe'),
        automaticallyImplyLeading: false,
      ),
      body: assessmentsAsync.when(
        data: (assessments) => _buildContent(
          context, ref, authState, assessments, patientsAsync, pregnanciesAsync, referralsAsync, isSupervisor, summaryAsync, escalationsAsync,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(assessmentsProvider)),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
    List<Assessment> assessments,
    AsyncValue<List<Patient>> patientsAsync,
    AsyncValue<List<Pregnancy>> pregnanciesAsync,
    AsyncValue<List<Referral>> referralsAsync,
    bool isSupervisor,
    AsyncValue<DashboardSummaryData> summaryAsync,
    AsyncValue<List<EscalationFeedItem>> escalationsAsync,
  ) {
    final patientsCount = patientsAsync.valueOrNull?.length ?? 0;
    final activePregnancies = pregnanciesAsync.valueOrNull?.where((p) => p.status == 'active').length ?? 0;
    final pendingReferrals = referralsAsync.valueOrNull?.where((r) => r.status == 'pending').length ?? 0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(assessmentsProvider);
        ref.invalidate(patientsProvider);
        ref.invalidate(pregnanciesProvider);
        ref.invalidate(referralsProvider);
        ref.invalidate(homeDashboardProvider);
        ref.invalidate(recentEscalationsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(ref, 'dashboard.welcome', {'name': authState.user?.name ?? 'CHW'}),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              tr(ref, 'dashboard.overviewSubtitle'),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _StatCard(
                  title: tr(ref, 'dashboard.assessments'),
                  value: '${assessments.length}',
                  icon: Icons.assignment,
                  color: AppColors.primary,
                  flex: 1,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  title: tr(ref, 'dashboard.patients'),
                  value: '$patientsCount',
                  icon: Icons.people,
                  color: AppColors.accent,
                  flex: 1,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  title: tr(ref, 'dashboard.activePregnancies'),
                  value: '$activePregnancies',
                  icon: Icons.pregnant_woman,
                  color: AppColors.warning,
                  flex: 1,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              tr(ref, 'dashboard.programOverview'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              data: (s) => _OverviewSection(summary: s),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _OverviewSection(
                summary: DashboardSummaryRepository.buildLocalSummary(
                  assessments: 0, highRisk: 0, midRisk: 0, lowRisk: 0,
                  patients: 0, activePregnancies: 0, pendingReferrals: 0,
                  upcomingVisits: 0, recentEscalations: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr(ref, 'dashboard.riskDistribution'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              data: (s) => RiskDonutChart(
                highRisk: s.highRiskCount,
                midRisk: s.midRiskCount,
                lowRisk: s.lowRiskCount,
                totalAssessments: s.totalAssessments,
              ),
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const SizedBox(height: 180),
            ),
            const SizedBox(height: 24),
            Text(
              tr(ref, 'dashboard.escalations'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _EscalationFeed(escalationsAsync: escalationsAsync),
            const SizedBox(height: 24),
            Text(
              tr(ref, 'dashboard.quickActions'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _QuickActionsGrid(isSupervisor: isSupervisor),
            const SizedBox(height: 24),
            Text(
              tr(ref, 'dashboard.recentActivity'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ...assessments.take(5).map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () => context.push('/assessments/${a.id}'),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.patientRef ?? tr(ref, 'common.unknown'),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${a.age.toStringAsFixed(0)} ${tr(ref, 'common.yearsShort')} \u2022 ${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _riskColor(a.riskLevel).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _riskLabel(ref, a.riskLevel),
                            style: TextStyle(
                              color: _riskColor(a.riskLevel),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton.outline(
                tr(ref, 'dashboard.viewAllAssessments'),
                iconLeft: Icons.arrow_forward,
                onPressed: () => context.push('/assessments'),
              ),
            ),
            if (isSupervisor) ...[
              const SizedBox(height: 24),
              Text(
                tr(ref, 'dashboard.supervisorTools'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      tr(ref, 'dashboard.approvalsCount', {'count': '$pendingReferrals'}),
                      iconLeft: Icons.checklist,
                      onPressed: () => context.push('/home/approvals'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.outline(
                      tr(ref, 'report.title'),
                      iconLeft: Icons.bar_chart,
                      onPressed: () => context.push('/supervisor/reports'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int flex;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends ConsumerWidget {
  final bool isSupervisor;

  const _QuickActionsGrid({required this.isSupervisor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _ActionItem(tr(ref, 'dashboard.newAssessment'), Icons.assignment, AppColors.primary, () => context.push('/assessments/new')),
      _ActionItem(tr(ref, 'dashboard.addPatient'), Icons.person_add, AppColors.accent, () => context.push('/home/patients/new')),
      _ActionItem(tr(ref, 'dashboard.registerPregnancy'), Icons.pregnant_woman, AppColors.warning, () => context.push('/home/pregnancies/new')),
      _ActionItem(tr(ref, 'dashboard.recordDelivery'), Icons.baby_changing_station, AppColors.primaryLight, () => context.push('/home/patients')),
      _ActionItem(tr(ref, 'dashboard.growthTracking'), Icons.show_chart, AppColors.success, () => context.push('/home/growth')),
      _ActionItem(tr(ref, 'dashboard.referrals'), Icons.local_hospital, AppColors.primary, () => context.push('/home/referrals')),
    ];

    final supervisorActions = [
      _ActionItem(tr(ref, 'approval.title'), Icons.checklist, AppColors.warning, () => context.push('/home/approvals')),
      _ActionItem(tr(ref, 'report.title'), Icons.bar_chart, AppColors.primary, () => context.push('/supervisor/reports')),
      _ActionItem(tr(ref, 'dashboard.escalations'), Icons.emergency, AppColors.error, () => context.push('/home/escalations')),
    ];

    final allActions = isSupervisor ? [...actions, ...supervisorActions] : actions;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: allActions.length,
      itemBuilder: (_, i) {
        final a = allActions[i];
        return AppCard(
          onTap: a.onTap,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(a.icon, color: a.color, size: 28),
              const SizedBox(height: 6),
              Text(
                a.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem(this.label, this.icon, this.color, this.onTap);
}

class _OverviewSection extends ConsumerWidget {
  final DashboardSummaryData summary;
  const _OverviewSection({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = [
      (label: tr(ref, 'dashboard.patients'), value: summary.totalPatients, icon: Icons.people_outline, color: AppColors.primary),
      (label: tr(ref, 'dashboard.assessments'), value: summary.totalAssessments, icon: Icons.assignment_outlined, color: AppColors.primary),
      (label: tr(ref, 'dashboard.activePregnancies'), value: summary.activePregnancies, icon: Icons.pregnant_woman, color: AppColors.success),
      (label: tr(ref, 'dashboard.pendingReferrals'), value: summary.pendingReferrals, icon: Icons.directions_walk_outlined, color: AppColors.warning),
      (label: tr(ref, 'dashboard.upcomingVisits'), value: summary.upcomingVisits, icon: Icons.event_outlined, color: AppColors.primary),
      (label: tr(ref, 'dashboard.escalations'), value: summary.recentEscalations, icon: Icons.notifications_active_outlined, color: AppColors.error),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards
          .map((c) => AppCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c.icon, color: c.color, size: 24),
                    const SizedBox(height: 8),
                    Text('${c.value}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(c.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _EscalationFeed extends ConsumerWidget {
  final AsyncValue<List<EscalationFeedItem>> escalationsAsync;
  const _EscalationFeed({required this.escalationsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return escalationsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.notifications_none,
            title: tr(ref, 'dashboard.noRecentEscalations'),
            subtitle: tr(ref, 'dashboard.noRecentEscalationsSubtitle'),
          );
        }
        return Column(
          children: items.take(5).map((e) {
            final escalatedTo = e.to?.replaceAll(' risk', '') ?? 'high';
            final color = escalatedTo == 'high' ? AppColors.error : AppColors.warning;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.arrow_upward,
                          color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.patientName ?? tr(ref, 'common.unknownPatient'),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(
                            '${e.from ?? 'risk'}\u2192${e.to ?? 'risk'}  ${e.date ?? ''}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (e.whatsappSent)
                      const Icon(Icons.check_circle,
                          size: 16, color: AppColors.success),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(tr(ref, 'dashboard.couldNotLoadEscalations'),
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}
