import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/date_field.dart';
import '../../../l10n/tr.dart';
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
        SnackBar(
          content: Text(tr(ref, 'referral.created')),
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
      appBar: AppBar(title: Text(tr(ref, 'referral.new'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
AppTextField(
                 label: tr(ref, 'referral.assessmentId'),
                 help: tr(ref, 'referral.assessmentIdHelp'),
                 hint: tr(ref, 'referral.assessmentIdHint'),
                 controller: _assessmentIdController,
                 keyboardType: TextInputType.number,
                 validator: (v) => numberValidator(v, fieldName: tr(ref, 'referral.assessmentId'), ref: ref),
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'referral.patientRefOptional'),
                 help: tr(ref, 'referral.patientRefHelp'),
                 hint: tr(ref, 'referral.patientRefHint'),
                 controller: _patientRefController,
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'referral.facility'),
                 help: tr(ref, 'referral.facilityHelp'),
                 hint: tr(ref, 'referral.facilityHint'),
                 controller: _referredToController,
                 validator: (v) =>
                     v == null || v.isEmpty ? tr(ref, 'referral.referredToRequired') : null,
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'referral.reason'),
                 help: tr(ref, 'referral.reasonHelp'),
                 hint: tr(ref, 'referral.reasonHint'),
                 controller: _reasonController,
                 maxLines: 3,
                 validator: (v) =>
                     v == null || v.isEmpty ? tr(ref, 'referral.reasonRequired') : null,
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'referral.notesOptional'),
                 help: tr(ref, 'referral.notesHelp'),
                 hint: tr(ref, 'referral.notesHint'),
                 controller: _notesController,
                 maxLines: 3,
               ),
               const SizedBox(height: 16),
               DateField(
                 label: tr(ref, 'referral.referralDate'),
                 help: tr(ref, 'referral.referralDateHelp'),
                 hint: tr(ref, 'referral.referralDateHint'),
                 value: _referralDate,
                 onChanged: (dt) => setState(() {
                   if (dt != null) _referralDate = dt;
                 }),
                 icon: Icons.calendar_today,
               ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  tr(ref, 'referral.submit'),
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
