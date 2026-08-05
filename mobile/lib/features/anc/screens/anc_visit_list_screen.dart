import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../anc_repository.dart';

class AncVisitListScreen extends ConsumerWidget {
  final int pregnancyId;

  const AncVisitListScreen({super.key, required this.pregnancyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(ancVisitsProvider(pregnancyId));

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'anc.title'))),
      body: visitsAsync.when(
        data: (visits) {
          if (visits.isEmpty) {
            return EmptyState(
              icon: Icons.calendar_month_outlined,
              title: tr(ref, 'anc.emptyTitle'),
              subtitle: tr(ref, 'anc.emptySubtitle'),
            );
          }
          final latestGa = visits
              .where((v) => v.gestationalAgeWeeks != null)
              .map((v) => v.gestationalAgeWeeks!)
              .toList()
            ..sort();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              AppCard(
                child: Row(
                  children: [
                    _summaryTile(tr(ref, 'anc.visits'), '${visits.length}', Icons.monitor_heart_outlined),
                    Container(
                      height: 40,
                      width: 1,
                      color: AppColors.border,
                    ),
                    _summaryTile(tr(ref, 'anc.gestationalAge'), latestGa.isNotEmpty ? '${latestGa.last}w' : tr(ref, 'common.na'), Icons.access_time),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...visits.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      onTap: () => context.push('/home/anc-visits/${v.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tr(ref, 'anc.visitNumberWith', {'number': '${v.visitNumber}'}),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${v.date.day}/${v.date.month}/${v.date.year}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (v.systolicBp != null && v.diastolicBp != null) ...[
                                _chip('BP: ${v.systolicBp!.toStringAsFixed(0)}/${v.diastolicBp!.toStringAsFixed(0)}', Icons.favorite_border),
                                const SizedBox(width: 8),
                              ],
                              if (v.weight != null) ...[
                                _chip('${v.weight!.toStringAsFixed(1)} kg', Icons.monitor_weight_outlined),
                                const SizedBox(width: 8),
                              ],
                              if (v.fundalHeight != null)
                                _chip('FH: ${v.fundalHeight!.toStringAsFixed(1)} cm', Icons.straighten),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          error: e,
          onRetry: () => ref.invalidate(ancVisitsProvider(pregnancyId)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/anc-visits/new?pregnancyId=$pregnancyId'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _summaryTile(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
