import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/storage/database.dart';
import '../assessment_repository.dart';

class AssessmentDetailScreen extends ConsumerWidget {
  final int assessmentId;

  const AssessmentDetailScreen({super.key, required this.assessmentId});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assessment Details')),
      body: assessmentsAsync.when(
        data: (assessments) {
          final assessment = assessments.where((a) => a.id == assessmentId).firstOrNull;
          if (assessment == null) {
            return const Center(child: Text('Assessment not found'));
          }
          return _buildContent(context, assessment);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(assessmentsProvider)),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Assessment assessment) {
    final riskColor = _riskColor(assessment.riskLevel);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Patient Reference'),
                _value(assessment.patientRef ?? 'Unknown'),
                const SizedBox(height: 12),
                _label('Age'),
                _value('${assessment.age.toStringAsFixed(0)} years'),
                const SizedBox(height: 12),
                _label('Assessment ID'),
                _value('#${assessment.id}'),
                const SizedBox(height: 12),
                _label('Date & Time'),
                _value(
                  '${assessment.createdAt.day}/${assessment.createdAt.month}/${assessment.createdAt.year} '
                  '${assessment.createdAt.hour.toString().padLeft(2, '0')}:'
                  '${assessment.createdAt.minute.toString().padLeft(2, '0')}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vital Signs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _vitalRow('Systolic BP', '${assessment.systolicBp.toStringAsFixed(0)} mmHg'),
                const Divider(height: 24),
                _vitalRow('Diastolic BP', '${assessment.diastolicBp.toStringAsFixed(0)} mmHg'),
                const Divider(height: 24),
                _vitalRow('Blood Sugar', '${assessment.bloodSugar.toStringAsFixed(0)} mg/dL'),
                const Divider(height: 24),
                _vitalRow('Body Temperature', '${assessment.bodyTemp.toStringAsFixed(1)} °C'),
                const Divider(height: 24),
                _vitalRow('Heart Rate', '${assessment.heartRate.toStringAsFixed(0)} bpm'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risk Assessment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        assessment.riskLevel.toUpperCase(),
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _probBar('Low Risk', assessment.probLow, AppColors.success),
                const SizedBox(height: 12),
                _probBar('Mid Risk', assessment.probMid, AppColors.warning),
                const SizedBox(height: 12),
                _probBar('High Risk', assessment.probHigh, AppColors.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _value(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  Widget _vitalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _probBar(String label, double probability, Color color) {
    final pct = (probability * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text('$pct%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: probability,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
