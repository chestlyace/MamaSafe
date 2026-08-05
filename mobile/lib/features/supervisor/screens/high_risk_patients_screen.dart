import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../supervisor_repository.dart';

class HighRiskPatientsScreen extends ConsumerWidget {
  const HighRiskPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(highRiskPatientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'supervisor.highRiskPatients')),
        automaticallyImplyLeading: false,
      ),
      body: patientsAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return EmptyState(
              icon: Icons.verified_user_outlined,
              title: tr(ref, 'supervisor.noHighRisk'),
              subtitle: tr(ref, 'supervisor.noHighRiskSubtitle'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: patients.length,
            itemBuilder: (context, i) {
              final p = patients[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.fullName,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (p.flagged)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(tr(ref, 'supervisor.flagged'),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (p.age != null)
                            tr(ref, 'supervisor.yrs', {'age': '${p.age}'}),
                          if (p.facility != null) p.facility!,
                          if (p.chwName != null)
                            tr(ref, 'supervisor.chwPrefix',
                                {'name': p.chwName!}),
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _chip(
                            tr(ref, 'supervisor.daysSinceAssessment',
                                {'days': '${p.daysSinceAssessment}'}),
                            p.flagged ? AppColors.error : AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            tr(ref, 'supervisor.confidence',
                                {'value': (p.confidence * 100).toStringAsFixed(0)}),
                            AppColors.primary,
                          ),
                        ],
                      ),
                      if (p.systolicBp != null || p.bloodSugar != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          [
                            if (p.systolicBp != null)
                              tr(ref, 'supervisor.bloodPressure',
                                  {'value': p.systolicBp!.toStringAsFixed(0)}),
                            if (p.bloodSugar != null)
                              tr(ref, 'supervisor.glucose',
                                  {'value': p.bloodSugar!.toStringAsFixed(1)}),
                          ].join(' · '),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                      if (!p.referralMade) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => context
                                .push('/pregnancies')
                                .then((_) => ref.invalidate(highRiskPatientsProvider)),
                            icon: const Icon(Icons.directions_walk_outlined,
                                size: 18),
                            label: Text(tr(ref, 'supervisor.refer')),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
            error: e,
            onRetry: () => ref.invalidate(highRiskPatientsProvider)),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
