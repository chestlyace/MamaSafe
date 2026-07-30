String? requiredValidator(String? value, {String fieldName = 'This field'}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
    return 'Enter a valid email';
  }
  return null;
}

String? phoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = value.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
  if (digits.length < 6 || digits.length > 15) {
    return 'Enter a valid phone number';
  }
  return null;
}

String? numberValidator(String? value, {double? min, double? max, String? fieldName}) {
  if (value == null || value.trim().isEmpty) {
    return '${fieldName ?? 'Value'} is required';
  }
  final n = double.tryParse(value) ?? int.tryParse(value);
  if (n == null) return 'Enter a valid number';
  if (min != null && n < min) return '${fieldName ?? 'Value'} must be at least $min';
  if (max != null && n > max) return '${fieldName ?? 'Value'} must be at most $max';
  return null;
}

String? ageValidator(String? value, {int min = 12, int max = 60}) {
  if (value == null || value.isEmpty) return 'Age is required';
  final age = int.tryParse(value);
  if (age == null) return 'Enter a valid age';
  if (age < min) return 'Age must be at least $min';
  if (age > max) return 'Age must be at most $max';
  return null;
}

String? bloodPressureValidator(String? value, {double min = 30, double max = 280}) {
  if (value == null || value.isEmpty) return 'Blood pressure is required';
  final bp = double.tryParse(value);
  if (bp == null) return 'Enter a valid number';
  if (bp < min) return 'Blood pressure must be at least ${min.toInt()}';
  if (bp > max) return 'Blood pressure must be at most ${max.toInt()}';
  return null;
}

String? bloodSugarValidator(String? value, {double min = 20, double max = 600}) {
  if (value == null || value.isEmpty) return 'Blood sugar is required';
  final bs = double.tryParse(value);
  if (bs == null) return 'Enter a valid number';
  if (bs < min) return 'Blood sugar must be at least ${min.toInt()}';
  if (bs > max) return 'Blood sugar must be at most ${max.toInt()}';
  return null;
}

String? positiveNumberValidator(String? value, {String fieldName = 'Value', bool allowDecimal = false}) {
  if (value == null || value.isEmpty) return '$fieldName is required';
  final parsed = allowDecimal ? double.tryParse(value) : int.tryParse(value);
  if (parsed == null) return 'Enter a valid number';
  if (parsed <= 0) return '$fieldName must be positive';
  return null;
}

String? heartRateValidator(String? value) {
  if (value == null || value.isEmpty) return 'Heart rate is required';
  final hr = double.tryParse(value);
  if (hr == null) return 'Enter a valid number';
  if (hr < 30) return 'Heart rate seems too low';
  if (hr > 250) return 'Heart rate seems too high';
  return null;
}

String? bodyTempValidator(String? value) {
  if (value == null || value.isEmpty) return 'Body temperature is required';
  final temp = double.tryParse(value);
  if (temp == null) return 'Enter a valid number';
  if (temp < 34) return 'Temperature seems too low';
  if (temp > 43) return 'Temperature seems too high';
  return null;
}
