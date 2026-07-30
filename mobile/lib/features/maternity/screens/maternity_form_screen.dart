import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../maternity_repository.dart';

class MaternityFormScreen extends ConsumerStatefulWidget {
  const MaternityFormScreen({super.key});

  @override
  ConsumerState<MaternityFormScreen> createState() => _MaternityFormScreenState();
}

class _MaternityFormScreenState extends ConsumerState<MaternityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _refController = TextEditingController();
  final _ageController = TextEditingController();
  final _gravidaController = TextEditingController();
  final _parityController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _lmp;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _refController.dispose();
    _ageController.dispose();
    _gravidaController.dispose();
    _parityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lmp ?? DateTime.now().subtract(const Duration(days: 84)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lmp = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final age = int.tryParse(_ageController.text);
    if (age == null) return;

    setState(() => _saving = true);

    final data = CreatePregnancyData(
      patientName: _nameController.text.trim(),
      patientRef: _refController.text.trim().isEmpty
          ? null
          : _refController.text.trim(),
      age: age,
      gravida: int.tryParse(_gravidaController.text),
      parity: int.tryParse(_parityController.text),
      lmp: _lmp != null
          ? '${_lmp!.year}-${_lmp!.month.toString().padLeft(2, '0')}-${_lmp!.day.toString().padLeft(2, '0')}'
          : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      await ref.read(createPregnancyProvider.notifier).create(data);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Pregnancy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Patient Name',
                hint: 'Full name',
                controller: _nameController,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Patient Reference',
                hint: 'Optional reference ID',
                controller: _refController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Age',
                hint: 'Patient age',
                controller: _ageController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 10 || n > 60) return 'Invalid age';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Gravida',
                      hint: '# pregnancies',
                      controller: _gravidaController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return 'Enter a valid number';
                        if (n > 20) return 'Gravida seems too high';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Parity',
                      hint: '# births',
                      controller: _parityController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return 'Enter a valid number';
                        if (n > 20) return 'Parity seems too high';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: AppTextField(
                    label: 'Last Menstrual Period',
                    hint: 'Tap to select date',
                    controller: TextEditingController(
                      text: _lmp != null
                          ? '${_lmp!.day}/${_lmp!.month}/${_lmp!.year}'
                          : '',
                    ),
                    suffix: const Icon(Icons.date_range,
                        size: 20, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Notes',
                hint: 'Additional notes',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                'Save',
                loading: _saving,
                onPressed: _save,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
