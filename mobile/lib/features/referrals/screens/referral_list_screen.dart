import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../referral_repository.dart';

class ReferralListScreen extends ConsumerWidget {
  const ReferralListScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralsAsync = ref.watch(referralsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
      body: referralsAsync.when(
        data: (referrals) {
          if (referrals.isEmpty) {
            return const EmptyState(
              icon: Icons.local_hospital_outlined,
              title: 'No referrals yet',
              subtitle: 'Refer a patient to get started',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: referrals.length,
            itemBuilder: (context, index) {
              final r = referrals[index];
              final statusColor = _statusColor(r.status);
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
                              r.patientRef ?? 'Unknown',
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
                              r.status.toUpperCase(),
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
                          const Icon(Icons.local_hospital,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r.referredTo,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
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
                            '${r.referralDate.day}/${r.referralDate.month}/${r.referralDate.year}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(referralsProvider)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/referrals/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
