import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/tr.dart';
import '../supervisor_repository.dart';

class SupervisorDashboardScreen extends ConsumerWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(supervisorDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'supervisor.title')),
        automaticallyImplyLeading: false,
      ),
      body: dashboardAsync.when(
        data: (d) => _buildContent(context, ref, d),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
            error: e,
            onRetry: () => ref.invalidate(supervisorDashboardProvider)),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AdminDashboardData d) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.district.isNotEmpty
                ? '${tr(ref, 'supervisor.overview')} — ${d.district}'
                : tr(ref, 'supervisor.overview'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(ref, 'supervisor.subtitle'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(title: tr(ref, 'supervisor.totalChws'), value: '${d.totalChws}', icon: Icons.people_outline, color: AppColors.primary),
              _StatCard(title: tr(ref, 'supervisor.activeToday'), value: '${d.activeChwsToday}', icon: Icons.check_circle_outline, color: AppColors.success),
              _StatCard(title: tr(ref, 'supervisor.totalPatients'), value: '${d.totalPatients}', icon: Icons.people_outline, color: AppColors.primary),
              _StatCard(title: tr(ref, 'supervisor.assessments'), value: '${d.totalAssessments}', icon: Icons.assignment_outlined, color: AppColors.primary),
              _StatCard(title: tr(ref, 'supervisor.deliveries'), value: '${d.totalDeliveries}', icon: Icons.child_friendly_outlined, color: AppColors.success),
              _StatCard(title: tr(ref, 'supervisor.referrals'), value: '${d.totalReferrals}', icon: Icons.directions_walk_outlined, color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(tr(ref, 'supervisor.riskDistribution')),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(title: tr(ref, 'supervisor.highRisk'), value: '${d.highRiskActive}', icon: Icons.warning_amber_rounded, color: AppColors.error),
              _StatCard(title: tr(ref, 'supervisor.midRisk'), value: '${d.midRiskActive}', icon: Icons.warning_amber_rounded, color: AppColors.warning),
              _StatCard(title: tr(ref, 'supervisor.lowRisk'), value: '${d.lowRiskActive}', icon: Icons.check_circle_outline, color: AppColors.success),
              _StatCard(title: tr(ref, 'supervisor.pendingEscalations'), value: '${d.pendingEscalations}', icon: Icons.notifications_active_outlined, color: AppColors.error),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(tr(ref, 'supervisor.thisWeek')),
          const SizedBox(height: 12),
          _WeekStatsTable(week: d.thisWeek, previous: d.lastWeek),
          const SizedBox(height: 24),
          _SectionTitle(tr(ref, 'supervisor.qualityIndicators')),
          _QualityRow(label: tr(ref, 'supervisor.referralCompletion'), value: d.referralCompletionRate, icon: Icons.directions_walk_outlined),
          _QualityRow(label: tr(ref, 'supervisor.pnc1Completion'), value: d.pnc1CompletionRate, icon: Icons.child_care_outlined),
          _QualityRow(label: tr(ref, 'supervisor.phq2PositiveMonth'), value: d.phq2PositiveThisMonth.toDouble(), icon: Icons.psychology_outlined, suffix: ''),
          _QualityRow(label: tr(ref, 'supervisor.growthAlertsActive'), value: d.growthAlertsActive.toDouble(), icon: Icons.trending_up, suffix: ''),
          const SizedBox(height: 24),
          _SectionTitle(tr(ref, 'supervisor.quickActions')),
          const SizedBox(height: 12),
          _QuickLink(label: tr(ref, 'supervisor.chwManagement'), icon: Icons.badge_outlined, onTap: () => context.push('/supervisor/chws')),
          _QuickLink(label: tr(ref, 'supervisor.facilities'), icon: Icons.local_hospital_outlined, onTap: () => context.push('/supervisor/facilities')),
          _QuickLink(label: tr(ref, 'supervisor.highRiskPatients'), icon: Icons.warning_amber_rounded, onTap: () => context.push('/supervisor/high-risk')),
          _QuickLink(label: tr(ref, 'supervisor.referralAnalytics'), icon: Icons.analytics_outlined, onTap: () => context.push('/supervisor/referrals')),
          _QuickLink(label: tr(ref, 'supervisor.reports'), icon: Icons.assessment_outlined, onTap: () => context.push('/supervisor/reports')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class _WeekStatsTable extends ConsumerWidget {
  final WeekStats week;
  final WeekStats previous;
  const _WeekStatsTable({required this.week, required this.previous});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = [
      (tr(ref, 'supervisor.assessments'), week.assessments, previous.assessments),
      (tr(ref, 'supervisor.referrals'), week.referrals, previous.referrals),
      (tr(ref, 'supervisor.deliveries'), week.deliveries, previous.deliveries),
      (tr(ref, 'supervisor.newPatients'), week.newPatients, previous.newPatients),
    ];
    return AppCard(
      child: Column(
        children: rows.map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(r.$1, style: const TextStyle(fontSize: 14))),
                Text('${r.$2}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(width: 8),
                Text(tr(ref, 'supervisor.prevWeek', {'count': '${r.$3}'}),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QualityRow extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final String suffix;
  const _QualityRow({
    required this.label,
    required this.value,
    required this.icon,
    this.suffix = '%',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            Text('${value.toStringAsFixed(1)}$suffix',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickLink({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
