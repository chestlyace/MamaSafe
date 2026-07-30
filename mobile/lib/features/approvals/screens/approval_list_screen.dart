import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../approval_repository.dart';

class ApprovalListScreen extends ConsumerWidget {
  const ApprovalListScreen({super.key});

  Color _entityColor(String entityType) {
    switch (entityType) {
      case 'assessment':
        return AppColors.primary;
      case 'referral':
        return AppColors.warning;
      case 'pregnancy':
        return Colors.blue;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(pendingApprovalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: approvalsAsync.when(
        data: (approvals) {
          if (approvals.isEmpty) {
            return const Center(child: Text('No pending approvals'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvals.length,
            itemBuilder: (context, index) {
              final a = approvals[index];
              final entityColor = _entityColor(a.entityType);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: entityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              a.entityType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: entityColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Action: ${a.action}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By: ${a.requestedBy}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.secondary(
                              'Approve',
                              onPressed: () => _handleAction(context, ref, a.id, 'approved'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton.secondary(
                              'Reject',
                              onPressed: () => _handleAction(context, ref, a.id, 'rejected'),
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
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, int id, String action) async {
    final commentsController = TextEditingController();
    final actionLabel = action == 'approved' ? 'Approve' : 'Reject';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionLabel Request'),
        content: TextField(
          controller: commentsController,
          decoration: const InputDecoration(hintText: 'Comments (optional)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(approvalRepositoryProvider);
      if (action == 'approved') {
        await repo.approve(id, 'supervisor', commentsController.text.trim().isEmpty
            ? null
            : commentsController.text.trim());
      } else {
        await repo.reject(id, 'supervisor', commentsController.text.trim().isEmpty
            ? null
            : commentsController.text.trim());
      }
      ref.invalidate(pendingApprovalsProvider);
    }
  }
}
