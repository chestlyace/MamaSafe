import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _message {
    final s = error.toString();
    if (s.startsWith('Exception:') || s.startsWith('ApiException')) {
      return s.replaceFirst(RegExp(r'^(Exception|ApiException)\(?\d*\)?:?\s*'), '');
    }
    if (s.startsWith('DioException')) {
      return 'A network error occurred. Please check your connection.';
    }
    return s;
  }
}
