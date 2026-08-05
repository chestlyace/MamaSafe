import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_calc.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/date_field.dart';
import '../../../l10n/tr.dart';
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
  DateTime? _edd;
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
      lmp: _lmp != null ? formatDate(_lmp!) : null,
      edd: _edd != null ? formatDate(_edd!) : null,
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
          SnackBar(content: Text(tr(ref, 'maternity.saveFailed', {'error': '$e'}))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'maternity.new'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: tr(ref, 'maternity.patientName'),
                hint: tr(ref, 'maternity.patientNameHint'),
                controller: _nameController,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? tr(ref, 'maternity.required') : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'maternity.patientRef'),
                hint: tr(ref, 'maternity.patientRefHint'),
                controller: _refController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'maternity.age'),
                hint: tr(ref, 'maternity.ageHint'),
                controller: _ageController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return tr(ref, 'maternity.required');
                  final n = int.tryParse(v);
                  if (n == null || n < 10 || n > 60) return tr(ref, 'maternity.invalidAge');
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: tr(ref, 'maternity.gravida'),
                      hint: tr(ref, 'maternity.gravidaHint'),
                      controller: _gravidaController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return tr(ref, 'maternity.invalidNumber');
                        if (n > 20) return tr(ref, 'maternity.gravidaHigh');
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: tr(ref, 'maternity.parity'),
                      hint: tr(ref, 'maternity.parityHint'),
                      controller: _parityController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return tr(ref, 'maternity.invalidNumber');
                        if (n > 20) return tr(ref, 'maternity.parityHigh');
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
DateField(
                  label: tr(ref, 'maternity.lmp'),
                  help: tr(ref, 'maternity.lmpHelp'),
                  hint: tr(ref, 'anc.dateHint'),
                  value: _lmp,
                  onChanged: (dt) => setState(() => _lmp = dt),
                  lastDate: DateTime.now(),
                ),
              const SizedBox(height: 16),
DateField(
                  label: tr(ref, 'maternity.eddField'),
                  help: tr(ref, 'maternity.eddHelp'),
                  hint: tr(ref, 'anc.dateHint'),
                  value: _edd,
                  onChanged: (dt) => setState(() => _edd = dt),
                  computed: _lmp != null ? eddFromLmp(_lmp!) : null,
                  icon: Icons.event_available,
                ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'common.notes'),
                hint: tr(ref, 'maternity.notesHint'),
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                tr(ref, 'common.save'),
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
