import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../facility_repository.dart';

class FacilityFormScreen extends ConsumerStatefulWidget {
  const FacilityFormScreen({super.key});

  @override
  ConsumerState<FacilityFormScreen> createState() => _FacilityFormScreenState();
}

class _FacilityFormScreenState extends ConsumerState<FacilityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _districtController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _districtController.dispose();
    _contactPhoneController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = CreateFacilityData(
      name: _nameController.text,
      location: _locationController.text,
      district: _districtController.text,
      contactPhone: _contactPhoneController.text.isNotEmpty
          ? _contactPhoneController.text
          : null,
      latitude: _latitudeController.text.isNotEmpty
          ? double.tryParse(_latitudeController.text)
          : null,
      longitude: _longitudeController.text.isNotEmpty
          ? double.tryParse(_longitudeController.text)
          : null,
    );

    try {
      await ref.read(facilityRepositoryProvider).createFacility(data);
      if (!mounted) return;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Facility')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Name',
                hint: 'e.g. District Hospital Bamenda',
                controller: _nameController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Location',
                hint: 'e.g. Bamenda',
                controller: _locationController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'District',
                hint: 'e.g. Mezam',
                controller: _districtController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'District is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Contact Phone (optional)',
                hint: 'e.g. +237 123 456 789',
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Latitude (optional)',
                hint: 'e.g. 5.96',
                controller: _latitudeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Longitude (optional)',
                hint: 'e.g. 10.15',
                controller: _longitudeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  'Save',
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
