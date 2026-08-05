import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/tr.dart';
import '../../auth/auth_repository.dart';
import '../../auth/user.dart';
import '../profile_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _facilityController = TextEditingController();
  final _districtController = TextEditingController();
  final _regionController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _whatsappController.dispose();
    _facilityController.dispose();
    _districtController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _ensureInitialized() {
    if (_initialized) return;
    final u = ref.read(profileProvider).valueOrNull ??
        ref.read(authStateProvider).user;
    if (u == null) return;
    _initialized = true;
    _fullNameController.text = u.name;
    _whatsappController.text = u.whatsappNumber ?? '';
    _facilityController.text = u.facility ?? '';
    _districtController.text = u.district ?? '';
    _regionController.text = u.region ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final role = ref.read(authStateProvider).user?.role ?? UserRole.chw;
    final whatsapp = _whatsappController.text.trim();

    final update = ProfileUpdate(
      fullName: _fullNameController.text.trim(),
      whatsappNumber: whatsapp.isEmpty ? null : whatsapp,
      facility: role == UserRole.chw ? _facilityController.text.trim() : null,
      district: role == UserRole.supervisor
          ? _districtController.text.trim()
          : null,
      region: role == UserRole.supervisor ? _regionController.text.trim() : null,
    );

    try {
      final updated =
          await ref.read(updateProfileProvider.notifier).update(update);
      if (!mounted) return;
      if (updated != null) {
        ref.read(authStateProvider.notifier).refreshUser(updated);
      }
      ref.invalidate(profileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'profile.profileUpdated'))),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
    }
    return tr(ref, 'profile.updateFailed');
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialized();
    final saving = ref.watch(updateProfileProvider).isLoading;
    final role = ref.read(authStateProvider).user?.role ?? UserRole.chw;
    final isChw = role == UserRole.chw;
    final isSupervisor = role == UserRole.supervisor;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'profile.editProfile'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: tr(ref, 'profile.fullName'),
                controller: _fullNameController,
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    requiredValidator(v, fieldName: tr(ref, 'profile.fullName'), ref: ref),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'profile.whatsapp'),
                hint: 'e.g. +237 123 456 789',
                controller: _whatsappController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? null : phoneValidator(v, ref: ref),
              ),
              if (isChw) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: tr(ref, 'profile.facility'),
                  controller: _facilityController,
                  prefixIcon: Icons.local_hospital_outlined,
                  validator: (v) => requiredValidator(v,
                      fieldName: tr(ref, 'profile.facility'), ref: ref),
                ),
              ],
              if (isSupervisor) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: tr(ref, 'profile.district'),
                  controller: _districtController,
                  prefixIcon: Icons.map_outlined,
                  validator: (v) => requiredValidator(v,
                      fieldName: tr(ref, 'profile.district'), ref: ref),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: tr(ref, 'profile.region'),
                  controller: _regionController,
                  prefixIcon: Icons.public,
                  validator: (v) => requiredValidator(v,
                      fieldName: tr(ref, 'profile.region'), ref: ref),
                ),
              ],
              const SizedBox(height: 32),
              AppButton.primary(
                saving ? tr(ref, 'common.loading') : tr(ref, 'common.save'),
                onPressed: saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
