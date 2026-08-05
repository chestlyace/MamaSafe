import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/tr.dart';
import '../theme/app_theme.dart';

class AppErrorWidget extends ConsumerWidget {
  final Object error;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              _message(ref),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(tr(ref, 'common.retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _message(WidgetRef ref) {
    final s = error.toString();
    if (s.startsWith('Exception:') || s.startsWith('ApiException')) {
      return s.replaceFirst(RegExp(r'^(Exception|ApiException)\(?\d*\)?:?\s*'), '');
    }
    if (s.startsWith('DioException')) {
      return tr(ref, 'common.networkError');
    }
    return s;
  }
}
