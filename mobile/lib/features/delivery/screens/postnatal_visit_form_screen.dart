import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_calc.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/date_field.dart';
import '../../../l10n/tr.dart';
import '../delivery_repository.dart';

class PostnatalVisitFormScreen extends ConsumerStatefulWidget {
  final int deliveryId;
  final int? newbornId;

  const PostnatalVisitFormScreen({
    super.key,
    required this.deliveryId,
    this.newbornId,
  });

  @override
  ConsumerState<PostnatalVisitFormScreen> createState() =>
      _PostnatalVisitFormScreenState();
}

class _PostnatalVisitFormScreenState
    extends ConsumerState<PostnatalVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _visitNumberController = TextEditingController();
  final _motherStatusController = TextEditingController();
  final _newbornWeightController = TextEditingController();
  final _breastfeedingStatusController = TextEditingController();
  final _muacController = TextEditingController();
  final _physicalExamController = TextEditingController();
  final _labsController = TextEditingController();
  final _mentalHealthNotesController = TextEditingController();
  DateTime? _visitDate;

  @override
  void dispose() {
    _visitNumberController.dispose();
    _motherStatusController.dispose();
    _newbornWeightController.dispose();
    _breastfeedingStatusController.dispose();
    _muacController.dispose();
    _physicalExamController.dispose();
    _labsController.dispose();
    _mentalHealthNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final visitNumber = int.tryParse(_visitNumberController.text);
    if (visitNumber == null) return;

    final visitDate = _visitDate;
    if (visitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(ref, 'postnatal.visitDateRequired')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = CreatePostnatalVisitData(
      deliveryId: widget.deliveryId,
      newbornId: widget.newbornId,
      visitDate: visitDate,
      visitNumber: visitNumber,
      motherStatus: _motherStatusController.text.trim().isEmpty
          ? null
          : _motherStatusController.text.trim(),
      newbornWeight: double.tryParse(_newbornWeightController.text),
      breastfeedingStatus: _breastfeedingStatusController.text.trim().isEmpty
          ? null
          : _breastfeedingStatusController.text.trim(),
      muac: double.tryParse(_muacController.text),
      physicalExam: _physicalExamController.text.trim().isEmpty
          ? null
          : _physicalExamController.text.trim(),
      labs: _labsController.text.trim().isEmpty
          ? null
          : _labsController.text.trim(),
      mentalHealthNotes: _mentalHealthNotesController.text.trim().isEmpty
          ? null
          : _mentalHealthNotesController.text.trim(),
    );

    try {
      await ref.read(createPostnatalVisitProvider.notifier).create(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(ref, 'postnatal.saved')),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(ref, 'postnatal.saveFailed', {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createPostnatalVisitProvider);
    final isLoading = createState is AsyncLoading;
    final delivery = ref.watch(deliveryByIdProvider(widget.deliveryId));
    final deliveryDate = delivery.valueOrNull?.date;
    final visitNumber = int.tryParse(_visitNumberController.text);
    final suggestedVisitDate = deliveryDate != null && visitNumber != null
        ? pncVisitDate(deliveryDate, visitNumber)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'postnatal.title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(ref, 'postnatal.infoTitle'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
AppTextField(
                 label: tr(ref, 'postnatal.visitNumber'),
                 help: tr(ref, 'postnatal.visitNumberHelp'),
                 hint: tr(ref, 'postnatal.visitNumberHint'),
                 controller: _visitNumberController,
                 keyboardType: TextInputType.number,
                 onChanged: (_) => setState(() {}),
                 validator: (v) => positiveNumberValidator(v, fieldName: tr(ref, 'postnatal.visitNumber'), ref: ref),
               ),
               const SizedBox(height: 12),
               DateField(
                 label: tr(ref, 'postnatal.visitDate'),
                 help: tr(ref, 'postnatal.visitDateHelp'),
                 hint: tr(ref, 'postnatal.visitDateHint'),
                 value: _visitDate,
                 onChanged: (dt) => setState(() => _visitDate = dt),
                 computed: suggestedVisitDate,
                 firstDate: deliveryDate != null ? deliveryDate : DateTime(2020),
                 lastDate: deliveryDate?.add(const Duration(days: 180)) ?? DateTime(2030),
                 icon: Icons.calendar_today,
               ),
               const SizedBox(height: 24),
               AppTextField(
                 label: tr(ref, 'postnatal.motherStatus'),
                 help: tr(ref, 'postnatal.motherStatusHelp'),
                 hint: tr(ref, 'postnatal.motherStatusHint'),
                 controller: _motherStatusController,
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'postnatal.newbornWeight'),
                 help: tr(ref, 'postnatal.newbornWeightHelp'),
                 hint: tr(ref, 'postnatal.newbornWeightHint'),
                 controller: _newbornWeightController,
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'postnatal.breastfeedingStatus'),
                 help: tr(ref, 'postnatal.breastfeedingStatusHelp'),
                 hint: tr(ref, 'postnatal.breastfeedingStatusHint'),
                 controller: _breastfeedingStatusController,
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'postnatal.muac'),
                 help: tr(ref, 'postnatal.muacHelp'),
                 hint: tr(ref, 'postnatal.muacHint'),
                 controller: _muacController,
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'postnatal.physicalExam'),
                 help: tr(ref, 'postnatal.physicalExamHelp'),
                 hint: tr(ref, 'postnatal.physicalExamHint'),
                 controller: _physicalExamController,
                 maxLines: 2,
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'postnatal.labs'),
                 help: tr(ref, 'postnatal.labsHelp'),
                 hint: tr(ref, 'postnatal.labsHint'),
                 controller: _labsController,
                 maxLines: 2,
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'postnatal.mentalHealthNotes'),
                 help: tr(ref, 'postnatal.mentalHealthNotesHelp'),
                 hint: tr(ref, 'postnatal.mentalHealthNotesHint'),
                 controller: _mentalHealthNotesController,
                 maxLines: 2,
               ),
              const SizedBox(height: 12),
              DateField(
                label: tr(ref, 'postnatal.visitDate'),
                hint: tr(ref, 'postnatal.visitDateHint'),
                value: _visitDate,
                onChanged: (dt) => setState(() => _visitDate = dt),
                computed: suggestedVisitDate,
                firstDate: deliveryDate ?? DateTime(2020),
                lastDate: deliveryDate?.add(const Duration(days: 180)) ?? DateTime(2030),
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 24),
              Text(
                tr(ref, 'postnatal.motherAssessment'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: tr(ref, 'postnatal.motherStatus'),
                hint: tr(ref, 'postnatal.motherStatusHint'),
                controller: _motherStatusController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'postnatal.newbornWeight'),
                hint: tr(ref, 'postnatal.newbornWeightHint'),
                controller: _newbornWeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'postnatal.breastfeedingStatus'),
                hint: tr(ref, 'postnatal.breastfeedingStatusHint'),
                controller: _breastfeedingStatusController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'postnatal.muac'),
                hint: tr(ref, 'postnatal.muacHint'),
                controller: _muacController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'postnatal.physicalExam'),
                hint: tr(ref, 'postnatal.physicalExamHint'),
                controller: _physicalExamController,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'postnatal.labs'),
                hint: tr(ref, 'postnatal.labsHint'),
                controller: _labsController,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'postnatal.mentalHealthNotes'),
                hint: tr(ref, 'postnatal.mentalHealthNotesHint'),
                controller: _mentalHealthNotesController,
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  tr(ref, 'postnatal.save'),
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
