import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/auth_repository.dart';
import '../../auth/user.dart';
import '../../supervisor/supervisor_repository.dart';
import '../../approvals/approval_repository.dart';
import '../../../l10n/localization_provider.dart';
import '../../../l10n/tr.dart';
import '../profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user?.role == UserRole.admin) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(tr(ref, 'nav.profile')),
            bottom: TabBar(
              tabs: [
                Tab(text: tr(ref, 'nav.profile')),
                Tab(text: tr(ref, 'nav.supervisor')),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _ProfileTab(user: user, ref: ref),
              const _SupervisorTab(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'nav.profile'))),
      body: _ProfileTab(user: user, ref: ref),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final User? user;

  const _ProfileTab({this.user, required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final u = profile ?? user;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  _initials(user?.name ?? '??'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user?.name ?? 'User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              _RoleBadge(role: user?.role),
              if (u != null && u.facility != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      u.facility!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(ref, 'profile.accountInfo'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.person_outline,
                label: tr(ref, 'profile.username'),
                value: user?.username ?? '-',
              ),
              if (u?.createdAt != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: tr(ref, 'profile.memberSince'),
                  value: _formatDate(u!.createdAt!),
                ),
              ],
              if (u?.facility != null && u!.facility!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.local_hospital_outlined,
                  label: tr(ref, 'profile.facility'),
                  value: u.facility!,
                ),
              ],
              if (u?.district != null && u!.district!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.map_outlined,
                  label: tr(ref, 'profile.district'),
                  value: u.district!,
                ),
              ],
              if (u?.region != null && u!.region!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.public,
                  label: tr(ref, 'profile.region'),
                  value: u.region!,
                ),
              ],
              if (u?.whatsappNumber != null &&
                  u!.whatsappNumber!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: tr(ref, 'profile.whatsapp'),
                  value: u.whatsappNumber!,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(ref, 'profile.settings'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.edit_outlined,
                title: tr(ref, 'profile.editProfile'),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onTap: () => context.push('/profile/edit'),
              ),
              const Divider(height: 1, color: AppColors.border),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: tr(ref, 'profile.changePassword'),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onTap: () => context.push('/profile/password'),
              ),
              const Divider(height: 1, color: AppColors.border),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: tr(ref, 'profile.notifications'),
                trailing: Switch(value: true, onChanged: (_) {}),
              ),
              const Divider(height: 1, color: AppColors.border),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: tr(ref, 'profile.darkMode'),
                trailing: Switch(value: false, onChanged: (_) {}),
              ),
              const Divider(height: 1, color: AppColors.border),
              _SettingsTile(
                icon: Icons.language,
                title: tr(ref, 'profile.language'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentLanguageLabel(ref),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                onTap: () => context.push('/profile/language'),
              ),
              const Divider(height: 1, color: AppColors.border),
              _SettingsTile(
                icon: Icons.info_outline,
                title: tr(ref, 'profile.about'),
                onTap: () => _showAbout(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppButton.outline(
          tr(ref, 'profile.syncQueue'),
          onPressed: () => context.push('/home/sync'),
          iconLeft: Icons.sync_rounded,
        ),
        const SizedBox(height: 12),
        AppButton.secondary(
          tr(ref, 'profile.signOut'),
          onPressed: () async {
            await ref.read(logoutProvider).call();
            if (context.mounted) context.go('/login');
          },
          iconLeft: Icons.logout_rounded,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _currentLanguageLabel(WidgetRef ref) {
    return ref.watch(localeProvider) == AppLocale.fr
        ? tr(ref, 'language.french')
        : tr(ref, 'language.english');
  }

  void _showAbout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(ref, 'app.name')),
        content: Text(tr(ref, 'profile.version')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(ref, 'common.ok')),
          ),
        ],
      ),
    );
  }
}

class _SupervisorTab extends ConsumerWidget {
  const _SupervisorTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(supervisorDashboardProvider);
    final approvalsAsync = ref.watch(pendingApprovalsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          tr(ref, 'profile.overview'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          tr(ref, 'profile.supervisorSubtitle'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        statsAsync.when(
          data: (stats) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                title: tr(ref, 'profile.totalPatients'),
                value: '${stats.totalPatients}',
                icon: Icons.people_outline,
                color: AppColors.primary,
              ),
              _StatCard(
                title: tr(ref, 'profile.highRisk'),
                value: '${stats.highRiskActive}',
                icon: Icons.warning_amber_rounded,
                color: AppColors.error,
              ),
              _StatCard(
                title: tr(ref, 'profile.escalations'),
                value: '${stats.pendingEscalations}',
                icon: Icons.notifications_active_outlined,
                color: AppColors.warning,
              ),
              _StatCard(
                title: tr(ref, 'profile.approvals'),
                value: '${approvalsAsync.valueOrNull?.length ?? 0}',
                icon: Icons.approval_outlined,
                color: AppColors.success,
              ),
            ],
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    tr(ref, 'profile.couldNotLoadStats'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          tr(ref, 'profile.quickActions'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton.primary(
                tr(ref, 'profile.allPatients'),
                iconLeft: Icons.people_outline,
                onPressed: () => context.push('/pregnancies'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton.outline(
                tr(ref, 'profile.approvals'),
                iconLeft: Icons.approval_outlined,
                onPressed: () => context.push('/approvals'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AppButton.secondary(
            tr(ref, 'profile.reports'),
            iconLeft: Icons.assessment_outlined,
            onPressed: () => context.push('/supervisor/reports'),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole? role;

  const _RoleBadge({this.role});

  @override
  Widget build(BuildContext context) {
    if (role == null) return const SizedBox.shrink();

    Color color;
    switch (role!) {
      case UserRole.admin:
        color = AppColors.accent;
      case UserRole.supervisor:
        color = AppColors.secondary;
      case UserRole.chw:
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role!.name.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
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
