import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/shap_decoration.dart';
import '../../../l10n/tr.dart';
import '../../referrals/referral_repository.dart';
import '../assessment_repository.dart';
class AssessmentDetailScreen extends ConsumerWidget {
  final int assessmentId;

  const AssessmentDetailScreen({super.key, required this.assessmentId});

  Color _riskColor(String? riskLevel) {
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

  String _riskLabel(WidgetRef ref, String? riskLevel) {
    switch (riskLevel) {
      case 'high':
        return tr(ref, 'risk.high');
      case 'mid':
        return tr(ref, 'risk.mid');
      case 'low':
        return tr(ref, 'risk.low');
      default:
        return tr(ref, 'common.unknown');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentsProvider);
    final referralsAsync = ref.watch(referralsProvider);

    return assessmentsAsync.when(
      data: (assessments) {
        final assessment = assessments.where((a) => a.id == assessmentId).firstOrNull;
        if (assessment == null) {
          return Scaffold(
            appBar: AppBar(title: Text(tr(ref, 'assessment.title'))),
            body: Center(child: Text(tr(ref, 'assessment.notFound'), style: const TextStyle(color: AppColors.textSecondary))),
          );
        }

        final patientName = assessment.patientRef ?? tr(ref, 'common.unknown');
        final riskColor = _riskColor(assessment.riskLevel);
        final existingReferral = referralsAsync.valueOrNull?.where((r) => r.patientRef == assessment.patientRef).firstOrNull;

        return Scaffold(
          appBar: AppBar(title: Text(tr(ref, 'assessment.titleWithId', {'id': '${assessment.id}'}))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  variant: AppCardVariant.elevated,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.15), child: const Icon(Icons.person, color: AppColors.primary)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(patientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                Text(tr(ref, 'assessment.ageYrs', {'age': assessment.age.toStringAsFixed(0)}), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _riskLabel(ref, assessment.riskLevel),
                              style: TextStyle(color: riskColor, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(tr(ref, 'assessment.vitals'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: [
                      _VitalRow(label: tr(ref, 'assessment.bloodPressure'), value: '${assessment.systolicBp.toStringAsFixed(0)}/${assessment.diastolicBp.toStringAsFixed(0)}', icon: Icons.favorite),
                      const Divider(height: 20),
                      _VitalRow(label: tr(ref, 'assessment.heartRate'), value: '${assessment.heartRate.toStringAsFixed(0)} bpm', icon: Icons.monitor_heart),
                      const Divider(height: 20),
                      _VitalRow(label: tr(ref, 'assessment.temperature'), value: '${assessment.bodyTemp.toStringAsFixed(1)}°C', icon: Icons.thermostat),
                      const Divider(height: 20),
                      _VitalRow(label: tr(ref, 'assessment.bloodSugar'), value: '${assessment.bloodSugar.toStringAsFixed(0)} mg/dL', icon: Icons.bloodtype),
                      const Divider(height: 20),
                      _VitalRow(label: tr(ref, 'assessment.age'), value: '${assessment.age.toStringAsFixed(0)} yrs', icon: Icons.calendar_today),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(tr(ref, 'assessment.riskAssessment'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ShapDecoration(
                  color: riskColor,
                  strokeWidth: 2.0,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: riskColor, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          tr(ref, 'assessment.riskBanner', {'level': _riskLabel(ref, assessment.riskLevel)}).toUpperCase(),
                          style: TextStyle(
                            color: riskColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr(ref, 'assessment.riskProbabilities', {
                            'high': (assessment.probHigh * 100).toStringAsFixed(0),
                            'mid': (assessment.probMid * 100).toStringAsFixed(0),
                            'low': (assessment.probLow * 100).toStringAsFixed(0),
                          }),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(tr(ref, 'assessment.recommendation'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                AppCard(
                  child: Text(
                    assessment.recommendation ?? tr(ref, 'assessment.noRecommendation'),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Text(tr(ref, 'assessment.actions'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (existingReferral == null)
                      Expanded(
                        child: AppButton.primary(
                          tr(ref, 'assessment.createReferral'),
                          iconLeft: Icons.local_hospital,
                          onPressed: () => context.push('/home/referrals/new'),
                        ),
                      )
                    else
                      Expanded(
                        child: AppButton.outline(
                          tr(ref, 'assessment.viewReferrals'),
                          iconLeft: Icons.local_hospital,
                          onPressed: () => context.push('/home/referrals/${existingReferral.id}'),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton.outline(
                        tr(ref, 'common.edit'),
                        iconLeft: Icons.edit,
                        onPressed: () => context.push('/assessments/${assessment.id}/edit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(tr(ref, 'assessment.title'))),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(assessmentsProvider)),
    );
  }

}

class _VitalRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _VitalRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
