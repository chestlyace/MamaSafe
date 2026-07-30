import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/sync_engine.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class MamaSafeApp extends ConsumerStatefulWidget {
  const MamaSafeApp({super.key});

  @override
  ConsumerState<MamaSafeApp> createState() => _MamaSafeAppState();
}

class _MamaSafeAppState extends ConsumerState<MamaSafeApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(triggerSyncProvider)();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MamaSafe',
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
