import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validators/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/storage/database.dart';
import '../../../l10n/tr.dart';
import '../delivery_repository.dart';

class DeliveryDetailScreen extends ConsumerWidget {
  final int deliveryId;
  final int patientId;

  const DeliveryDetailScreen({
    super.key,
    required this.deliveryId,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryAsync = ref.watch(deliveryByIdProvider(deliveryId));
    final newbornsAsync = ref.watch(newbornsProvider(deliveryId));
    final visitsAsync = ref.watch(postnatalVisitsProvider(deliveryId));
    final mentalHealthAsync = ref.watch(mentalHealthProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'delivery.details'))),
      body: deliveryAsync.when(
        data: (delivery) {
          if (delivery == null) {
            return Center(child: Text(tr(ref, 'delivery.notFound')));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _deliveryInfoCard(ref, delivery),
                const SizedBox(height: 16),
                _sectionHeader(tr(ref, 'delivery.newborns'), Icons.child_care),
                const SizedBox(height: 8),
                newbornsAsync.when(
                  data: (newborns) => _newbornsSection(ref, context, newborns),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('${tr(ref, 'common.error')}: $e'),
                ),
                const SizedBox(height: 16),
                AppButton.outline(
                  tr(ref, 'delivery.addNewborn'),
                  iconLeft: Icons.person_add,
                  onPressed: () => _showAddNewbornDialog(context, ref),
                  width: double.infinity,
                ),
                const SizedBox(height: 24),
                _sectionHeader(tr(ref, 'postnatal.title'), Icons.receipt_long),
                const SizedBox(height: 8),
                visitsAsync.when(
                  data: (visits) => _visitsSection(ref, context, visits),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('${tr(ref, 'common.error')}: $e'),
                ),
                const SizedBox(height: 16),
                AppButton.outline(
                  tr(ref, 'delivery.addPostnatalVisit'),
                  iconLeft: Icons.add_circle_outline,
                  onPressed: () => context.push(
                    '/home/postnatal-visits/new',
                    extra: {'deliveryId': deliveryId},
                  ),
                  width: double.infinity,
                ),
                const SizedBox(height: 24),
                _sectionHeader(tr(ref, 'delivery.mentalHealth'), Icons.favorite_border),
                const SizedBox(height: 8),
                mentalHealthAsync.when(
                  data: (screens) => _mentalHealthSection(ref, context, screens),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('${tr(ref, 'common.error')}: $e'),
                ),
                const SizedBox(height: 16),
                AppButton.outline(
                  tr(ref, 'delivery.addMentalHealthScreen'),
                  iconLeft: Icons.add_circle_outline,
                  onPressed: () => context.push(
                    '/home/mental-health/new',
                    extra: {'patientId': patientId, 'deliveryId': deliveryId},
                  ),
                  width: double.infinity,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          error: e,
          onRetry: () => ref.invalidate(deliveryByIdProvider(deliveryId)),
        ),
      ),
    );
  }

  Widget _deliveryInfoCard(WidgetRef ref, Delivery delivery) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(ref, 'delivery.infoTitle'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _infoRow(tr(ref, 'delivery.date'), '${delivery.date.day}/${delivery.date.month}/${delivery.date.year}'),
          const Divider(height: 24),
          _infoRow(tr(ref, 'delivery.location'), delivery.location),
          const Divider(height: 24),
          _infoRow(tr(ref, 'delivery.deliveredBy'), delivery.deliveredBy),
          if (delivery.complications != null) ...[
            const Divider(height: 24),
            _infoRow(tr(ref, 'delivery.complications'), delivery.complications!),
          ],
        ],
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

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _newbornsSection(WidgetRef ref, BuildContext context, List<Newborn> newborns) {
    if (newborns.isEmpty) {
      return EmptyState(
        icon: Icons.child_care_outlined,
        title: tr(ref, 'delivery.noNewbornsTitle'),
        subtitle: tr(ref, 'delivery.noNewbornsSubtitle'),
      );
    }
    return Column(
      children: newborns.map((n) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          onTap: () => context.push(
            '/home/newborns/${n.id}',
            extra: {'newbornId': n.id},
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                n.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (n.sex != null) ...[
                    Text(n.sex!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(width: 16),
                  ],
                  if (n.birthWeight != null)
                    Text('${n.birthWeight!.toStringAsFixed(2)} kg',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _visitsSection(WidgetRef ref, BuildContext context, List<PostnatalVisit> visits) {
    if (visits.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: tr(ref, 'delivery.noPostnatalVisitsTitle'),
        subtitle: tr(ref, 'delivery.noPostnatalVisitsSubtitle'),
      );
    }
    return Column(
      children: visits.map((v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    tr(ref, 'postnatal.visitNumberWith', {'number': '${v.visitNumber}'}),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${v.visitDate.day}/${v.visitDate.month}/${v.visitDate.year}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (v.motherStatus != null)
                _visitRow(tr(ref, 'postnatal.motherStatus'), v.motherStatus!),
              if (v.newbornWeight != null)
                _visitRow(tr(ref, 'postnatal.newbornWeight'), '${v.newbornWeight!.toStringAsFixed(2)} kg'),
              if (v.breastfeedingStatus != null)
                _visitRow(tr(ref, 'postnatal.breastfeedingStatus'), v.breastfeedingStatus!),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _visitRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: ',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mentalHealthSection(WidgetRef ref, BuildContext context, List<MentalHealthScreen> screens) {
    final deliveryScreens = screens.where((s) => s.deliveryId == deliveryId).toList();
    if (deliveryScreens.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: tr(ref, 'delivery.noMentalHealthTitle'),
        subtitle: tr(ref, 'delivery.noMentalHealthSubtitle'),
      );
    }
    return Column(
      children: deliveryScreens.map((s) {
        final riskColor = _riskColor(s.riskLevel);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${tr(ref, 'mentalhealth.score')}: ${s.totalScore}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tr(ref, 'risk.${s.riskLevel}').toUpperCase(),
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _riskColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return AppColors.error;
      case 'moderate':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showAddNewbornDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    final apgarController = TextEditingController();
    String? selectedSex;
    bool? crying;
    bool? breastfeeding;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) => SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(ref, 'newborn.add'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: tr(ref, 'newborn.name'),
                      hint: tr(ref, 'newborn.nameHint'),
                      controller: nameController,
                      validator: (v) => requiredValidator(v, fieldName: tr(ref, 'newborn.name'), ref: ref),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSex,
                      decoration: InputDecoration(
                        label: Text(tr(ref, 'newborn.sex')),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'Male', child: Text(tr(ref, 'common.male'))),
                        DropdownMenuItem(
                            value: 'Female',
                            child: Text(tr(ref, 'common.female'))),
                      ],
                      onChanged: (v) => setSheetState(() => selectedSex = v),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: tr(ref, 'newborn.birthWeight'),
                      hint: tr(ref, 'newborn.birthWeightHint'),
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: tr(ref, 'newborn.apgar'),
                      hint: tr(ref, 'newborn.apgarHint'),
                      controller: apgarController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: Text(tr(ref, 'newborn.crying')),
                      value: crying ?? false,
                      onChanged: (v) => setSheetState(() => crying = v),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: Text(tr(ref, 'newborn.breastfeeding')),
                      value: breastfeeding ?? false,
                      onChanged: (v) => setSheetState(() => breastfeeding = v),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        tr(ref, 'newborn.save'),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final data = CreateNewbornData(
                            deliveryId: deliveryId,
                            name: nameController.text.trim(),
                            sex: selectedSex,
                            birthWeight: double.tryParse(weightController.text),
                            apgarScore: int.tryParse(apgarController.text),
                            crying: crying,
                            breastfeeding: breastfeeding,
                            status: 'active',
                          );
                          try {
                            await ref.read(createNewbornProvider.notifier).create(data);
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                            ref.invalidate(newbornsProvider(deliveryId));
                          } catch (e) {
                            if (!sheetContext.mounted) return;
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text(tr(ref, 'newborn.saveFailed', {'error': '$e'}))),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
