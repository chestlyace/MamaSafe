import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../maternity_repository.dart';

class MaternityListScreen extends ConsumerWidget {
  const MaternityListScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'delivered':
        return AppColors.success;
      case 'transferred':
        return AppColors.warning;
      case 'lost':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'delivered':
        return 'Delivered';
      case 'transferred':
        return 'Transferred';
      case 'lost':
        return 'Lost';
      default:
        return status;
    }
  }

  Color _riskColor(String? riskLevel) {
    switch (riskLevel) {
      case 'high':
        return AppColors.accent;
      case 'mid':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnanciesAsync = ref.watch(pregnanciesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Maternity')),
      body: pregnanciesAsync.when(
        data: (pregnancies) {
          if (pregnancies.isEmpty) {
            return const EmptyState(
              icon: Icons.pregnant_woman_outlined,
              title: 'No pregnancies registered',
              subtitle: 'Register a pregnancy to start tracking',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: pregnancies.length,
            itemBuilder: (context, index) {
              final p = pregnancies[index];
              final statusColor = _statusColor(p.status);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.patientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusLabel(p.status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (p.edd != null) ...[
                            const Icon(Icons.calendar_today,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'EDD: ${p.edd}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (p.gestationalAgeWeeks != null) ...[
                            const Icon(Icons.access_time,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${p.gestationalAgeWeeks}w',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (p.riskLevel != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _riskColor(p.riskLevel).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.riskLevel!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _riskColor(p.riskLevel),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(pregnanciesProvider)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/pregnancies/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
