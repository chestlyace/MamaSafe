import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../referral_repository.dart';

class ReferralFormScreen extends ConsumerStatefulWidget {
  const ReferralFormScreen({super.key});

  @override
  ConsumerState<ReferralFormScreen> createState() => _ReferralFormScreenState();
}

class _ReferralFormScreenState extends ConsumerState<ReferralFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assessmentIdController = TextEditingController();
  final _patientRefController = TextEditingController();
  final _referredToController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _referralDate = DateTime.now();

  @override
  void dispose() {
    _assessmentIdController.dispose();
    _patientRefController.dispose();
    _referredToController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _referralDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _referralDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = CreateReferralData(
      assessmentId: int.parse(_assessmentIdController.text),
      patientRef: _patientRefController.text.isNotEmpty
          ? _patientRefController.text
          : null,
      referredTo: _referredToController.text,
      reason: _reasonController.text,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      referralDate: _referralDate,
    );

    try {
      await ref.read(createReferralProvider.notifier).create(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral created successfully'),
          backgroundColor: Colors.green,
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
    final createState = ref.watch(createReferralProvider);
    final isLoading = createState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('New Referral')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Assessment ID',
                hint: 'e.g. 12345',
                controller: _assessmentIdController,
                keyboardType: TextInputType.number,
                validator: (v) => numberValidator(v, fieldName: 'Assessment ID'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Patient Reference (optional)',
                hint: 'e.g. MRN-12345',
                controller: _patientRefController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Referred To',
                hint: 'e.g. Yaoundé Central Hospital',
                controller: _referredToController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Referred To is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Reason',
                hint: 'Reason for referral',
                controller: _reasonController,
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Reason is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Notes (optional)',
                hint: 'Additional notes',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    label: const Text('Referral Date'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_referralDate.day}/${_referralDate.month}/${_referralDate.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  'Create Referral',
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
