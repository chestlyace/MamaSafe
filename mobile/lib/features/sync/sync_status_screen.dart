import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/app_error_widget.dart';
import '../../core/network/sync_engine.dart';
import '../../core/storage/database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/tr.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingOpsAsync = ref.watch(pendingOpsProvider);
    final syncProgress = ref.watch(syncProgressProvider);
    final engine = ref.watch(syncEngineProvider);
    final lastSync = engine.lastSyncTime;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'sync.title'))),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pendingOpsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SyncSummaryCard(
              pendingOpsAsync: pendingOpsAsync,
              syncProgress: syncProgress,
              lastSync: lastSync,
            ),
            const SizedBox(height: 16),
            _PendingOpsList(pendingOpsAsync: pendingOpsAsync),
          ],
        ),
      ),
    );
  }
}

class _SyncSummaryCard extends ConsumerWidget {
  final AsyncValue<List<PendingOp>> pendingOpsAsync;
  final AsyncValue<SyncProgress> syncProgress;
  final DateTime? lastSync;

  const _SyncSummaryCard({
    required this.pendingOpsAsync,
    required this.syncProgress,
    this.lastSync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = syncProgress.valueOrNull?.isRunning ?? false;
    final totalOps = pendingOpsAsync.valueOrNull?.length ?? 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.sync, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                tr(ref, 'sync.queue'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: totalOps > 0
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tr(ref, 'sync.pendingCount', {'count': '$totalOps'}),
                  style: TextStyle(
                    color: totalOps > 0 ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isRunning) ...[
            const LinearProgressIndicator(
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${syncProgress.valueOrNull?.completed ?? 0} / ${syncProgress.valueOrNull?.total ?? 0}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          if (lastSync != null) ...[
            const SizedBox(height: 4),
            Text(
              tr(ref, 'sync.lastSync', {'time': _formatDateTime(ref, lastSync!)}),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isRunning
                  ? null
                  : () async {
                      await ref.read(triggerSyncProvider)();
                      ref.invalidate(pendingOpsProvider);
                    },
              icon: Icon(
                isRunning ? Icons.hourglass_top : Icons.sync,
                size: 18,
              ),
              label: Text(isRunning ? tr(ref, 'sync.syncing') : tr(ref, 'sync.now')),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(WidgetRef ref, DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return tr(ref, 'sync.justNow');
    if (diff.inMinutes < 60) return tr(ref, 'sync.minutesAgo', {'count': '${diff.inMinutes}'});
    if (diff.inHours < 24) return tr(ref, 'sync.hoursAgo', {'count': '${diff.inHours}'});
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _PendingOpsList extends ConsumerWidget {
  final AsyncValue<List<PendingOp>> pendingOpsAsync;

  const _PendingOpsList({required this.pendingOpsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return pendingOpsAsync.when(
      data: (ops) {
        if (ops.isEmpty) {
          return AppCard(
            variant: AppCardVariant.outlined,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  tr(ref, 'sync.noPending'),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tr(ref, 'sync.pendingOperations'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...ops.map((op) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PendingOpCard(op: op),
                )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(pendingOpsProvider)),
    );
  }
}

class _PendingOpCard extends StatelessWidget {
  final PendingOp op;
  const _PendingOpCard({required this.op});

  @override
  Widget build(BuildContext context) {
    final Color methodColor;
    switch (op.operationType.toUpperCase()) {
      case 'POST':
        methodColor = AppColors.success;
      case 'PUT':
      case 'PATCH':
        methodColor = AppColors.warning;
      case 'DELETE':
        methodColor = AppColors.error;
      default:
        methodColor = AppColors.textSecondary;
    }

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: methodColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              op.operationType.toUpperCase(),
              style: TextStyle(
                color: methodColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  op.endpoint,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${op.createdAt.day}/${op.createdAt.month}/${op.createdAt.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
