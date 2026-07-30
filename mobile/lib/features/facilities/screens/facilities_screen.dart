import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../facility_repository.dart';

class FacilitiesScreen extends ConsumerWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Facilities')),
      body: facilitiesAsync.when(
        data: (facilities) => facilities.isEmpty
            ? const EmptyState(
                icon: Icons.local_hospital_outlined,
                title: 'No facilities found',
                subtitle: 'Facilities will appear here once added',
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
                              color: Color(0xFF7B776E),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/facilities/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
