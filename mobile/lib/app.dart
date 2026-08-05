import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/sync_engine.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/localization_provider.dart';

class MamaSafeApp extends ConsumerStatefulWidget {
  const MamaSafeApp({super.key});

  @override
  ConsumerState<MamaSafeApp> createState() => _MamaSafeAppState();
}

class _MamaSafeAppState extends ConsumerState<MamaSafeApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ref.read(localeProvider.notifier).loadLocale();
    if (mounted) setState(() => _ready = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(triggerSyncProvider)();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'MamaSafe',
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: Locale(locale.name),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr')],
    );
  }
}
