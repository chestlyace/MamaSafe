import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/tr.dart';
import '../patient_repository.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key});

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _facilityController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _facilityController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = CreatePatientData(
      fullName: _fullNameController.text,
      dateOfBirth: _dateOfBirthController.text.isNotEmpty
          ? _dateOfBirthController.text
          : null,
      phone: _phoneController.text.isNotEmpty
          ? _phoneController.text
          : null,
      address: _addressController.text.isNotEmpty
          ? _addressController.text
          : null,
      facility: _facilityController.text.isNotEmpty
          ? _facilityController.text
          : null,
      bloodGroup: _bloodGroupController.text.isNotEmpty
          ? _bloodGroupController.text
          : null,
      allergies: _allergiesController.text.isNotEmpty
          ? _allergiesController.text
          : null,
      emergencyContactName: _emergencyContactNameController.text.isNotEmpty
          ? _emergencyContactNameController.text
          : null,
      emergencyContactPhone: _emergencyContactPhoneController.text.isNotEmpty
          ? _emergencyContactPhoneController.text
          : null,
    );

    try {
      await ref.read(createPatientProvider.notifier).create(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(ref, 'patients.created')),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
      ref.invalidate(patientsProvider);
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
    final createState = ref.watch(createPatientProvider);
    final isLoading = createState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'patients.new'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
AppTextField(
                  label: tr(ref, 'patients.fullName'),
                  help: tr(ref, 'patients.fullNameHelp'),
                  hint: tr(ref, 'patients.fullNameHint'),
                  controller: _fullNameController,
                  validator: (v) => v == null || v.isEmpty
                    ? tr(ref, 'patients.fullNameRequired')
                    : null,
               ),
              const SizedBox(height: 16),
AppTextField(
                  label: tr(ref, 'patients.dateOfBirthOptional'),
                  help: tr(ref, 'patients.dateOfBirthHelp'),
                  hint: tr(ref, 'patients.dateOfBirthHint'),
                  controller: _dateOfBirthController,
               ),
              const SizedBox(height: 16),
AppTextField(
                  label: tr(ref, 'patients.phoneOptional'),
                  help: tr(ref, 'patients.phoneHelp'),
                  hint: tr(ref, 'patients.phoneHint'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? null : phoneValidator(v, ref: ref),
               ),
              const SizedBox(height: 16),
AppTextField(
                  label: tr(ref, 'patients.addressOptional'),
                  help: tr(ref, 'patients.addressHelp'),
                  hint: tr(ref, 'patients.addressHint'),
                  controller: _addressController,
               ),
              const SizedBox(height: 16),
AppTextField(
                  label: tr(ref, 'patients.fullName'),
                  help: tr(ref, 'patients.fullNameHelp'),
                  hint: tr(ref, 'patients.fullNameHint'),
                  controller: _fullNameController,
                  validator: (v) => v == null || v.isEmpty
                    ? tr(ref, 'patients.fullNameRequired')
                    : null,
               ),
              const SizedBox(height: 16),
AppTextField(
                  label: tr(ref, 'patients.allergiesOptional'),
                  help: tr(ref, 'patients.allergiesHelp'),
                  hint: tr(ref, 'patients.allergiesHint'),
                  controller: _allergiesController,
                  maxLines: 2,
               ),
              const SizedBox(height: 16),
AppTextField(
                  label: tr(ref, 'patients.facilityOptional'),
                  help: tr(ref, 'patients.facilityHelp'),
                  hint: tr(ref, 'patients.facilityHint'),
                  controller: _facilityController,
               ),
              const SizedBox(height: 24),
              Text(
                tr(ref, 'patients.emergencyContact'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
AppTextField(
                  label: tr(ref, 'patients.emergencyNameOptional'),
                  help: tr(ref, 'patients.emergencyNameHelp'),
                  hint: tr(ref, 'patients.emergencyNameHint'),
                  controller: _emergencyContactNameController,
               ),
              const SizedBox(height: 16),
AppTextField(
                  label: tr(ref, 'patients.emergencyPhoneOptional'),
                  help: tr(ref, 'patients.emergencyPhoneHelp'),
                  hint: tr(ref, 'patients.emergencyPhoneHint'),
                  controller: _emergencyContactPhoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? null : phoneValidator(v, ref: ref),
               ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  tr(ref, 'patients.save'),
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
