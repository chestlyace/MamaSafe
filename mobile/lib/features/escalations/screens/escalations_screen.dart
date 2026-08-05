import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../escalation_repository.dart';

Color _riskColor(String level) {
  switch (level) {
    case 'high':
      return AppColors.error;
    case 'mid':
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}

String _riskLabel(WidgetRef ref, String level) {
  switch (level) {
    case 'high':
      return tr(ref, 'risk.high');
    case 'mid':
      return tr(ref, 'risk.mid');
    case 'low':
      return tr(ref, 'risk.low');
    default:
      return level.toUpperCase();
  }
}

Color _severityColor(String severity) {
  switch (severity) {
    case 'critical':
      return AppColors.error;
    case 'warning':
      return AppColors.warning;
    default:
      return AppColors.primary;
  }
}

String _severityLabel(WidgetRef ref, String severity) {
  switch (severity) {
    case 'critical':
      return tr(ref, 'escalation.severityCritical');
    case 'warning':
      return tr(ref, 'escalation.severityWarning');
    default:
      return severity.toUpperCase();
  }
}

class EscalationsScreen extends ConsumerWidget {
  const EscalationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(ref, 'escalation.title')),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: tr(ref, 'escalation.riskTab')),
              Tab(text: tr(ref, 'escalation.growthTab')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RiskEscalationsTab(),
            _GrowthAlertsTab(),
          ],
        ),
      ),
    );
  }
}

class _RiskEscalationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escalationsAsync = ref.watch(unacknowledgedEscalationsProvider);

    return escalationsAsync.when(
      data: (escalations) {
        if (escalations.isEmpty) {
          return EmptyState(
            icon: Icons.check_circle_outline,
            title: tr(ref, 'escalation.noEscalations'),
            subtitle: tr(ref, 'escalation.noEscalationsSubtitle'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: escalations.length,
          itemBuilder: (context, index) {
            final e = escalations[index];
            final riskColor = _riskColor(e.riskLevel);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => context.push('/escalations/${e.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.patientRef ??
                                tr(ref, 'escalation.patientNumber',
                                    {'id': '${e.patientId}'}),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _riskLabel(ref, e.riskLevel),
                            style: TextStyle(
                              color: riskColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (e.confidenceScore != null)
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            tr(ref, 'escalation.confidence',
                                {'value': '${(e.confidenceScore! * 100).toStringAsFixed(0)}%'}),
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          try {
                            await ref.read(acknowledgeEscalationProvider)(e.id);
                            ref.invalidate(unacknowledgedEscalationsProvider);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(tr(ref, 'escalation.acknowledgedSnack')),
                                  backgroundColor: AppColors.success),
                            );
                          } catch (err) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(tr(ref, 'escalation.failed', {'error': '$err'})),
                                  backgroundColor: AppColors.error),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(tr(ref, 'escalation.acknowledge')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(unacknowledgedEscalationsProvider)),
    );
  }
}

class _GrowthAlertsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(unresolvedAlertsProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return EmptyState(
            icon: Icons.check_circle_outline,
            title: tr(ref, 'escalation.noGrowthAlerts'),
            subtitle: tr(ref, 'escalation.noGrowthAlertsSubtitle'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final a = alerts[index];
            final sevColor = _severityColor(a.severity);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sevColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            a.alertType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: sevColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sevColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _severityLabel(ref, a.severity),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: sevColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.message,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          try {
                            await ref.read(resolveAlertProvider)(a.id);
                            ref.invalidate(unresolvedAlertsProvider);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(tr(ref, 'escalation.resolvedSnack')),
                                  backgroundColor: AppColors.success),
                            );
                          } catch (err) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(tr(ref, 'escalation.failed', {'error': '$err'})),
                                  backgroundColor: AppColors.error),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(tr(ref, 'escalation.resolve')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(unresolvedAlertsProvider)),
    );
  }
}
