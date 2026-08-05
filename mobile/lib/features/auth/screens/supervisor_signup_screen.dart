import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/tr.dart';
import '../auth_repository.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_page_shell.dart';

class SupervisorSignupScreen extends ConsumerStatefulWidget {
  const SupervisorSignupScreen({super.key});

  @override
  ConsumerState<SupervisorSignupScreen> createState() =>
      _SupervisorSignupScreenState();
}

class _SupervisorSignupScreenState
    extends ConsumerState<SupervisorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _districtController = TextEditingController();
  final _regionController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _districtController.dispose();
    _regionController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = false;
    });

    try {
      await ref.read(authRepositoryProvider).supervisorSignup(
            fullName: _fullNameController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            district: _districtController.text.trim(),
            region: _regionController.text.trim().isEmpty
                ? null
                : _regionController.text.trim(),
            whatsappNumber: _whatsappController.text.trim().isEmpty
                ? null
                : _whatsappController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _success = true);
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? e.response?.data['detail']?.toString()
          : null;
      if (mounted) {
        setState(
            () => _error = detail ?? e.message ?? tr(ref, 'auth.signupFailed'));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: _success
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 48, color: AppColors.success),
                  const SizedBox(height: 12),
                  Text(
                    tr(ref, 'auth.signupSuccess'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      tr(ref, 'auth.goToLogin'),
                      onPressed: () => context.go('/login'),
                    ),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr(ref, 'auth.supervisorSignupTitle'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: tr(ref, 'auth.fullName'),
                      hint: tr(ref, 'auth.fullNameHint'),
                      controller: _fullNameController,
                      prefixIcon: Icons.person_outline,
                      validator: (value) => requiredValidator(
                        value,
                        fieldName: tr(ref, 'auth.fullName'),
                        ref: ref,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: tr(ref, 'auth.username'),
                      hint: tr(ref, 'auth.usernameHint'),
                      controller: _usernameController,
                      prefixIcon: Icons.badge_outlined,
                      validator: (value) => requiredValidator(
                        value,
                        fieldName: tr(ref, 'auth.username'),
                        ref: ref,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: tr(ref, 'auth.password'),
                      hint: tr(ref, 'auth.passwordHint'),
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr(ref, 'auth.passwordRequired');
                        }
                        if (value.length < 6) {
                          return tr(ref, 'auth.passwordTooShort');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: tr(ref, 'auth.district'),
                      hint: tr(ref, 'auth.districtHint'),
                      controller: _districtController,
                      prefixIcon: Icons.map_outlined,
                      validator: (value) => requiredValidator(
                        value,
                        fieldName: tr(ref, 'auth.district'),
                        ref: ref,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: tr(ref, 'auth.region'),
                      hint: tr(ref, 'auth.regionHint'),
                      controller: _regionController,
                      prefixIcon: Icons.public_outlined,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: tr(ref, 'auth.whatsappNumber'),
                      hint: tr(ref, 'auth.whatsappHint'),
                      controller: _whatsappController,
                      prefixIcon: Icons.chat_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) => phoneValidator(value, ref: ref),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      AuthErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        tr(ref, 'auth.signup'),
                        loading: _loading,
                        onPressed: _submit,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(tr(ref, 'auth.backToLogin')),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
