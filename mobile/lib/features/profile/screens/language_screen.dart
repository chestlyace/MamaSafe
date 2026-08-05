import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/localization_provider.dart';
import '../../../l10n/tr.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'language.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr(ref, 'language.subtitle'),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                _LanguageTile(
                  label: tr(ref, 'language.english'),
                  selected: current == AppLocale.en,
                  onTap: () =>
                      ref.read(localeProvider.notifier).setLocale(AppLocale.en),
                ),
                const Divider(height: 1, color: AppColors.border),
                _LanguageTile(
                  label: tr(ref, 'language.french'),
                  selected: current == AppLocale.fr,
                  onTap: () =>
                      ref.read(localeProvider.notifier).setLocale(AppLocale.fr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              selected ? Icons.language : Icons.language_outlined,
              size: 22,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 22,
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}
