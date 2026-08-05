import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_brand.dart';
import 'auth_language_toggle.dart';

class AuthPageShell extends StatelessWidget {
  final Widget child;
  final Widget? footer;

  const AuthPageShell({super.key, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: AuthLanguageToggle(),
                  ),
                  const SizedBox(height: 28),
                  const AuthBrand(),
                  const SizedBox(height: 28),
                  child,
                  if (footer != null) ...[
                    const SizedBox(height: 16),
                    footer!,
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
