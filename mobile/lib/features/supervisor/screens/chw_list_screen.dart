import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../supervisor_repository.dart';

class ChwListScreen extends ConsumerStatefulWidget {
  const ChwListScreen({super.key});

  @override
  ConsumerState<ChwListScreen> createState() => _ChwListScreenState();
}

class _ChwListScreenState extends ConsumerState<ChwListScreen> {
  @override
  Widget build(BuildContext context) {
    final chwsAsync = ref.watch(chwsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'supervisor.chwManagement')),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: const Color(0xFFE11D48),
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 12,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.vpn_key),
            label: tr(ref, 'supervisor.inviteCode'),
            onTap: () => context.push('/supervisor/invites'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.person_add_outlined),
            label: tr(ref, 'supervisor.manualEntry'),
            onTap: () => context.push('/supervisor/chws/new'),
          ),
        ],
      ),
      body: chwsAsync.when(
        data: (chws) {
          if (chws.isEmpty) {
            return EmptyState(
              icon: Icons.badge_outlined,
              title: tr(ref, 'supervisor.noChws'),
              subtitle: tr(ref, 'supervisor.chwEmptySubtitle'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: chws.length,
            itemBuilder: (context, i) {
              final c = chws[i];
              final color = c.status == 'active'
                  ? AppColors.success
                  : c.status == 'inactive_warning'
                      ? AppColors.warning
                      : AppColors.error;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => context.push('/supervisor/chws/${c.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.fullName,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(c.status),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(c.facility ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _mini('${c.patientCount}', tr(ref, 'supervisor.miniPatients')),
                          _mini('${c.assessmentCount}', tr(ref, 'supervisor.assessments')),
                          _mini('${c.highRiskCount}', tr(ref, 'supervisor.highRisk')),
                          _mini(
                              '${c.referralCompletionRate.toStringAsFixed(0)}%',
                              tr(ref, 'supervisor.refRate')),
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
        error: (e, _) => AppErrorWidget(
            error: e, onRetry: () => ref.invalidate(chwsProvider)),
      ),
    );
  }

  Widget _mini(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return tr(ref, 'supervisor.statusActive');
      case 'inactive_warning':
        return tr(ref, 'supervisor.statusInactiveWarning');
      default:
        return tr(ref, 'supervisor.statusInactive');
    }
  }
}
