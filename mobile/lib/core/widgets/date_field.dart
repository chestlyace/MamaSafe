import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'app_text_field.dart';
import '../../l10n/tr.dart';

/// Date picker field that auto-fills from a `computed` (suggested) value until
/// the user manually picks a different date, then "sticks". A revert link
/// restores the suggested value and re-enables auto-fill.
///
/// Mirrors the web `DateField` (frontend/src/components/DateField.jsx).
class DateField extends ConsumerStatefulWidget {
  final String label;
  final String? help;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  /// Suggested value; null when there is no source (e.g. no LMP yet).
  final DateTime? computed;
  final String? hint;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final IconData icon;

  const DateField({
    super.key,
    required this.label,
    this.help,
    required this.value,
    required this.onChanged,
    this.computed,
    this.hint,
    this.firstDate,
    this.lastDate,
    this.icon = Icons.date_range,
  });

  @override
  ConsumerState<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends ConsumerState<DateField> {
  bool _dirty = false;
  bool _showRevert = false;

  static String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  @override
  void didUpdateWidget(covariant DateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldComputed = oldWidget.computed;
    final newComputed = widget.computed;
    if (oldComputed == newComputed) return;

    if (_dirty) {
      return;
    }
    if (newComputed != null && newComputed != widget.value) {
      widget.onChanged(newComputed);
    } else if (oldComputed != null &&
        newComputed == null &&
        widget.value != null) {
      widget.onChanged(null);
    }
  }

  Future<void> _pick() async {
    final firstDate = widget.firstDate ?? DateTime(2020);
    final lastDate = widget.lastDate ?? DateTime(2030);
    final initial =
        widget.value ?? widget.computed ?? DateTime.now().add(const Duration(days: 28));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate)
          ? firstDate
          : initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      widget.onChanged(picked);
      if (widget.computed != null && _sameDate(picked, widget.computed!)) {
        _dirty = false;
        _showRevert = false;
      } else {
        _dirty = true;
        _showRevert = true;
      }
    });
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _revert() {
    final computed = widget.computed;
    if (computed == null) return;
    setState(() {
      _dirty = false;
      _showRevert = false;
      widget.onChanged(computed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final showRevert = _showRevert &&
        widget.computed != null &&
        (value == null || !_sameDate(value, widget.computed!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pick,
          child: AbsorbPointer(
            child: AppTextField(
              label: widget.label,
              help: widget.help,
              hint: widget.hint,
              controller: TextEditingController(
                text: value != null ? _fmt(value) : '',
              ),
              suffix: Icon(widget.icon, size: 20, color: AppColors.primary),
            ),
          ),
        ),
        if (showRevert)
          TextButton.icon(
            onPressed: _revert,
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
      ],
    );
  }
}
