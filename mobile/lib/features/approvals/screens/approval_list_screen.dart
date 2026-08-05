import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
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

  String _entityLabel(WidgetRef ref, String entityType) {
    switch (entityType) {
      case 'assessment':
        return tr(ref, 'approval.entityAssessment');
      case 'referral':
        return tr(ref, 'approval.entityReferral');
      case 'pregnancy':
        return tr(ref, 'approval.entityPregnancy');
      default:
        return entityType.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(pendingApprovalsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'supervisor.pendingApprovals'))),
      body: approvalsAsync.when(
        data: (approvals) {
          if (approvals.isEmpty) {
            return EmptyState(
              icon: Icons.check_circle_outline,
              title: tr(ref, 'approval.noPending'),
              subtitle: tr(ref, 'approval.noPendingSubtitle'),
            );
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
                              _entityLabel(ref, a.entityType),
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
                        tr(ref, 'approval.action', {'action': a.action}),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr(ref, 'approval.by', {'name': a.requestedBy}),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.secondary(
                              tr(ref, 'approval.approve'),
                              onPressed: () => _handleAction(context, ref, a.id, 'approved'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton.secondary(
                              tr(ref, 'approval.reject'),
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
        error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(pendingApprovalsProvider)),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, int id, String action) async {
    final commentsController = TextEditingController();
    final isApprove = action == 'approved';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove
            ? tr(ref, 'approval.approveRequest')
            : tr(ref, 'approval.rejectRequest')),
        content: TextField(
          controller: commentsController,
          decoration:
              InputDecoration(hintText: tr(ref, 'approval.commentsHint')),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(ref, 'common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isApprove
                ? tr(ref, 'approval.approve')
                : tr(ref, 'approval.reject')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(approvalRepositoryProvider);
        final comments = commentsController.text.trim().isEmpty
            ? null
            : commentsController.text.trim();
        if (action == 'approved') {
          await repo.approve(id, 'supervisor', comments);
        } else {
          await repo.reject(id, 'supervisor', comments);
        }
        ref.invalidate(pendingApprovalsProvider);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isApprove
                  ? tr(ref, 'approval.approveFailed', {'error': '$e'})
                  : tr(ref, 'approval.rejectFailed', {'error': '$e'})),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
