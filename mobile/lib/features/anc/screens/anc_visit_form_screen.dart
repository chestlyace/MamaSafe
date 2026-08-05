import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/database.dart';
import '../../../core/utils/date_calc.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/validators/validators.dart';
import '../../../l10n/tr.dart';
import '../../maternity/maternity_repository.dart';
import '../anc_repository.dart';

class AncVisitFormScreen extends ConsumerStatefulWidget {
  final int pregnancyId;

  const AncVisitFormScreen({super.key, required this.pregnancyId});

  @override
  ConsumerState<AncVisitFormScreen> createState() => _AncVisitFormScreenState();
}

class _AncVisitFormScreenState extends ConsumerState<AncVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _visitNumberController = TextEditingController();
  final _gestationalAgeController = TextEditingController();
  final _weightController = TextEditingController();
  final _systolicBpController = TextEditingController();
  final _diastolicBpController = TextEditingController();
  final _fundalHeightController = TextEditingController();
  final _fetalHeartRateController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _visitDate = DateTime.now();
  DateTime? _nextVisitDate;
  String? _presentation;
  bool _oedema = false;
  bool _ttVaccine = false;
  bool _malariaProphylaxis = false;
  bool _ironSupplements = false;
  bool _saving = false;
  DateTime? _lmp;
  bool _gaDirty = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(pregnanciesProvider).value;
    if (current != null) _applyLmp(current);
    ref.listen(pregnanciesProvider, (prev, next) {
      _applyLmp(next.value);
    });
  }

  void _applyLmp(List<Pregnancy>? pregnancies) {
    if (pregnancies == null) return;
    Pregnancy? match;
    for (final p in pregnancies) {
      if (p.id == widget.pregnancyId) {
        match = p;
        break;
      }
    }
    final newLmp = match?.lmp != null ? DateTime.tryParse(match!.lmp!) : null;
    if (newLmp == _lmp) return;
    _lmp = newLmp;
    _applyAutoGa();
  }

  int? get _suggestedGa =>
      _lmp != null ? gestationalAge(_lmp!, _visitDate) : null;

  int? get _effectiveGa => int.tryParse(_gestationalAgeController.text);

  DateTime? get _suggestedNextVisit {
    final lmp = _lmp;
    final ga = _effectiveGa;
    if (lmp == null || ga == null) return null;
    return nextVisitDate(lmp, ga);
  }

  void _applyAutoGa() {
    if (_gaDirty) return;
    final suggested = _suggestedGa;
    if (suggested == null) return;
    _gestationalAgeController.text = '$suggested';
  }

  void _onGaChanged(String v) {
    setState(() {
      final suggested = _suggestedGa;
      if (v.isNotEmpty && suggested != null && v == '$suggested') {
        _gaDirty = false;
      } else {
        _gaDirty = true;
      }
    });
  }

  void _revertGa() {
    final suggested = _suggestedGa;
    if (suggested == null) return;
    setState(() {
      _gaDirty = false;
      _gestationalAgeController.text = '$suggested';
    });
  }

  @override
  void dispose() {
    _visitNumberController.dispose();
    _gestationalAgeController.dispose();
    _weightController.dispose();
    _systolicBpController.dispose();
    _diastolicBpController.dispose();
    _fundalHeightController.dispose();
    _fetalHeartRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = CreateAncVisitData(
      pregnancyId: widget.pregnancyId,
      visitNumber: int.tryParse(_visitNumberController.text) ?? 1,
      date: _visitDate,
      gestationalAgeWeeks: int.tryParse(_gestationalAgeController.text),
      weight: double.tryParse(_weightController.text),
      systolicBp: double.tryParse(_systolicBpController.text),
      diastolicBp: double.tryParse(_diastolicBpController.text),
      fundalHeight: double.tryParse(_fundalHeightController.text),
      fetalHeartRate: double.tryParse(_fetalHeartRateController.text),
      presentation: _presentation,
      urinalysis: null,
      oedema: _oedema,
      ttVaccine: _ttVaccine,
      malariaProphylaxis: _malariaProphylaxis,
      ironSupplements: _ironSupplements,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      nextVisitDate: _nextVisitDate,
    );

    try {
      await ref.read(createAncVisitProvider.notifier).create(data);
      if (mounted) {
        ref.invalidate(ancVisitsProvider(widget.pregnancyId));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(ref, 'anc.saveFailed', {'error': '$e'}))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'anc.recordNew'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: tr(ref, 'anc.visitNumber'),
                    help: tr(ref, 'anc.visitNumberHelp'),
                    hint: tr(ref, 'anc.visitNumberHint'),
                    controller: _visitNumberController,
                    keyboardType: TextInputType.number,
                    validator: (v) => positiveNumberValidator(v, fieldName: tr(ref, 'anc.visitNumber'), ref: ref),
                  ),
                  const SizedBox(height: 16),
                  DateField(
                    label: tr(ref, 'anc.date'),
                    help: tr(ref, 'anc.dateHelp'),
                    hint: tr(ref, 'anc.dateHint'),
                    value: _visitDate,
                    onChanged: (dt) => setState(() {
                      _visitDate = dt ?? DateTime.now();
                      _applyAutoGa();
                    }),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: tr(ref, 'anc.gestationalAgeWeeks'),
                    help: tr(ref, 'anc.gestationalAgeHelp'),
                    hint: tr(ref, 'anc.gestationalAgeHint'),
                    controller: _gestationalAgeController,
                    keyboardType: TextInputType.number,
                  ),
                  if (_gaDirty && _suggestedGa != null &&
                      _gestationalAgeController.text != '$_suggestedGa')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _revertGa,
                        icon: const Icon(Icons.undo, size: 16),
                        label: Text(tr(ref, 'common.revertToSuggested')),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: AppColors.primary,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: tr(ref, 'anc.weightKg'),
                    help: tr(ref, 'anc.weightHelp'),
                    hint: tr(ref, 'anc.weightHint'),
                    controller: _weightController,
                 keyboardType: TextInputType.number,
               ),
              const SizedBox(height: 16),
              Row(
                children: [
Expanded(
                     child: AppTextField(
                       label: tr(ref, 'anc.systolicBp'),
                       help: tr(ref, 'anc.systolicBpHelp'),
                       hint: tr(ref, 'anc.bpHint120'),
                       controller: _systolicBpController,
                       keyboardType: TextInputType.number,
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: AppTextField(
                       label: tr(ref, 'anc.diastolicBp'),
                       help: tr(ref, 'anc.diastolicBpHelp'),
                       hint: tr(ref, 'anc.bpHint80'),
                       controller: _diastolicBpController,
                       keyboardType: TextInputType.number,
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'anc.fundalHeightCm'),
                 help: tr(ref, 'anc.fundalHeightHelp'),
                 hint: tr(ref, 'anc.fundalHeightHint'),
                 controller: _fundalHeightController,
                 keyboardType: TextInputType.number,
               ),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'anc.fetalHeartRateBpm'),
                 help: tr(ref, 'anc.fetalHeartRateHelp'),
                 hint: tr(ref, 'anc.fetalHeartRateHint'),
                 controller: _fetalHeartRateController,
                 keyboardType: TextInputType.number,
               ),
               const SizedBox(height: 16),
               DropdownButtonFormField<String>(
                 initialValue: _presentation,
                 decoration: InputDecoration(
                   labelText: tr(ref, 'anc.presentation'),
                   border: const OutlineInputBorder(
                     borderRadius: BorderRadius.all(Radius.circular(12)),
                   ),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                 ),
                 items: [
                   DropdownMenuItem(value: 'cephalic', child: Text(tr(ref, 'anc.presentationCephalic'))),
                   DropdownMenuItem(value: 'breech', child: Text(tr(ref, 'anc.presentationBreech'))),
                   DropdownMenuItem(value: 'transverse', child: Text(tr(ref, 'anc.presentationTransverse'))),
                 ],
                 onChanged: (v) => setState(() => _presentation = v),
               ),
               const SizedBox(height: 16),
_checkbox(tr(ref, 'anc.oedema'), _oedema, (v) => setState(() => _oedema = v ?? false)),
               _checkbox(tr(ref, 'anc.ttVaccineGiven'), _ttVaccine, (v) => setState(() => _ttVaccine = v ?? false)),
               _checkbox(tr(ref, 'anc.malariaProphylaxis'), _malariaProphylaxis, (v) => setState(() => _malariaProphylaxis = v ?? false)),
               _checkbox(tr(ref, 'anc.ironSupplements'), _ironSupplements, (v) => setState(() => _ironSupplements = v ?? false)),
               const SizedBox(height: 16),
               AppTextField(
                 label: tr(ref, 'anc.notes'),
                 help: tr(ref, 'anc.notesHelp'),
                 hint: tr(ref, 'anc.notesHint'),
                 controller: _notesController,
                 maxLines: 3,
               ),
               const SizedBox(height: 16),
               DateField(
                 label: tr(ref, 'anc.nextVisit'),
                 help: tr(ref, 'anc.nextVisitHelp'),
                 hint: tr(ref, 'anc.dateHint'),
                 value: _nextVisitDate,
                 onChanged: (dt) => setState(() => _nextVisitDate = dt),
                 computed: _suggestedNextVisit,
               ),
               const SizedBox(height: 16),
               DateField(
                 label: tr(ref, 'anc.nextVisit'),
                 help: tr(ref, 'anc.nextVisitHelp'),
                 hint: tr(ref, 'anc.dateHint'),
                 value: _nextVisitDate,
                 onChanged: (dt) => setState(() => _nextVisitDate = dt),
                 computed: _suggestedNextVisit,
               ),
              const SizedBox(height: 24),
              AppButton.primary(
                tr(ref, 'anc.save'),
                loading: _saving,
                onPressed: _save,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
