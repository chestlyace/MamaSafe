import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/date_field.dart';
import '../../../l10n/tr.dart';
import '../growth_repository.dart';

class GrowthFormScreen extends ConsumerStatefulWidget {
  const GrowthFormScreen({super.key});

  @override
  ConsumerState<GrowthFormScreen> createState() => _GrowthFormScreenState();
}

class _GrowthFormScreenState extends ConsumerState<GrowthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childNameController = TextEditingController();
  final _childRefController = TextEditingController();
  final _ageMonthsController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _headCircumferenceController = TextEditingController();
  final _muacController = TextEditingController();
  DateTime _recordedAt = DateTime.now();
  String? _nutritionalStatus;

  @override
  void dispose() {
    _childNameController.dispose();
    _childRefController.dispose();
    _ageMonthsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _headCircumferenceController.dispose();
    _muacController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = CreateGrowthRecordData(
      childName: _childNameController.text,
      childRef: _childRefController.text.isNotEmpty
          ? _childRefController.text
          : null,
      ageMonths: int.parse(_ageMonthsController.text),
      weight: double.parse(_weightController.text),
      height: _heightController.text.isNotEmpty
          ? double.parse(_heightController.text)
          : null,
      headCircumference: _headCircumferenceController.text.isNotEmpty
          ? double.parse(_headCircumferenceController.text)
          : null,
      muac: _muacController.text.isNotEmpty
          ? double.parse(_muacController.text)
          : null,
      nutritionalStatus: _nutritionalStatus,
      recordedAt: _recordedAt,
    );

    try {
      await ref.read(createGrowthRecordProvider.notifier).create(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(ref, 'growth.saved')),
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
    final createState = ref.watch(createGrowthRecordProvider);
    final isLoading = createState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'growth.new'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(ref, 'growth.childInfo'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
AppTextField(
                 label: tr(ref, 'growth.childName'),
                 help: tr(ref, 'growth.childNameHelp'),
                 hint: tr(ref, 'growth.childNameHint'),
                 controller: _childNameController,
                 validator: (v) => v == null || v.isEmpty ? tr(ref, 'growth.childNameRequired') : null,
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'growth.childRefOptional'),
                 help: tr(ref, 'growth.childRefHelp'),
                 hint: tr(ref, 'growth.childRefHint'),
                 controller: _childRefController,
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'growth.ageMonths'),
                 help: tr(ref, 'growth.ageMonthsHelp'),
                 hint: tr(ref, 'growth.ageMonthsHint'),
                 controller: _ageMonthsController,
                 keyboardType: TextInputType.number,
                 validator: (v) => positiveNumberValidator(v, fieldName: tr(ref, 'growth.ageMonths'), ref: ref),
               ),
               const SizedBox(height: 24),
               Text(
                 tr(ref, 'growth.anthropometry'),
                 style: const TextStyle(
                   fontSize: 18,
                   fontWeight: FontWeight.w700,
                 ),
               ),
               const SizedBox(height: 12),
               AppTextField(
                 label: tr(ref, 'growth.weightKg'),
                 help: tr(ref, 'growth.weightHelp'),
                 hint: tr(ref, 'growth.weightHint'),
                 controller: _weightController,
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 validator: (v) =>
                     positiveNumberValidator(v, fieldName: tr(ref, 'growth.weight'), allowDecimal: true, ref: ref),
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'growth.heightOptional'),
                 help: tr(ref, 'growth.heightHelp'),
                 hint: tr(ref, 'growth.heightHint'),
                 controller: _heightController,
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'growth.headCircumferenceOptional'),
                 help: tr(ref, 'growth.headCircumferenceHelp'),
                 hint: tr(ref, 'growth.headCircumferenceHint'),
                 controller: _headCircumferenceController,
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'growth.muacOptional'),
                 help: tr(ref, 'growth.muacHelp'),
                 hint: tr(ref, 'growth.muacHint'),
                 controller: _muacController,
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
               ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _nutritionalStatus,
                decoration: InputDecoration(
                  labelText: tr(ref, 'growth.nutritionalStatusOptional'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'normal', child: Text(tr(ref, 'growth.normal'))),
                  DropdownMenuItem(value: 'moderate', child: Text(tr(ref, 'growth.moderateMalnutrition'))),
                  DropdownMenuItem(value: 'severe', child: Text(tr(ref, 'growth.severeMalnutrition'))),
                ],
                onChanged: (v) => setState(() => _nutritionalStatus = v),
              ),
              const SizedBox(height: 24),
              DateField(
                label: tr(ref, 'growth.recordedAtLabel'),
                hint: tr(ref, 'growth.recordedAtHint'),
                value: _recordedAt,
                onChanged: (dt) => setState(() {
                  if (dt != null) _recordedAt = dt;
                }),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  tr(ref, 'growth.save'),
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
