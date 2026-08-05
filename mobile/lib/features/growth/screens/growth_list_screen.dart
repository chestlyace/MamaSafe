import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../growth_repository.dart';

class GrowthListScreen extends ConsumerWidget {
  const GrowthListScreen({super.key});

  Color _statusColor(String? status) {
    switch (status) {
      case 'normal':
        return AppColors.success;
      case 'moderate':
        return AppColors.warning;
      case 'severe':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(WidgetRef ref, String? status) {
    switch (status) {
      case 'normal':
        return tr(ref, 'growth.normal');
      case 'moderate':
        return tr(ref, 'growth.moderate');
      case 'severe':
        return tr(ref, 'growth.severe');
      default:
        return tr(ref, 'common.unknown');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(growthRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'growth.title'))),
      body: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return EmptyState(
              icon: Icons.monitor_heart_outlined,
              title: tr(ref, 'growth.emptyTitle'),
              subtitle: tr(ref, 'growth.emptySubtitle'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              final statusColor = _statusColor(r.nutritionalStatus);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () {
                    if (r.childRef != null) {
                      context.push('/home/growth/${r.childRef}');
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.childName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr(ref, 'growth.monthsWeight', {
                                'months': '${r.ageMonths}',
                                'weight': r.weight.toStringAsFixed(1),
                              }),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (r.muac != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                tr(ref, 'growth.muacValue', {'value': r.muac!.toStringAsFixed(1)}),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${r.recordedAt.day}/${r.recordedAt.month}/${r.recordedAt.year}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (r.nutritionalStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(ref, r.nutritionalStatus).toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(growthRecordsProvider)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/growth/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
