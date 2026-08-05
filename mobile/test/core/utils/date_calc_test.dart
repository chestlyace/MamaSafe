import 'package:flutter_test/flutter_test.dart';

import 'package:mamasafe/core/utils/date_calc.dart';

void main() {
  DateTime d(String iso) => DateTime.parse(iso);

  group('eddFromLmp (Naegele, matches backend relativedelta)', () {
    final cases = <String, String>{
      '2024-01-15': '2024-10-22',
      '2024-05-31': '2025-03-07',
      '2023-11-30': '2024-09-06',
      '2024-02-29': '2024-12-06',
      '2024-08-31': '2025-06-07',
      '2023-03-31': '2024-01-07',
      '2022-06-15': '2023-03-22',
      '2025-12-31': '2026-10-07',
    };
    cases.forEach((lmp, expected) {
      test('LMP $lmp → $expected', () {
        expect(formatDate(eddFromLmp(d(lmp))), expected);
      });
    });
  });

  group('gestationalAge', () {
    test('floors weeks', () {
      expect(gestationalAge(d('2024-01-01'), d('2024-03-07')), 9);
    });
    test('clamps to clinical window', () {
      expect(gestationalAge(d('2024-01-01'), d('2024-01-03')), 4);
      expect(gestationalAge(d('2024-01-01'), d('2025-04-01')), 42);
    });
  });

  group('nextVisitDate', () {
    test('first schedule week strictly after GA', () {
      expect(
        formatDate(nextVisitDate(d('2024-01-01'), 12)!),
        '2024-04-22', // week 16 → +112d
      );
    });
    test('null at/beyond 38 weeks', () {
      expect(nextVisitDate(d('2024-01-01'), 38), isNull);
      expect(nextVisitDate(d('2024-01-01'), 40), isNull);
    });
  });

  group('pncVisitDate', () {
    test('applies day 1/6/42 offsets', () {
      expect(formatDate(pncVisitDate(d('2024-06-01'), 1)), '2024-06-02');
      expect(formatDate(pncVisitDate(d('2024-06-01'), 2)), '2024-06-07');
      expect(formatDate(pncVisitDate(d('2024-06-01'), 3)), '2024-07-13');
    });
  });
}
