// Shared client-side pregnancy date math.
// Mirrors frontend/src/utils/dateCalc.js so web and mobile compute identical
// values. EDD uses Naegele's rule the same way the backend does
// (relativedelta months=9, days=7 → clamped month-end then +7 days).

const ancScheduleWeeks = [8, 16, 20, 26, 30, 34, 36, 38];
const pncDaysAfterDelivery = [1, 6, 42];

int _daysInMonth(int year, int month) {
  if (month == 2) {
    final leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    return leap ? 29 : 28;
  }
  return const [4, 6, 9, 11].contains(month) ? 30 : 31;
}

// date + `months`, clamping the day to the target month's length
// (mirrors Python dateutil.relativedelta, not Dart's overflow normalization).
DateTime _addMonthsClamped(DateTime date, int months) {
  int year = date.year;
  int month = date.month + months;
  while (month > 12) {
    month -= 12;
    year += 1;
  }
  final day = date.day.clamp(1, _daysInMonth(year, month));
  return DateTime(year, month, day);
}

// Naegele's rule: LMP + 9 months + 7 days.
DateTime eddFromLmp(DateTime lmp) {
  return _addMonthsClamped(lmp, 9).add(const Duration(days: 7));
}

// Floor weeks between LMP and asOf, clamped to the clinical 4–42 window.
int gestationalAge(DateTime lmp, DateTime asOf) {
  final days = asOf.difference(lmp).inDays;
  return (days / 7).floor().clamp(4, 42);
}

// First ANC schedule week strictly after the current gestational age, as
// LMP + week*7 days. Returns null when the pregnancy is at/beyond 38 weeks.
DateTime? nextVisitDate(DateTime lmp, int gestationalAgeWeeks) {
  for (final week in ancScheduleWeeks) {
    if (week > gestationalAgeWeeks) {
      return lmp.add(Duration(days: week * 7));
    }
  }
  return null;
}

// Postnatal visit at day 1 / 6 / 42 after delivery (visitNumber is 1-based).
DateTime pncVisitDate(DateTime delivery, int visitNumber) {
  final index = (visitNumber - 1).clamp(0, pncDaysAfterDelivery.length - 1);
  return delivery.add(Duration(days: pncDaysAfterDelivery[index]));
}

String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
