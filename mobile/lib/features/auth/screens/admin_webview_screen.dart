import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/tr.dart';
import '../auth_repository.dart';

class AdminWebViewScreen extends ConsumerStatefulWidget {
  const AdminWebViewScreen({super.key});

  @override
  ConsumerState<AdminWebViewScreen> createState() => _AdminWebViewScreenState();
}

class _AdminWebViewScreenState extends ConsumerState<AdminWebViewScreen> {
  WebViewController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    final rawUrl = dotenv.env['WEB_APP_URL'] ?? 'http://localhost:5173';
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      _error = 'Web app URL is not configured';
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(uri);
  }

  Future<void> _close() async {
    await ref.read(authStateProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(tr(ref, 'app.name')),
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _close,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public_off,
                      color: AppColors.error, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      tr(ref, 'auth.backToLogin'),
                      onPressed: _close,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return WillPopScope(
      onWillPop: () async {
        await _close();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(tr(ref, 'app.name')),
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _close,
            ),
          ],
        ),
        body: WebViewWidget(controller: controller),
      ),
    );
  }
}
