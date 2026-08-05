import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/tr.dart';
import '../profile_repository.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(changePasswordProvider.notifier).change(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'profile.passwordUpdated'))),
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
    return tr(ref, 'profile.passwordChangeFailed');
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(changePasswordProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'profile.changePassword'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: tr(ref, 'profile.currentPassword'),
                controller: _currentController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) => (v == null || v.isEmpty)
                    ? tr(ref, 'profile.currentPasswordRequired')
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'profile.newPassword'),
                controller: _newController,
                obscureText: true,
                prefixIcon: Icons.lock_reset,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return tr(ref, 'profile.newPasswordRequired');
                  }
                  if (v.length < 8) {
                    return tr(ref, 'profile.passwordTooShort');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'profile.confirmPassword'),
                controller: _confirmController,
                obscureText: true,
                prefixIcon: Icons.lock_reset,
                validator: (v) => v == _newController.text
                    ? null
                    : tr(ref, 'profile.passwordsDontMatch'),
              ),
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
