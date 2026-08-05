import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/tr.dart';
import '../facility_repository.dart';

class FacilitiesTabView extends ConsumerWidget {
  const FacilitiesTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);

    return facilitiesAsync.when(
      data: (facilities) => facilities.isEmpty
          ? EmptyState(
              icon: Icons.local_hospital_outlined,
              title: tr(ref, 'facility.emptyTitle'),
              subtitle: tr(ref, 'facility.emptySubtitle'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: facilities.length,
              itemBuilder: (context, index) {
                final facility = facilities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${facility.district} — ${facility.location}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(error: e, onRetry: () => ref.invalidate(facilitiesProvider)),
    );
  }
}

class FacilitiesScreen extends ConsumerWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'facility.title'))),
      body: const FacilitiesTabView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/facilities/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
