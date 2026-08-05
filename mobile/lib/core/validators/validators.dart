import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/tr.dart';

String _apply(String value, Map<String, String> args) {
  if (args.isEmpty) return value;
  return args.entries
      .fold(value, (v, e) => v.replaceAll('{${e.key}}', e.value));
}

String _t(WidgetRef? ref, String key, [Map<String, String> args = const {}]) {
  if (ref == null) return _apply(enStrings[key] ?? key, args);
  return tr(ref, key, args);
}

String? requiredValidator(String? value,
    {String fieldName = 'This field', WidgetRef? ref}) {
  if (value == null || value.trim().isEmpty) {
    return _t(ref, 'validator.required', {'field': fieldName});
  }
  return null;
}

String? inviteCodeValidator(String? value, {WidgetRef? ref}) {
  if (value == null || value.trim().isEmpty) {
    return _t(ref, 'validator.required', {'field': _t(ref, 'auth.inviteCode')});
  }
  if (!RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$')
      .hasMatch(value.trim().toUpperCase())) {
    return _t(ref, 'validator.inviteCodeInvalid');
  }
  return null;
}

String? emailValidator(String? value, {WidgetRef? ref}) {
  if (value == null || value.trim().isEmpty) {
    return _t(ref, 'validator.emailRequired');
  }
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
    return _t(ref, 'validator.emailInvalid');
  }
  return null;
}

String? phoneValidator(String? value, {WidgetRef? ref}) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = value.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
  if (digits.length < 6 || digits.length > 15) {
    return _t(ref, 'validator.phoneInvalid');
  }
  return null;
}

String? numberValidator(String? value,
    {double? min, double? max, String? fieldName, WidgetRef? ref}) {
  if (value == null || value.trim().isEmpty) {
    return _t(ref, 'validator.required', {'field': fieldName ?? 'Value'});
  }
  final n = double.tryParse(value) ?? int.tryParse(value);
  if (n == null) return _t(ref, 'validator.numberInvalid');
  if (min != null && n < min) {
    return _t(
        ref, 'validator.min', {'field': fieldName ?? 'Value', 'min': '$min'});
  }
  if (max != null && n > max) {
    return _t(
        ref, 'validator.max', {'field': fieldName ?? 'Value', 'max': '$max'});
  }
  return null;
}

String? ageValidator(String? value,
    {int min = 12, int max = 60, WidgetRef? ref}) {
  if (value == null || value.isEmpty) return _t(ref, 'validator.ageRequired');
  final age = int.tryParse(value);
  if (age == null) return _t(ref, 'validator.ageInvalid');
  if (age < min) return _t(ref, 'validator.ageMin', {'min': '$min'});
  if (age > max) return _t(ref, 'validator.ageMax', {'max': '$max'});
  return null;
}

String? bloodPressureValidator(String? value,
    {double min = 30, double max = 280, WidgetRef? ref}) {
  if (value == null || value.isEmpty) return _t(ref, 'validator.bpRequired');
  final bp = double.tryParse(value);
  if (bp == null) return _t(ref, 'validator.numberInvalid');
  if (bp < min) return _t(ref, 'validator.bpMin', {'min': '${min.toInt()}'});
  if (bp > max) return _t(ref, 'validator.bpMax', {'max': '${max.toInt()}'});
  return null;
}

String? bloodSugarValidator(String? value,
    {double min = 20, double max = 600, WidgetRef? ref}) {
  if (value == null || value.isEmpty) return _t(ref, 'validator.bsRequired');
  final bs = double.tryParse(value);
  if (bs == null) return _t(ref, 'validator.numberInvalid');
  if (bs < min) return _t(ref, 'validator.bsMin', {'min': '${min.toInt()}'});
  if (bs > max) return _t(ref, 'validator.bsMax', {'max': '${max.toInt()}'});
  return null;
}

String? positiveNumberValidator(String? value,
    {String fieldName = 'Value', bool allowDecimal = false, WidgetRef? ref}) {
  if (value == null || value.isEmpty) {
    return _t(ref, 'validator.required', {'field': fieldName});
  }
  final parsed = allowDecimal ? double.tryParse(value) : int.tryParse(value);
  if (parsed == null) return _t(ref, 'validator.numberInvalid');
  if (parsed <= 0) return _t(ref, 'validator.positive', {'field': fieldName});
  return null;
}

String? heartRateValidator(String? value, {WidgetRef? ref}) {
  if (value == null || value.isEmpty) return _t(ref, 'validator.hrRequired');
  final hr = double.tryParse(value);
  if (hr == null) return _t(ref, 'validator.numberInvalid');
  if (hr < 30) return _t(ref, 'validator.hrLow');
  if (hr > 250) return _t(ref, 'validator.hrHigh');
  return null;
}

String? bodyTempValidator(String? value, {WidgetRef? ref}) {
  if (value == null || value.isEmpty) return _t(ref, 'validator.tempRequired');
  final temp = double.tryParse(value);
  if (temp == null) return _t(ref, 'validator.numberInvalid');
  if (temp < 34) return _t(ref, 'validator.tempLow');
  if (temp > 43) return _t(ref, 'validator.tempHigh');
  return null;
}
