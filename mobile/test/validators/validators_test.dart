import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/core/validators/validators.dart';

void main() {
  group('requiredValidator', () {
    test('returns error for null value', () {
      expect(requiredValidator(null), 'This field is required');
    });

    test('returns error for empty string', () {
      expect(requiredValidator(''), 'This field is required');
    });

    test('returns error for whitespace only', () {
      expect(requiredValidator('   '), 'This field is required');
    });

    test('returns null for valid value', () {
      expect(requiredValidator('hello'), isNull);
    });

    test('uses custom field name', () {
      expect(
        requiredValidator(null, fieldName: 'Email'),
        'Email is required',
      );
    });
  });

  group('emailValidator', () {
    test('returns error for null', () {
      expect(emailValidator(null), 'Email is required');
    });

    test('returns error for empty', () {
      expect(emailValidator(''), 'Email is required');
    });

    test('returns error for missing @', () {
      expect(emailValidator('notanemail'), 'Enter a valid email');
    });

    test('returns error for missing domain', () {
      expect(emailValidator('user@'), 'Enter a valid email');
    });

    test('returns error for missing tld', () {
      expect(emailValidator('user@domain'), 'Enter a valid email');
    });

    test('returns null for simple valid email', () {
      expect(emailValidator('user@example.com'), isNull);
    });

    test('returns null for email with subdomain', () {
      expect(emailValidator('user@mail.example.com'), isNull);
    });

    test('returns null for email with plus', () {
      expect(emailValidator('user+tag@example.com'), isNull);
    });

    test('trims whitespace', () {
      expect(emailValidator('  user@example.com  '), isNull);
    });
  });

  group('ageValidator', () {
    test('returns error for null', () {
      expect(ageValidator(null), 'Age is required');
    });

    test('returns error for empty', () {
      expect(ageValidator(''), 'Age is required');
    });

    test('returns error for non-numeric', () {
      expect(ageValidator('abc'), 'Enter a valid age');
    });

    test('returns error for too young (below 12)', () {
      expect(ageValidator('5'), 'Age must be at least 12');
    });

    test('returns error for too old (above 60)', () {
      expect(ageValidator('99'), 'Age must be at most 60');
    });

    test('returns null for valid age', () {
      expect(ageValidator('30'), isNull);
    });

    test('returns null for boundary min age', () {
      expect(ageValidator('12'), isNull);
    });

    test('returns null for boundary max age', () {
      expect(ageValidator('60'), isNull);
    });

    test('uses custom range', () {
      expect(ageValidator('2', min: 0, max: 5), isNull);
      expect(ageValidator('10', min: 0, max: 5), 'Age must be at most 5');
    });
  });

  group('bloodPressureValidator', () {
    test('returns error for null', () {
      expect(bloodPressureValidator(null), 'Blood pressure is required');
    });

    test('returns error for empty', () {
      expect(bloodPressureValidator(''), 'Blood pressure is required');
    });

    test('returns error for non-numeric', () {
      expect(bloodPressureValidator('abc'), 'Enter a valid number');
    });

    test('returns error for too low', () {
      expect(
        bloodPressureValidator('10'),
        'Blood pressure must be at least 30',
      );
    });

    test('returns error for too high', () {
      expect(
        bloodPressureValidator('300'),
        'Blood pressure must be at most 280',
      );
    });

    test('returns null for valid systolic', () {
      expect(bloodPressureValidator('120'), isNull);
    });

    test('returns null for valid diastolic', () {
      expect(bloodPressureValidator('80'), isNull);
    });

    test('returns null with decimal', () {
      expect(bloodPressureValidator('120.5'), isNull);
    });
  });

  group('bloodSugarValidator', () {
    test('returns error for null', () {
      expect(bloodSugarValidator(null), 'Blood sugar is required');
    });

    test('returns error for empty', () {
      expect(bloodSugarValidator(''), 'Blood sugar is required');
    });

    test('returns error for non-numeric', () {
      expect(bloodSugarValidator('abc'), 'Enter a valid number');
    });

    test('returns error for too low', () {
      expect(bloodSugarValidator('10'), 'Blood sugar must be at least 20');
    });

    test('returns error for too high', () {
      expect(bloodSugarValidator('700'), 'Blood sugar must be at most 600');
    });

    test('returns null for normal fasting', () {
      expect(bloodSugarValidator('80'), isNull);
    });

    test('returns null for high but valid', () {
      expect(bloodSugarValidator('400'), isNull);
    });
  });

  group('positiveNumberValidator', () {
    test('returns error for null', () {
      expect(positiveNumberValidator(null), 'Value is required');
    });

    test('returns error for empty', () {
      expect(positiveNumberValidator(''), 'Value is required');
    });

    test('returns error for zero', () {
      expect(positiveNumberValidator('0'), 'Value must be positive');
    });

    test('returns error for negative', () {
      expect(positiveNumberValidator('-5'), 'Value must be positive');
    });

    test('returns error for non-numeric', () {
      expect(positiveNumberValidator('abc'), 'Enter a valid number');
    });

    test('returns null for positive integer', () {
      expect(positiveNumberValidator('30'), isNull);
    });

    test('returns error for decimal without allowDecimal', () {
      expect(positiveNumberValidator('30.5'), 'Enter a valid number');
    });

    test('returns null for decimal with allowDecimal', () {
      expect(positiveNumberValidator('36.6', allowDecimal: true), isNull);
    });

    test('uses custom field name', () {
      expect(
        positiveNumberValidator('', fieldName: 'Heart Rate'),
        'Heart Rate is required',
      );
    });
  });
}
