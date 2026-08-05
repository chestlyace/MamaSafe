import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/storage/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../../auth/auth_repository.dart';
import '../../auth/user.dart';
import '../referral_repository.dart';

class ReferralListScreen extends ConsumerStatefulWidget {
  const ReferralListScreen({super.key});

  @override
  ConsumerState<ReferralListScreen> createState() => _ReferralListScreenState();
}

class _ReferralListScreenState extends ConsumerState<ReferralListScreen> {
  String _statusFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final referralsAsync = ref.watch(referralsProvider);
    final isSupervisor = ref.watch(authStateProvider).user?.role == UserRole.supervisor;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'referral.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/home/referrals/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(tr(ref, 'referral.new')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr(ref, 'referral.searchHint'),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _StatusTab(tr(ref, 'referral.all'), _statusFilter == 'all', () => setState(() => _statusFilter = 'all')),
                const SizedBox(width: 8),
                _StatusTab(tr(ref, 'referral.pending'), _statusFilter == 'pending', () => setState(() => _statusFilter = 'pending')),
                const SizedBox(width: 8),
                _StatusTab(tr(ref, 'referral.accepted'), _statusFilter == 'accepted', () => setState(() => _statusFilter = 'accepted')),
                const SizedBox(width: 8),
                _StatusTab(tr(ref, 'referral.completed'), _statusFilter == 'completed', () => setState(() => _statusFilter = 'completed')),
                const SizedBox(width: 8),
                _StatusTab(tr(ref, 'referral.rejected'), _statusFilter == 'rejected', () => setState(() => _statusFilter = 'rejected')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: referralsAsync.when(
              data: (referrals) {
                var filtered = referrals.where((r) {
                  if (_statusFilter != 'all' && r.status != _statusFilter) return false;
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery;
                    if (!(r.patientRef?.toLowerCase().contains(q) ?? false) &&
                        !r.referredTo.toLowerCase().contains(q) &&
                        !r.reason.toLowerCase().contains(q)) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  if (_statusFilter != 'all' || _searchQuery.isNotEmpty) {
                    return EmptyState(
                      icon: Icons.search_off,
                      title: tr(ref, 'referral.notFound'),
                      subtitle: tr(ref, 'referral.adjustFilters'),
                    );
                  }
                  return EmptyState(
                    icon: Icons.local_hospital,
                    title: tr(ref, 'referral.emptyTitle'),
                    subtitle: tr(ref, 'referral.emptySubtitle'),
                    actionLabel: tr(ref, 'referral.new'),
                    onAction: () => context.push('/home/referrals/new'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(referralsProvider),
                  child: DismissibleManager(
                    referrals: filtered,
                    statusColor: _statusColor,
                    isSupervisor: isSupervisor,
                    ref: ref,
                    context: context,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(referralsProvider)),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabelOf(WidgetRef ref, String status) {
  switch (status) {
    case 'pending':
      return tr(ref, 'referral.pending');
    case 'accepted':
      return tr(ref, 'referral.accepted');
    case 'completed':
      return tr(ref, 'referral.completed');
    case 'rejected':
      return tr(ref, 'referral.rejected');
    default:
      return tr(ref, 'referral.cancelled');
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusTab(this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class DismissibleManager extends StatelessWidget {
  final List<Referral> referrals;
  final Color Function(String) statusColor;
  final bool isSupervisor;
  final WidgetRef ref;
  final BuildContext context;

  const DismissibleManager({
    super.key,
    required this.referrals,
    required this.statusColor,
    required this.isSupervisor,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: referrals.length,
      itemBuilder: (_, i) {
        final r = referrals[i];
        final color = statusColor(r.status);
        final hasWhatsApp = r.whatsappStatus != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: ValueKey(r.id),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(tr(ref, 'referral.deleteTitle')),
                    content: Text(tr(ref, 'referral.deleteContent', {'patient': r.patientRef ?? tr(ref, 'common.unknown')})),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(ref, 'common.cancel'))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr(ref, 'referral.delete'), style: const TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
              }
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            child: AppCard(
              onTap: () => context.push('/home/referrals/${r.id}'),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.patientRef ?? tr(ref, 'common.unknown'),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                            if (hasWhatsApp)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.chat, size: 14, color: Color(0xFF25D366)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.referredTo,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        if (r.reason.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            r.reason,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusLabelOf(ref, r.status).toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
