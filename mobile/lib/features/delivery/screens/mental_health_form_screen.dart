import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/tr.dart';
import '../delivery_repository.dart';

class MentalHealthFormScreen extends ConsumerStatefulWidget {
  final int patientId;
  final int deliveryId;

  const MentalHealthFormScreen({
    super.key,
    required this.patientId,
    required this.deliveryId,
  });

  @override
  ConsumerState<MentalHealthFormScreen> createState() =>
      _MentalHealthFormScreenState();
}

class _MentalHealthFormScreenState
    extends ConsumerState<MentalHealthFormScreen> {
  int _score1 = 0;
  int _score2 = 0;
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _totalScore => _score1 + _score2;

  String get _riskLevel {
    if (_totalScore <= 2) return 'low';
    if (_totalScore <= 4) return 'moderate';
    return 'high';
  }

  Color get _riskColor {
    switch (_riskLevel) {
      case 'high':
        return AppColors.error;
      case 'moderate':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);

    final data = CreateMentalHealthData(
      patientId: widget.patientId,
      deliveryId: widget.deliveryId,
      phq2Score1: _score1,
      phq2Score2: _score2,
      totalScore: _totalScore,
      riskLevel: _riskLevel,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      await ref.read(createMentalHealthProvider.notifier).create(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${tr(ref, 'mentalhealth.saved')} - ${tr(ref, 'mentalhealth.totalScore')}: $_totalScore - ${tr(ref, 'mentalhealth.risk')}: ${tr(ref, 'risk.$_riskLevel')}',
          ),
          backgroundColor: _riskColor,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'mentalhealth.title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(ref, 'mentalhealth.intro'),
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(ref, 'mentalhealth.question1'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(ref, 'mentalhealth.phq2q1'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _score1,
                    decoration: InputDecoration(
                      label: Text(tr(ref, 'mentalhealth.score')),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 0, child: Text(tr(ref, 'mentalhealth.option0'))),
                      DropdownMenuItem(value: 1, child: Text(tr(ref, 'mentalhealth.option1'))),
                      DropdownMenuItem(value: 2, child: Text(tr(ref, 'mentalhealth.option2'))),
                      DropdownMenuItem(value: 3, child: Text(tr(ref, 'mentalhealth.option3'))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _score1 = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(ref, 'mentalhealth.question2'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(ref, 'mentalhealth.phq2q2'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _score2,
                    decoration: InputDecoration(
                      label: Text(tr(ref, 'mentalhealth.score')),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 0, child: Text(tr(ref, 'mentalhealth.option0'))),
                      DropdownMenuItem(value: 1, child: Text(tr(ref, 'mentalhealth.option1'))),
                      DropdownMenuItem(value: 2, child: Text(tr(ref, 'mentalhealth.option2'))),
                      DropdownMenuItem(value: 3, child: Text(tr(ref, 'mentalhealth.option3'))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _score2 = v);
                    },
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
                    tr(ref, 'mentalhealth.resultsSummary'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _resultRow(tr(ref, 'mentalhealth.q1Score'), _score1.toString()),
                  const Divider(height: 20),
                  _resultRow(tr(ref, 'mentalhealth.q2Score'), _score2.toString()),
                  const Divider(height: 20),
                  _resultRow(tr(ref, 'mentalhealth.totalScore'), _totalScore.toString()),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr(ref, 'mentalhealth.risk'),
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _riskColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tr(ref, 'risk.$_riskLevel'),
                          style: TextStyle(
                            color: _riskColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: tr(ref, 'mentalhealth.notes'),
              hint: tr(ref, 'mentalhealth.notesHint'),
              controller: _notesController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                tr(ref, 'mentalhealth.submit'),
                loading: _saving,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
