import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/tr.dart';
import '../../auth/auth_repository.dart';
import '../../auth/user.dart';
import '../../profile/profile_repository.dart';
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
  void initState() {
    super.initState();
    Future.microtask(() {
      final profile = ref.read(profileProvider);
      profile.whenData((user) {
        if (user.district != null && user.district!.isNotEmpty) {
          _districtController.text = user.district!;
        }
      });
    });
  }

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
      ref.invalidate(facilitiesProvider);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(ref, 'facility.saveFailed', {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final isStaff = auth.user?.role == UserRole.supervisor ||
        auth.user?.role == UserRole.admin;
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, isStaff ? 'facility.new' : 'facility.suggest'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: tr(ref, 'facility.name'),
                hint: tr(ref, 'facility.nameHint'),
                controller: _nameController,
                validator: (v) => requiredValidator(v, fieldName: tr(ref, 'facility.name'), ref: ref),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'facility.location'),
                hint: tr(ref, 'facility.locationHint'),
                controller: _locationController,
                validator: (v) => requiredValidator(v, fieldName: tr(ref, 'facility.location'), ref: ref),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'facility.district'),
                hint: tr(ref, 'facility.districtHint'),
                controller: _districtController,
                validator: (v) => requiredValidator(v, fieldName: tr(ref, 'facility.district'), ref: ref),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'facility.contactPhone'),
                hint: tr(ref, 'facility.contactPhoneHint'),
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? null : phoneValidator(v, ref: ref),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'facility.latitude'),
                hint: tr(ref, 'facility.latitudeHint'),
                controller: _latitudeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (double.tryParse(v) == null) return tr(ref, 'facility.invalidNumber');
                  final lat = double.parse(v);
                  if (lat < -90 || lat > 90) return tr(ref, 'facility.latRange');
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'facility.longitude'),
                hint: tr(ref, 'facility.longitudeHint'),
                controller: _longitudeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (double.tryParse(v) == null) return tr(ref, 'facility.invalidNumber');
                  final lng = double.parse(v);
                  if (lng < -180 || lng > 180) return tr(ref, 'facility.lngRange');
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  tr(ref, 'common.save'),
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
