import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
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

class EscalationDetailScreen extends ConsumerWidget {
  final int escalationId;

  const EscalationDetailScreen({super.key, required this.escalationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escalationsAsync = ref.watch(escalationsProvider);

    return escalationsAsync.when(
      data: (escalations) {
        final escalation = escalations.where((e) => e.id == escalationId).firstOrNull;
        if (escalation == null) {
          return Scaffold(
            appBar: AppBar(title: Text(tr(ref, 'escalation.detailsTitle'))),
            body: Center(child: Text(tr(ref, 'escalation.notFound'))),
          );
        }

        final riskColor = _riskColor(escalation.riskLevel);

        return Scaffold(
          appBar: AppBar(title: Text(tr(ref, 'escalation.detailsTitle'))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              escalation.patientRef ??
                                  tr(ref, 'escalation.patientNumber',
                                      {'id': '${escalation.patientId}'}),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _riskLabel(ref, escalation.riskLevel),
                              style: TextStyle(
                                color: riskColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _infoRow(ref, tr(ref, 'escalation.assessmentId'),
                          escalation.assessmentId.toString()),
                      if (escalation.confidenceScore != null)
                        _infoRow(
                          ref,
                          tr(ref, 'escalation.confidenceLabel'),
                          '${(escalation.confidenceScore! * 100).toStringAsFixed(1)}%',
                        ),
                      _infoRow(
                        ref,
                        tr(ref, 'common.date'),
                        '${escalation.createdAt.day}/${escalation.createdAt.month}/${escalation.createdAt.year}',
                      ),
                      _infoRow(
                        ref,
                        tr(ref, 'escalation.acknowledgedLabel'),
                        escalation.acknowledged
                            ? tr(ref, 'common.yes')
                            : tr(ref, 'common.no'),
                      ),
                      if (escalation.acknowledgedAt != null)
                        _infoRow(
                          ref,
                          tr(ref, 'escalation.acknowledgedAt'),
                          '${escalation.acknowledgedAt!.day}/${escalation.acknowledgedAt!.month}/${escalation.acknowledgedAt!.year}',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(ref, 'escalation.messageLabel'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        escalation.message,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        tr(ref, 'escalation.viewAssessment'),
                        iconLeft: Icons.assignment_outlined,
                        onPressed: () => context.push('/assessments/${escalation.assessmentId}'),
                      ),
                    ),
                  ],
                ),
                if (!escalation.acknowledged) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      tr(ref, 'escalation.acknowledgeEscalation'),
                      iconLeft: Icons.check_circle_outline,
                      onPressed: () async {
                        try {
                          await ref.read(acknowledgeEscalationProvider)(escalation.id);
                          ref.invalidate(escalationsProvider);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(tr(ref, 'escalation.acknowledgedSnack')),
                                backgroundColor: AppColors.success),
                          );
                          context.pop();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(tr(ref, 'escalation.failed', {'error': '$e'})),
                                backgroundColor: AppColors.error),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
        loading: () => Scaffold(
        appBar: AppBar(title: Text(tr(ref, 'escalation.detailsTitle'))),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(tr(ref, 'escalation.detailsTitle'))),
        body: AppErrorWidget(error: e, onRetry: () => ref.invalidate(escalationsProvider)),
      ),
    );
  }

  Widget _infoRow(WidgetRef ref, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
