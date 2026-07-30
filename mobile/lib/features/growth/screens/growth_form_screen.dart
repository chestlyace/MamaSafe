import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _recordedAt = picked);
    }
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
        const SnackBar(
          content: Text('Growth record saved'),
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
      appBar: AppBar(title: const Text('New Growth Record')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Child Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Child Name',
                hint: 'e.g. Baby John',
                controller: _childNameController,
                validator: (v) => v == null || v.isEmpty ? 'Child name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Child Reference (optional)',
                hint: 'e.g. MRN-67890',
                controller: _childRefController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Age (months)',
                hint: 'e.g. 24',
                controller: _ageMonthsController,
                keyboardType: TextInputType.number,
                validator: (v) => positiveNumberValidator(v, fieldName: 'Age'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Anthropometry',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Weight (kg)',
                hint: 'e.g. 12.5',
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    positiveNumberValidator(v, fieldName: 'Weight', allowDecimal: true),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Height (cm) optional',
                hint: 'e.g. 85',
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Head Circumference (cm) optional',
                hint: 'e.g. 48',
                controller: _headCircumferenceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'MUAC (cm) optional',
                hint: 'e.g. 14.5',
                controller: _muacController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _nutritionalStatus,
                decoration: const InputDecoration(
                  labelText: 'Nutritional Status (optional)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderate Malnutrition')),
                  DropdownMenuItem(value: 'severe', child: Text('Severe Malnutrition')),
                ],
                onChanged: (v) => setState(() => _nutritionalStatus = v),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _pickDate,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recorded At: ${_recordedAt.day}/${_recordedAt.month}/${_recordedAt.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  'Save Growth Record',
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
