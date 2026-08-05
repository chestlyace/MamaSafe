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
import '../user.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_page_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await ref.read(authStateProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
      if (!mounted) return;
      if (user.role == UserRole.admin) {
        context.go('/admin-browser');
      } else if (user.role == UserRole.supervisor) {
        context.go('/supervisor');
      } else {
        context.go('/home');
      }
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? e.response?.data['detail']?.toString()
          : null;
      if (mounted) {
        setState(
            () => _error = detail ?? e.message ?? tr(ref, 'auth.loginFailed'));
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(ref, 'auth.login'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'auth.username'),
                hint: tr(ref, 'auth.usernameHint'),
                controller: _usernameController,
                prefixIcon: Icons.person_outlined,
                validator: (v) => requiredValidator(
                  v,
                  fieldName: tr(ref, 'auth.username'),
                  ref: ref,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr(ref, 'auth.password'),
                hint: tr(ref, 'auth.passwordHint'),
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return tr(ref, 'auth.passwordRequired');
                  }
                  if (v.length < 6) {
                    return tr(ref, 'auth.passwordTooShort');
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AuthErrorBanner(message: _error!),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  tr(ref, 'auth.logIn'),
                  loading: _loading,
                  onPressed: _login,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/login/forgot-password'),
                child: Text(
                  tr(ref, 'auth.forgotPassword'),
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
      footer: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(ref, 'auth.noAccount'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textBody,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: Text(tr(ref, 'auth.signupAsSupervisor')),
            ),
            TextButton(
              onPressed: () => context.go('/chw-signup'),
              child: Text(tr(ref, 'auth.signupAsChw')),
            ),
          ],
        ),
      ),
    );
  }
}
