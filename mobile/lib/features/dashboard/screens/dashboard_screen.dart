import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../assessment/assessment_repository.dart';
import '../../auth/auth_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final assessmentsAsync = ref.watch(assessmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MamaSafe'),
        automaticallyImplyLeading: false,
      ),
      body: assessmentsAsync.when(
        data: (assessments) {
          final highRisk = assessments.where((a) => a.riskLevel == 'high').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${authState.user?.name ?? 'CHW'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here\'s your overview',
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
                    _SummaryCard(
                      title: 'Total Assessments',
                      value: '${assessments.length}',
                      icon: Icons.assignment_turned_in_outlined,
                      color: AppColors.primary,
                    ),
                    _SummaryCard(
                      title: 'High Risk',
                      value: '$highRisk',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.accent,
                    ),
                    const _SummaryCard(
                      title: 'Pending Referrals',
                      value: '0',
                      icon: Icons.local_hospital_outlined,
                      color: AppColors.warning,
                    ),
                    _SummaryCard(
                      title: 'This Week',
                      value: '${assessments.length}',
                      icon: Icons.trending_up,
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.primary(
                        'New Assessment',
                        iconLeft: Icons.add_rounded,
                        onPressed: () => context.push('/assessments/new'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton.outline(
                        'View All',
                        iconLeft: Icons.list_rounded,
                        onPressed: () => context.push('/assessments'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent Assessments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
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
                                    a.patientRef ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${a.age.toStringAsFixed(0)} yrs',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _riskColor(a.riskLevel).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                a.riskLevel.toUpperCase(),
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
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(assessmentsProvider)),
      ),
    );
  }

  Color _riskColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return AppColors.accent;
      case 'mid':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
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
