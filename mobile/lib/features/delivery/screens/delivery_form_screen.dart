import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/date_field.dart';
import '../../../l10n/tr.dart';
import '../delivery_repository.dart';

class DeliveryFormScreen extends ConsumerStatefulWidget {
  final int patientId;
  final int? pregnancyId;

  const DeliveryFormScreen({
    super.key,
    required this.patientId,
    this.pregnancyId,
  });

  @override
  ConsumerState<DeliveryFormScreen> createState() => _DeliveryFormScreenState();
}

class _DeliveryFormScreenState extends ConsumerState<DeliveryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _deliveredByController = TextEditingController();
  final _complicationsController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _locationController.dispose();
    _deliveredByController.dispose();
    _complicationsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = CreateDeliveryData(
      patientId: widget.patientId,
      pregnancyId: widget.pregnancyId ?? 0,
      date: _date,
      location: _locationController.text.trim(),
      deliveredBy: _deliveredByController.text.trim(),
      complications: _complicationsController.text.trim().isEmpty
          ? null
          : _complicationsController.text.trim(),
    );

    try {
      await ref.read(createDeliveryProvider.notifier).create(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(ref, 'delivery.saved')),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(ref, 'delivery.saveFailed', {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createDeliveryProvider);
    final isLoading = createState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'delivery.new'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(ref, 'delivery.infoTitle'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              DateField(
                label: tr(ref, 'delivery.date'),
                hint: tr(ref, 'delivery.dateHint'),
                value: _date,
                onChanged: (dt) => setState(() {
                  if (dt != null) _date = dt;
                }),
                lastDate: DateTime.now(),
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 16),
AppTextField(
                 label: tr(ref, 'delivery.location'),
                 help: tr(ref, 'delivery.locationHelp'),
                 hint: tr(ref, 'delivery.locationHint'),
                 controller: _locationController,
                 validator: (v) => requiredValidator(v, fieldName: tr(ref, 'delivery.location'), ref: ref),
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'delivery.deliveredBy'),
                 help: tr(ref, 'delivery.deliveredByHelp'),
                 hint: tr(ref, 'delivery.deliveredByHint'),
                 controller: _deliveredByController,
                 validator: (v) => requiredValidator(v, fieldName: tr(ref, 'delivery.deliveredBy'), ref: ref),
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'delivery.complications'),
                 help: tr(ref, 'delivery.complicationsHelp'),
                 hint: tr(ref, 'delivery.complicationsHint'),
                 controller: _complicationsController,
                 maxLines: 3,
               ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  tr(ref, 'delivery.save'),
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
