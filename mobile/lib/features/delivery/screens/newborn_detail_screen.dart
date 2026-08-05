import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/storage/database.dart';
import '../../../core/storage/database_provider.dart';
import '../../../l10n/tr.dart';

class NewbornDetailScreen extends ConsumerWidget {
  final int newbornId;

  const NewbornDetailScreen({super.key, required this.newbornId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'newborn.details'))),
      body: FutureBuilder<Newborn>(
        future: (db.select(db.newborns)..where((t) => t.id.equals(newbornId)))
            .getSingle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return AppErrorWidget(
              error: snapshot.error ?? tr(ref, 'newborn.notFound'),
            );
          }
          final n = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(ref, 'newborn.information'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    const SizedBox(height: 16),
                      _infoRow(tr(ref, 'newborn.name'), n.name),
                      const Divider(height: 24),
                      _infoRow(tr(ref, 'newborn.sex'), n.sex ?? tr(ref, 'newborn.notSpecified')),
                      const Divider(height: 24),
                      _infoRow(
                        tr(ref, 'newborn.birthWeight'),
                        n.birthWeight != null
                            ? '${n.birthWeight!.toStringAsFixed(2)} kg'
                            : tr(ref, 'newborn.notRecorded'),
                      ),
                      const Divider(height: 24),
                      _infoRow(
                        tr(ref, 'newborn.apgar'),
                        n.apgarScore?.toString() ?? tr(ref, 'newborn.notRecorded'),
                      ),
                      const Divider(height: 24),
                      _infoRow(
                        tr(ref, 'newborn.crying'),
                        n.crying == true ? tr(ref, 'common.yes') : n.crying == false ? tr(ref, 'common.no') : tr(ref, 'newborn.notRecorded'),
                      ),
                      const Divider(height: 24),
                      _infoRow(
                        tr(ref, 'newborn.breastfeeding'),
                        n.breastfeeding == true ? tr(ref, 'common.yes') : n.breastfeeding == false ? tr(ref, 'common.no') : tr(ref, 'newborn.notRecorded'),
                      ),
                      const Divider(height: 24),
                      _infoRow(tr(ref, 'newborn.status'), n.status),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    tr(ref, 'newborn.viewGrowthRecords'),
                    iconLeft: Icons.timeline,
                    onPressed: () => context.push(
                      '/home/growth',
                      extra: {'childName': n.name, 'newbornId': n.id},
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
