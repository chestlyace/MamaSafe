import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/tr.dart';
import '../patient_repository.dart';

class PatientDetailScreen extends ConsumerWidget {
  final int patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientByIdProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'patients.details')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: patientAsync.when(
        data: (patient) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(tr(ref, 'patients.fullName')),
                    _value(patient.fullName),
                    const SizedBox(height: 12),
                    _label(tr(ref, 'patients.dateOfBirth')),
                    _value(patient.dateOfBirth ?? tr(ref, 'common.notProvided')),
                    const SizedBox(height: 12),
                    _label(tr(ref, 'patients.phone')),
                    _value(patient.phone ?? tr(ref, 'common.notProvided')),
                    const SizedBox(height: 12),
                    _label(tr(ref, 'patients.address')),
                    _value(patient.address ?? tr(ref, 'common.notProvided')),
                    const SizedBox(height: 12),
                    _label(tr(ref, 'patients.facility')),
                    _value(patient.facility ?? tr(ref, 'common.notProvided')),
                    const SizedBox(height: 12),
                    _label(tr(ref, 'patients.bloodGroup')),
                    _value(patient.bloodGroup ?? tr(ref, 'common.notProvided')),
                    const SizedBox(height: 12),
                    _label(tr(ref, 'patients.allergies')),
                    _value(patient.allergies ?? tr(ref, 'common.none')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(ref, 'patients.emergencyContacts'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    _label(tr(ref, 'patients.emergencyName')),
                    _value(patient.emergencyContactName ?? tr(ref, 'common.notProvided')),
                    const SizedBox(height: 12),
                    _label(tr(ref, 'patients.emergencyPhone')),
                    _value(patient.emergencyContactPhone ?? tr(ref, 'common.notProvided')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tr(ref, 'patients.actions'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  tr(ref, 'patients.newAssessment'),
                  iconLeft: Icons.assessment,
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AppButton.secondary(
                  tr(ref, 'patients.newPregnancy'),
                  iconLeft: Icons.pregnant_woman,
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AppButton.outline(
                  tr(ref, 'patients.viewHistory'),
                  iconLeft: Icons.history,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
            error: e, onRetry: () => ref.invalidate(patientByIdProvider(patientId))),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _value(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }
}
