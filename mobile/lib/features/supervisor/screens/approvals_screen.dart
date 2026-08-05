import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/storage/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../../approvals/approval_repository.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'approval.title'))),
      body: const ApprovalsBody(darkTabBar: true),
    );
  }
}

class ApprovalsBody extends ConsumerStatefulWidget {
  const ApprovalsBody({super.key, this.darkTabBar = true});

  final bool darkTabBar;

  @override
  ConsumerState<ApprovalsBody> createState() => _ApprovalsBodyState();
}

class _ApprovalsBodyState extends ConsumerState<ApprovalsBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final approvalsAsync = ref.watch(pendingApprovalsProvider);

    final tabBar = TabBar(
      controller: _tabController,
      labelColor: widget.darkTabBar ? AppColors.textOnPrimary : AppColors.primary,
      unselectedLabelColor:
          widget.darkTabBar ? Colors.white54 : AppColors.textSecondary,
      indicatorColor: widget.darkTabBar ? Colors.white : AppColors.primary,
      tabs: [
        Tab(text: tr(ref, 'approval.pending')),
        Tab(text: tr(ref, 'approval.approved')),
        Tab(text: tr(ref, 'approval.rejected')),
      ],
    );

    return Column(
      children: [
        if (widget.darkTabBar)
          Container(color: AppColors.primary, child: tabBar)
        else
          Material(color: AppColors.surface, child: tabBar),
        Expanded(
          child: approvalsAsync.when(
            data: (approvals) {
              if (approvals.isEmpty) {
                return EmptyState(
                  icon: Icons.check_circle_outline,
                  title: tr(ref, 'approval.noPending'),
                  subtitle: tr(ref, 'approval.noPendingSubtitle'),
                );
              }
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildList(approvals.where((a) => a.status == 'pending').toList()),
                  _buildList(approvals.where((a) => a.status == 'approved').toList()),
                  _buildList(approvals.where((a) => a.status == 'rejected').toList()),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(pendingApprovalsProvider)),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Approval> approvals) {
    if (approvals.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: tr(ref, 'approval.noItems'),
        subtitle: tr(ref, 'approval.noItemsSubtitle'),
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
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                  tr(ref, 'approval.requestedBy', {'name': a.requestedBy}),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                if (a.status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          tr(ref, 'approval.approve'),
                          onPressed: () => _handleAction(a.id, 'approved'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton.secondary(
                          tr(ref, 'approval.reject'),
                          onPressed: () => _handleAction(a.id, 'rejected'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (a.comments != null && a.comments!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    tr(ref, 'approval.comments', {'text': a.comments!}),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
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

  Future<void> _handleAction(int id, String action) async {
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
          decoration: InputDecoration(
              hintText: tr(ref, 'approval.commentsHint')),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isApprove
                  ? tr(ref, 'approval.approvedSnack')
                  : tr(ref, 'approval.rejectedSnack')),
              backgroundColor: AppColors.success),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isApprove
                  ? tr(ref, 'approval.approveFailed', {'error': '$e'})
                  : tr(ref, 'approval.rejectFailed', {'error': '$e'})),
              backgroundColor: AppColors.error),
        );
      }
    }
  }
}
