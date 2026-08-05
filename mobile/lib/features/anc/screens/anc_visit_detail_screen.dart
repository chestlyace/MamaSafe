import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/storage/database.dart';
import '../../../l10n/tr.dart';
import '../anc_repository.dart';

class AncVisitDetailScreen extends ConsumerWidget {
  final int visitId;

  const AncVisitDetailScreen({super.key, required this.visitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(ancVisitsProvider(0));

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'anc.detailTitle'))),
      body: visitsAsync.when(
        data: (visits) {
          final visit = visits.where((v) => v.id == visitId).firstOrNull;
          if (visit == null) {
            return Center(child: Text(tr(ref, 'anc.visitNotFound')));
          }
          return _buildContent(context, ref, visit);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(error: e),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AncVisit visit) {
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
                  tr(ref, 'anc.visitInfo'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _infoRow(tr(ref, 'anc.visitNumber'), '#${visit.visitNumber}'),
                const Divider(height: 20),
                _infoRow(tr(ref, 'anc.dateShort'), '${visit.date.day}/${visit.date.month}/${visit.date.year}'),
                if (visit.gestationalAgeWeeks != null) ...[
                  const Divider(height: 20),
                  _infoRow(tr(ref, 'anc.gestationalAgeWeeks'), tr(ref, 'anc.gestationalAgeWeeksValue', {'weeks': '${visit.gestationalAgeWeeks}'})),
                ],
                if (visit.presentation != null) ...[
                  const Divider(height: 20),
                  _infoRow(tr(ref, 'anc.presentation'), _presentationLabel(ref, visit.presentation!)),
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
                  tr(ref, 'anc.vitals'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _vitalRow(
                  tr(ref, 'anc.bloodPressure'),
                  visit.systolicBp != null && visit.diastolicBp != null
                      ? '${visit.systolicBp!.toStringAsFixed(0)}/${visit.diastolicBp!.toStringAsFixed(0)} mmHg'
                      : tr(ref, 'anc.notRecorded'),
                ),
                if (visit.fetalHeartRate != null) ...[
                  const Divider(height: 20),
                  _vitalRow(tr(ref, 'anc.fetalHeartRate'), '${visit.fetalHeartRate!.toStringAsFixed(0)} bpm'),
                ],
                if (visit.weight != null) ...[
                  const Divider(height: 20),
                  _vitalRow(tr(ref, 'anc.weight'), '${visit.weight!.toStringAsFixed(1)} kg'),
                ],
                if (visit.fundalHeight != null) ...[
                  const Divider(height: 20),
                  _vitalRow(tr(ref, 'anc.fundalHeight'), '${visit.fundalHeight!.toStringAsFixed(1)} cm'),
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
                  tr(ref, 'anc.medications'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _statusRow(ref, tr(ref, 'anc.ttVaccine'), visit.ttVaccine),
                const Divider(height: 16),
                _statusRow(ref, tr(ref, 'anc.malariaProphylaxis'), visit.malariaProphylaxis),
                const Divider(height: 16),
                _statusRow(ref, tr(ref, 'anc.ironSupplements'), visit.ironSupplements),
                if (visit.oedema != null) ...[
                  const Divider(height: 16),
                  _statusRow(ref, tr(ref, 'anc.oedema'), visit.oedema),
                ],
              ],
            ),
          ),
          if (visit.notes != null && visit.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(ref, 'anc.notes'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    visit.notes!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (visit.nextVisitDate != null) ...[
            const SizedBox(height: 16),
            AppCard(
              variant: AppCardVariant.outlined,
              child: Row(
                children: [
                  const Icon(Icons.event, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(ref, 'anc.nextVisit'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${visit.nextVisitDate!.day}/${visit.nextVisitDate!.month}/${visit.nextVisitDate!.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _presentationLabel(WidgetRef ref, String presentation) {
    switch (presentation) {
      case 'cephalic':
        return tr(ref, 'anc.presentationCephalic');
      case 'breech':
        return tr(ref, 'anc.presentationBreech');
      case 'transverse':
        return tr(ref, 'anc.presentationTransverse');
      default:
        return presentation;
    }
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _vitalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusRow(WidgetRef ref, String label, bool? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value == true ? Icons.check_circle : Icons.cancel,
              size: 20,
              color: value == true ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              value == true ? tr(ref, 'common.yes') : tr(ref, 'common.no'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: value == true ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
