import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/date_field.dart';
import '../../../l10n/tr.dart';
import '../schedule_repository.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final int? pregnancyId;

  const ScheduleFormScreen({super.key, this.pregnancyId});

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _visitNumberController = TextEditingController();
  DateTime? _selectedDate;
  bool _saving = false;

  @override
  void dispose() {
    _visitNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final visitNumberStr = _visitNumberController.text.trim();
    if (visitNumberStr.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'schedule.fillAllFields')), backgroundColor: AppColors.error),
      );
      return;
    }

    final visitNumber = int.tryParse(visitNumberStr);
    if (visitNumber == null || visitNumber < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'schedule.validVisitNumber')), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(createScheduleProvider.notifier).create(
        CreateScheduledVisitData(
          pregnancyId: widget.pregnancyId ?? 0,
          visitNumber: visitNumber,
          scheduledDate: _selectedDate!,
        ),
      );
      if (!mounted) return;
      ref.invalidate(upcomingVisitsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'schedule.scheduled')), backgroundColor: AppColors.success),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'schedule.failed', {'error': '$e'})), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'schedule.new'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: tr(ref, 'schedule.visitNumber'),
              hint: tr(ref, 'schedule.visitNumberHint'),
              keyboardType: TextInputType.number,
              controller: _visitNumberController,
            ),
            const SizedBox(height: 16),
            DateField(
              label: tr(ref, 'schedule.date'),
              hint: tr(ref, 'schedule.selectDate'),
              value: _selectedDate,
              onChanged: (dt) => setState(() => _selectedDate = dt),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                _saving ? tr(ref, 'common.saving') : tr(ref, 'schedule.new'),
                loading: _saving,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
