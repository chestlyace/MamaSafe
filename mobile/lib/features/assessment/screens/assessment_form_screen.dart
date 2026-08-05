import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/tr.dart';
import '../../patients/patient_repository.dart';
import '../assessment_repository.dart';

class AssessmentFormScreen extends ConsumerStatefulWidget {
  const AssessmentFormScreen({super.key});

  @override
  ConsumerState<AssessmentFormScreen> createState() => _AssessmentFormScreenState();
}

class _AssessmentFormScreenState extends ConsumerState<AssessmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPatientId;
  final _ageController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _bloodSugarController = TextEditingController();
  final _bodyTempController = TextEditingController();
  final _heartRateController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _ageController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _bloodSugarController.dispose();
    _bodyTempController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  String? _patientValidator(String? value) {
    if (_selectedPatientId == null) return tr(ref, 'assessment.selectPatientRequired');
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(createAssessmentProvider.notifier);
      final assessment = await notifier.create(CreateAssessmentData(
        patientRef: _selectedPatientId,
        age: double.parse(_ageController.text),
        systolicBp: double.parse(_systolicController.text),
        diastolicBp: double.parse(_diastolicController.text),
        bloodSugar: double.parse(_bloodSugarController.text),
        bodyTemp: double.parse(_bodyTempController.text),
        heartRate: double.parse(_heartRateController.text),
      ));

      if (!mounted) return;

      final riskColor = _riskColor(assessment.riskLevel);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.assignment_turned_in, color: riskColor, size: 28),
              const SizedBox(width: 8),
              Text(tr(ref, 'assessment.complete')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _riskLabel(assessment.riskLevel),
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
                  Text(
                    tr(ref, 'assessment.riskScoreHigh', {'score': ((assessment.probHigh) * 100).toStringAsFixed(1)}),
                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                tr(ref, 'assessment.savedSubmitted'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/assessments/${assessment.id}');
              },
              child: Text(tr(ref, 'assessment.viewDetails')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/dashboard');
              },
              child: Text(tr(ref, 'common.done')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(ref, 'assessment.createFailed', {'error': '$e'})),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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

  String _riskLabel(String riskLevel) {
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
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'assessment.new'))),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(ref, 'assessment.patientInfo'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              AppCard(
                child: patientsAsync.when(
                  data: (patients) => DropdownButtonFormField<String>(
                    initialValue: _selectedPatientId,
                    decoration: InputDecoration(
                      labelText: tr(ref, 'assessment.selectPatient'),
                      prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                      border: const OutlineInputBorder(),
                    ),
                    items: patients.map((p) => DropdownMenuItem(
                      value: p.fullName,
                      child: Text('${p.fullName} (${p.phone ?? tr(ref, 'common.noPhone')})', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedPatientId = v),
                    validator: _patientValidator,
                  ),
                  loading: () => DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: tr(ref, 'assessment.loadingPatients'),
                      border: const OutlineInputBorder(),
                    ),
                    items: const [],
                    onChanged: null,
                  ),
                  error: (e, _) => Text(tr(ref, 'assessment.loadPatientsError', {'error': '$e'}), style: const TextStyle(color: AppColors.error)),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: tr(ref, 'assessment.ageYears'),
                  prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: ageValidator,
              ),
              const SizedBox(height: 16),
              Text(tr(ref, 'assessment.vitals'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _systolicController,
                            decoration: InputDecoration(
                              labelText: tr(ref, 'assessment.systolicBp'),
                              prefixIcon: const Icon(Icons.favorite, color: AppColors.accent, size: 20),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: bloodPressureValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _diastolicController,
                            decoration: InputDecoration(
                              labelText: tr(ref, 'assessment.diastolicBp'),
                              prefixIcon: const Icon(Icons.favorite_border, color: AppColors.accent, size: 20),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: bloodPressureValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bloodSugarController,
                      decoration: InputDecoration(
                        labelText: tr(ref, 'assessment.bloodSugarUnit'),
                        prefixIcon: const Icon(Icons.bloodtype, color: AppColors.primary, size: 20),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: bloodSugarValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bodyTempController,
                      decoration: InputDecoration(
                        labelText: tr(ref, 'assessment.bodyTempUnit'),
                        prefixIcon: const Icon(Icons.thermostat, color: AppColors.warning, size: 20),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: bodyTempValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _heartRateController,
                      decoration: InputDecoration(
                        labelText: tr(ref, 'assessment.heartRateUnit'),
                        prefixIcon: const Icon(Icons.monitor_heart, color: AppColors.accent, size: 20),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: heartRateValidator,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: AppButton.primary(
                  _isSubmitting ? tr(ref, 'assessment.submitting') : tr(ref, 'assessment.submit'),
                  iconLeft: Icons.check_circle,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
