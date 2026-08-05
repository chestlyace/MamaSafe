import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/storage/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../maternity/maternity_repository.dart';
import '../../../l10n/tr.dart';
import '../schedule_repository.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'missed':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingVisitsProvider);
    final pregnanciesAsync = ref.watch(pregnanciesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'schedule.title'))),
      body: upcomingAsync.when(
        data: (visits) {
          if (visits.isEmpty) {
            return EmptyState(
              icon: Icons.event_available_outlined,
              title: tr(ref, 'schedule.emptyTitle'),
              subtitle: tr(ref, 'schedule.emptySubtitle'),
            );
          }
          return pregnanciesAsync.when(
            data: (pregnancies) {
              final pregnancyMap = {for (final p in pregnancies) p.id: p};
              return RefreshIndicator(
                onRefresh: () => ref.refresh(upcomingVisitsProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: visits.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          tr(ref, 'schedule.upcomingAnc'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      );
                    }
                    final v = visits[index - 1];
                    final patientName = pregnancyMap[v.pregnancyId]?.patientName ??
                        tr(ref, 'schedule.patientFallback', {'id': '${v.pregnancyId}'});
                    final statusColor = _statusColor(v.status);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => _showVisitDetails(context, ref, v, patientName),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tr(ref, 'anc.visitNumberWith', {'number': '${v.visitNumber}'}),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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
                                    tr(ref, 'schedule.${v.status}').toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  patientName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  '${v.scheduledDate.day}/${v.scheduledDate.month}/${v.scheduledDate.year}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _rescheduleVisit(context, ref, v),
                                icon: const Icon(Icons.edit_calendar, size: 16),
                                label: Text(tr(ref, 'schedule.reschedule')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(pregnanciesProvider)),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(upcomingVisitsProvider)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/schedule/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showVisitDetails(BuildContext context, WidgetRef ref, ScheduledVisit visit, String patientName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(ref, 'anc.visitNumberWith', {'number': '${visit.visitNumber}'}),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.person_outline, tr(ref, 'schedule.patient'), patientName),
            _detailRow(Icons.calendar_today, tr(ref, 'common.date'),
                '${visit.scheduledDate.day}/${visit.scheduledDate.month}/${visit.scheduledDate.year}'),
            _detailRow(Icons.info_outline, tr(ref, 'common.status'),
                tr(ref, 'schedule.${visit.status}')),
            if (visit.rescheduleReason != null)
              _detailRow(Icons.note_outlined, tr(ref, 'schedule.rescheduleReason'), visit.rescheduleReason!),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _rescheduleVisit(BuildContext context, WidgetRef ref, ScheduledVisit visit) async {
    final dateController = TextEditingController();
    final reasonController = TextEditingController();
    DateTime? newDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ref, 'schedule.rescheduleVisit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: tr(ref, 'schedule.newDate'),
                hintText: tr(ref, 'schedule.dateHint'),
              ),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: visit.scheduledDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  newDate = picked;
                  dateController.text =
                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(labelText: tr(ref, 'schedule.reason')),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(ref, 'common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(ref, 'common.confirm')),
          ),
        ],
      ),
    );

    if (result == true && newDate != null && reasonController.text.trim().isNotEmpty) {
      try {
        await ref.read(scheduleRepositoryProvider).rescheduleVisit(visit.id, newDate!, reasonController.text.trim());
        ref.invalidate(upcomingVisitsProvider);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(ref, 'schedule.rescheduled')), backgroundColor: AppColors.success),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(ref, 'schedule.rescheduleFailed', {'error': '$e'})), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
