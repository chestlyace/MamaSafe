import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../assessment_repository.dart';

class AssessmentFormScreen extends ConsumerStatefulWidget {
  const AssessmentFormScreen({super.key});

  @override
  ConsumerState<AssessmentFormScreen> createState() =>
      _AssessmentFormScreenState();
}

class _AssessmentFormScreenState extends ConsumerState<AssessmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientRefController = TextEditingController();
  final _ageController = TextEditingController();
  final _systolicBpController = TextEditingController();
  final _diastolicBpController = TextEditingController();
  final _bloodSugarController = TextEditingController();
  final _bodyTempController = TextEditingController();
  final _heartRateController = TextEditingController();

  @override
  void dispose() {
    _patientRefController.dispose();
    _ageController.dispose();
    _systolicBpController.dispose();
    _diastolicBpController.dispose();
    _bloodSugarController.dispose();
    _bodyTempController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = CreateAssessmentData(
      patientRef: _patientRefController.text.isNotEmpty
          ? _patientRefController.text
          : null,
      age: double.parse(_ageController.text),
      systolicBp: double.parse(_systolicBpController.text),
      diastolicBp: double.parse(_diastolicBpController.text),
      bloodSugar: double.parse(_bloodSugarController.text),
      bodyTemp: double.parse(_bodyTempController.text),
      heartRate: double.parse(_heartRateController.text),
    );

    try {
      final assessment =
          await ref.read(createAssessmentProvider.notifier).create(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Risk Level: ${assessment.riskLevel.toUpperCase()}'),
          backgroundColor: assessment.riskLevel == 'high'
              ? Colors.red
              : assessment.riskLevel == 'mid'
                  ? Colors.orange
                  : Colors.green,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createAssessmentProvider);
    final isLoading = createState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('New Assessment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patient Reference',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Patient Reference (optional)',
                hint: 'e.g. MRN-12345',
                controller: _patientRefController,
              ),
              const SizedBox(height: 24),
              const Text(
                'Vital Signs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Age (years)',
                hint: 'e.g. 30',
                controller: _ageController,
                keyboardType: TextInputType.number,
                validator: (v) => positiveNumberValidator(v, fieldName: 'Age'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Systolic BP (mmHg)',
                hint: 'e.g. 120',
                controller: _systolicBpController,
                keyboardType: TextInputType.number,
                validator: (v) => bloodPressureValidator(v),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Diastolic BP (mmHg)',
                hint: 'e.g. 80',
                controller: _diastolicBpController,
                keyboardType: TextInputType.number,
                validator: (v) => bloodPressureValidator(v),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Blood Sugar (mg/dL)',
                hint: 'e.g. 100',
                controller: _bloodSugarController,
                keyboardType: TextInputType.number,
                validator: (v) => bloodSugarValidator(v),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Body Temperature (°C)',
                hint: 'e.g. 36.6',
                controller: _bodyTempController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => bodyTempValidator(v),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Heart Rate (bpm)',
                hint: 'e.g. 72',
                controller: _heartRateController,
                keyboardType: TextInputType.number,
                validator: (v) => heartRateValidator(v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  'Submit Assessment',
                  loading: isLoading,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
