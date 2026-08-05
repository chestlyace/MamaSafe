# Web Data Parity (Supervisor/Admin Views) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port all web app supervisor/admin data views to the Flutter mobile app with live API data and offline fallback, plus fix the broken supervisor reports screen and dead Reports buttons.

**Architecture:** Two new/expanded repository layers (`dashboard_repository.dart` + `supervisor_repository.dart`) calling the existing FastAPI admin endpoints via the existing Dio `dioProvider`. Each screen consumes a Riverpod `FutureProvider` whose aggregate method is **live-first**: if `connectivityServiceProvider.currentValue` is true it calls the API, otherwise (or on any `DioException`) it computes the same shape from the local drift database (`AppDatabase`). Existing shared widgets (`AppCard`, `AppButton`, `EmptyState`, `AppErrorWidget`) and the existing rose Material 2 theme are reused. `fl_chart` (already in `pubspec.yaml`) renders the donut and bar charts.

**Tech Stack:** Flutter · Riverpod · go_router · drift · Dio · fl_chart · mocktail (dev)

---

## File Structure

### New files
| File | Responsibility |
|------|---------------|
| `mobile/lib/features/dashboard/dashboard_repository.dart` | `DashboardSummaryData` model, `DashboardSummaryRepository` (live + local fallback), `EscalationFeedItem`, aggregate providers |
| `mobile/lib/features/dashboard/widgets/risk_donut_chart.dart` | fl_chart donut + weekly trend bar for Home |
| `mobile/lib/features/supervisor/screens/chw_list_screen.dart` | CHW roster with status badges, tap → detail, FAB → create |
| `mobile/lib/features/supervisor/screens/chw_form_screen.dart` | Create CHW form (username/password/full name/facility) |
| `mobile/lib/features/supervisor/screens/chw_detail_screen.dart` | Per-CHW stats, risk distribution, ANC/PNC completion, weekly activity, patient list |
| `mobile/lib/features/supervisor/screens/high_risk_patients_screen.dart` | High-risk patient list with flagged/referral badges |
| `mobile/lib/features/supervisor/screens/referral_analytics_screen.dart` | Referral funnel + by-facility/by-CHW breakdowns |
| `mobile/test/features/dashboard/dashboard_repository_test.dart` | Dashboard model/repository/aggregate tests |
| `mobile/test/features/supervisor/supervisor_repository_test.dart` | Supervisor models + repository method tests |
| `mobile/test/widgets/risk_donut_chart_test.dart` | Donut widget tests |

### Modified files
| File | Change |
|------|--------|
| `mobile/lib/features/supervisor/supervisor_repository.dart` | Add `AdminDashboardData`, `WeekStats`, `ChwSummary`, `ChwDetailStats`, `HighRiskPatient`, `ReferralAnalytics`, `MonthlyReport` models + 8 methods; fix `getReports()` → `getMonthlyReport(year, month)` |
| `mobile/lib/features/supervisor/screens/supervisor_dashboard_screen.dart` | Replace fake activity feed with full web dashboard data + quick links |
| `mobile/lib/features/supervisor/screens/reports_screen.dart` | Rewrite with year/month selectors + real monthly report |
| `mobile/lib/features/dashboard/screens/dashboard_screen.dart` | Add web-data sections above Quick Actions; fix dead Reports buttons (lines 205, 279) |
| `mobile/lib/core/router/app_router.dart` | Add 5 supervisor sub-routes |
| `mobile/lib/l10n/app_en.dart` / `app_fr.dart` | Add parity strings (both locales) |

### Unchanged
| File | Reason |
|------|--------|
| `backend/**` | All required endpoints already exist |
| `frontend/**` | Reference only — data shapes mirrored from `frontend/src/pages/*.jsx` |

---

## Backend response shapes (authoritative)

`GET /api/v1/admin/dashboard`:
```json
{
  "district": "string", "region": "string",
  "total_chws": 0, "active_chws_today": 0, "total_patients": 0,
  "total_assessments": 0, "total_deliveries": 0, "total_referrals": 0,
  "referral_completion_rate": 0.0,
  "high_risk_active": 0, "mid_risk_active": 0, "low_risk_active": 0,
  "pnc1_completion_rate": 0.0, "phq2_positive_this_month": 0, "growth_alerts_active": 0,
  "pending_escalations": 0,
  "this_week": {"assessments": 0, "referrals": 0, "deliveries": 0, "new_patients": 0},
  "last_week": {"assessments": 0, "referrals": 0, "deliveries": 0, "new_patients": 0}
}
```

`GET /api/v1/dashboard/summary`:
```json
{
  "total_assessments": 0, "high_risk_count": 0, "mid_risk_count": 0, "low_risk_count": 0,
  "high_risk_pct": 0.0, "mid_risk_pct": 0.0, "low_risk_pct": 0.0,
  "total_patients": 0, "active_pregnancies": 0, "pending_referrals": 0,
  "upcoming_visits": 0, "recent_escalations": 0
}
```

`GET /api/v1/risk-escalations/recent?days=7&limit=10` → `[{ "patient_id": 1, "patient_name": "str", "from": "str", "to": "str", "escalation_type": "str", "date": "YYYY-MM-DD", "whatsapp_sent": bool }]`

`GET /api/v1/admin/chws` → `[{ "id": 1, "full_name": "str", "username": "str", "facility": "str", "district": "str", "is_active": bool, "last_active": "str|null", "days_since_active": int|null, "patient_count": int, "assessment_count": int, "referral_count": int, "high_risk_count": int, "referral_completion_rate": float, "status": "active|inactive_warning|inactive|never_active" }]`

`GET /api/v1/admin/chws/{id}/stats` → `{ "chw_id": 1, "full_name": "str", "username": "str", "facility": "str", "last_active": "str|null", "patient_count": int, "assessment_count": int, "referral_count": int, "referral_completion_rate": float, "risk_distribution": {"low": 0, "mid": 0, "high": 0}, "anc_completion": {"visit_1": 0.0, ...}, "pnc_completion": {"pnc_1": 0.0, ...}, "weekly_activity": [{"week": "YYYY-MM-DD", "assessments": 0, "referrals": 0}], "patients": [{"id": 1, "full_name": "str", "risk_level": "str|null", "last_assessment": "YYYY-MM-DD|null"}] }`

`GET /api/v1/admin/high-risk-patients?days_since_assessment=7` → `[{ "patient_id": 1, "full_name": "str", "age": 0, "facility": "str|null", "chw_name": "str|null", "chw_id": int|null, "risk_level": "high risk", "confidence": 0.0, "last_assessment_date": "YYYY-MM-DD", "days_since_assessment": 0, "flagged": bool, "systolic_bp": float|null, "blood_sugar": float|null, "referral_made": bool }]`

`GET /api/v1/admin/referral-analytics` → `{ "total_referrals": 0, "sent": 0, "received": 0, "patient_arrived": 0, "completion_rate": float, "avg_hours_to_receipt": float|null, "avg_hours_to_arrival": float|null, "high_risk_referrals": 0, "by_facility": [{"facility_name": "str", "total": 0, "arrived": 0, "completion_rate": float}], "by_chw": [{"chw_name": "str", "total": 0, "arrived": 0, "completion_rate": float}] }`

`GET /api/v1/admin/report/monthly?year=YYYY&month=MM` → `{ "district": "str", "region": "str", "year": 0, "month": 0, "reporting_period": "str", "total_chws": 0, "active_chws": 0, "total_patients_registered": 0, "new_patients_this_month": 0, "total_assessments": 0, "high_risk_detected": 0, "mid_risk_detected": 0, "low_risk_detected": 0, "total_referrals": 0, "referral_completion_rate": float, "total_deliveries": 0, "live_births": 0, "stillbirths": 0, "pnc1_completion_rate": float, "pnc2_completion_rate": float, "pnc3_completion_rate": float, "phq2_screens_performed": 0, "phq2_positive_count": 0, "growth_alerts_generated": 0, "exclusive_breastfeeding_rate": float, "generated_at": "str" }`

`POST /api/v1/admin/users` body: `{"username": "str", "password": "str", "full_name": "str|null", "facility": "str|null"}` → `{"message": "str", "user_id": 0, "username": "str", "temporary_password": "str"}`

`PATCH /api/v1/admin/users/{id}/deactivate` and `/activate` → `{"message": "str"}`

Local drift tables used for offline fallback: `Assessments(riskLevel, createdAt)`, `Patients(fullName, facility, createdAt)`, `Referrals(status)`, `Pregnancies(status)`, `ScheduledVisits(status, scheduledDate)`, `RiskEscalations(patientRef, riskLevel, message, createdAt)`.

---

## Task 1: DashboardSummaryData model + repository skeleton

**Files:**
- Create: `mobile/lib/features/dashboard/dashboard_repository.dart`
- Create: `mobile/test/features/dashboard/dashboard_repository_test.dart`

- [ ] **Step 1: Write failing test for `DashboardSummaryData.fromJson`**

```dart
// test/features/dashboard/dashboard_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/features/dashboard/dashboard_repository.dart';

void main() {
  group('DashboardSummaryData.fromJson', () {
    test('parses full payload', () {
      final data = DashboardSummaryData.fromJson(const {
        'total_assessments': 42,
        'high_risk_count': 5,
        'mid_risk_count': 12,
        'low_risk_count': 25,
        'high_risk_pct': 11.9,
        'mid_risk_pct': 28.6,
        'low_risk_pct': 59.5,
        'total_patients': 30,
        'active_pregnancies': 8,
        'pending_referrals': 3,
        'upcoming_visits': 6,
        'recent_escalations': 2,
      });

      expect(data.totalAssessments, 42);
      expect(data.highRiskCount, 5);
      expect(data.midRiskCount, 12);
      expect(data.lowRiskCount, 25);
      expect(data.highRiskPct, 11.9);
      expect(data.totalPatients, 30);
      expect(data.activePregnancies, 8);
      expect(data.pendingReferrals, 3);
      expect(data.upcomingVisits, 6);
      expect(data.recentEscalations, 2);
    });

    test('defaults missing numeric fields to zero', () {
      final data = DashboardSummaryData.fromJson(const {'total_patients': 1});
      expect(data.totalAssessments, 0);
      expect(data.highRiskCount, 0);
      expect(data.midRiskCount, 0);
      expect(data.lowRiskCount, 0);
      expect(data.highRiskPct, 0.0);
    });
  });
}
```

- [ ] **Step 2: Implement the model**

```dart
// lib/features/dashboard/dashboard_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/connectivity_service.dart';

class DashboardSummaryData {
  final int totalAssessments;
  final int highRiskCount;
  final int midRiskCount;
  final int lowRiskCount;
  final double highRiskPct;
  final double midRiskPct;
  final double lowRiskPct;
  final int totalPatients;
  final int activePregnancies;
  final int pendingReferrals;
  final int upcomingVisits;
  final int recentEscalations;

  const DashboardSummaryData({
    required this.totalAssessments,
    required this.highRiskCount,
    required this.midRiskCount,
    required this.lowRiskCount,
    required this.highRiskPct,
    required this.midRiskPct,
    required this.lowRiskPct,
    required this.totalPatients,
    required this.activePregnancies,
    required this.pendingReferrals,
    required this.upcomingVisits,
    required this.recentEscalations,
  });

  factory DashboardSummaryData.fromJson(Map<String, dynamic> json) =>
      DashboardSummaryData(
        totalAssessments: json['total_assessments'] as int? ?? 0,
        highRiskCount: json['high_risk_count'] as int? ?? 0,
        midRiskCount: json['mid_risk_count'] as int? ?? 0,
        lowRiskCount: json['low_risk_count'] as int? ?? 0,
        highRiskPct: (json['high_risk_pct'] as num?)?.toDouble() ?? 0,
        midRiskPct: (json['mid_risk_pct'] as num?)?.toDouble() ?? 0,
        lowRiskPct: (json['low_risk_pct'] as num?)?.toDouble() ?? 0,
        totalPatients: json['total_patients'] as int? ?? 0,
        activePregnancies: json['active_pregnancies'] as int? ?? 0,
        pendingReferrals: json['pending_referrals'] as int? ?? 0,
        upcomingVisits: json['upcoming_visits'] as int? ?? 0,
        recentEscalations: json['recent_escalations'] as int? ?? 0,
      );
}
```

- [ ] **Step 3: Run `flutter test test/features/dashboard/dashboard_repository_test.dart` — expect pass**

---

## Task 2: DashboardSummaryRepository (live + offline fallback)

**Files:**
- Modify: `mobile/lib/features/dashboard/dashboard_repository.dart`
- Modify: `mobile/test/features/dashboard/dashboard_repository_test.dart`

- [ ] **Step 1: Write failing test for local aggregation**

```dart
// add to dashboard_repository_test.dart
group('buildLocalSummary', () {
  test('aggregates drift rows', () {
    // rows carry only riskLevel + a marker per table
    final local = DashboardSummaryRepository.buildLocalSummary(
      assessments: 42,
      highRisk: 5,
      midRisk: 12,
      lowRisk: 25,
      patients: 30,
      activePregnancies: 8,
      pendingReferrals: 3,
      upcomingVisits: 6,
      recentEscalations: 2,
    );

    expect(local.totalAssessments, 42);
    expect(local.highRiskCount, 5);
    expect(local.midRiskCount, 12);
    expect(local.lowRiskCount, 25);
    expect(local.highRiskPct, closeTo(11.9, 0.1));
    expect(local.totalPatients, 30);
  });

  test('avoids division by zero', () {
    final local = DashboardSummaryRepository.buildLocalSummary(
      assessments: 0, highRisk: 0, midRisk: 0, lowRisk: 0,
      patients: 0, activePregnancies: 0, pendingReferrals: 0,
      upcomingVisits: 0, recentEscalations: 0,
    );
    expect(local.highRiskPct, 0.0);
    expect(local.midRiskPct, 0.0);
    expect(local.lowRiskPct, 0.0);
  });
});
```

- [ ] **Step 2: Implement repository + aggregate provider**

```dart
// append to dashboard_repository.dart
class DashboardSummaryRepository {
  final Dio _dio;

  DashboardSummaryRepository(this._dio);

  Future<DashboardSummaryData> getSummary() async {
    final response = await _dio.get('/api/v1/dashboard/summary');
    return DashboardSummaryData.fromJson(response.data as Map<String, dynamic>);
  }

  static DashboardSummaryData buildLocalSummary({
    required int assessments,
    required int highRisk,
    required int midRisk,
    required int lowRisk,
    required int patients,
    required int activePregnancies,
    required int pendingReferrals,
    required int upcomingVisits,
    required int recentEscalations,
  }) {
    final total = assessments;
    double pct(int count) => total == 0 ? 0 : (count / total * 100);
    return DashboardSummaryData(
      totalAssessments: total,
      highRiskCount: highRisk,
      midRiskCount: midRisk,
      lowRiskCount: lowRisk,
      highRiskPct: double.parse(pct(highRisk).toStringAsFixed(1)),
      midRiskPct: double.parse(pct(midRisk).toStringAsFixed(1)),
      lowRiskPct: double.parse(pct(lowRisk).toStringAsFixed(1)),
      totalPatients: patients,
      activePregnancies: activePregnancies,
      pendingReferrals: pendingReferrals,
      upcomingVisits: upcomingVisits,
      recentEscalations: recentEscalations,
    );
  }
}

final dashboardSummaryRepositoryProvider =
    Provider<DashboardSummaryRepository>((ref) {
  return DashboardSummaryRepository(ref.watch(dioProvider));
});
```

- [ ] **Step 3: Add the aggregate `FutureProvider` (uses drift via `appDatabaseProvider`)**

```dart
// append to dashboard_repository.dart
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';
// ...(imports at top: keep dio/api_client/connectivity_service; add the two above)

final homeDashboardProvider =
    FutureProvider<DashboardSummaryData>((ref) async {
  final repo = ref.watch(dashboardSummaryRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  if (connectivity.currentValue) {
    try {
      return await repo.getSummary();
    } on DioException {
      // fall through to local
    }
  }

  final db = ref.read(appDatabaseProvider);
  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: 7));

  final assessments = await db.select(db.assessments).get();
  final high = assessments
      .where((a) => a.riskLevel == 'high risk')
      .length;
  final mid = assessments.where((a) => a.riskLevel == 'mid risk').length;
  final low = assessments.where((a) => a.riskLevel == 'low risk').length;

  final patients = await db.select(db.patients).get();
  final pregnancies = await db.select(db.pregnancies).get();
  final referrals = await db.select(db.referrals).get();
  final visits = await db.select(db.scheduledVisits).get();
  final escalations = await db.select(db.riskEscalations).get();

  final upcoming = visits
      .where((v) =>
          v.status == 'scheduled' ||
          (v.status == 'rescheduled' &&
              v.scheduledDate != null &&
              !v.scheduledDate!.isBefore(cutoff)))
      .length;

  return DashboardSummaryRepository.buildLocalSummary(
    assessments: assessments.length,
    highRisk: high,
    midRisk: mid,
    lowRisk: low,
    patients: patients.length,
    activePregnancies: pregnancies.where((p) => p.status == 'active').length,
    pendingReferrals:
        referrals.where((r) => r.status == 'pending').length,
    upcomingVisits: upcoming,
    recentEscalations: escalations.length,
  );
});
```

> Note: verify `scheduledVisits` column names (`status`, `scheduledDate`) against `database.dart` during implementation; adjust getter names to the generated drift accessors if they differ.

- [ ] **Step 4: Run the test file — expect pass**

---

## Task 3: EscalationFeedItem + recentEscalationsProvider

**Files:**
- Modify: `mobile/lib/features/dashboard/dashboard_repository.dart`
- Modify: `mobile/test/features/dashboard/dashboard_repository_test.dart`

- [ ] **Step 1: Failing test for `EscalationFeedItem.fromJson` + local fallback mapping**

```dart
// add to dashboard_repository_test.dart
group('EscalationFeedItem', () {
  test('parses web shape', () {
    final item = EscalationFeedItem.fromJson(const {
      'patient_id': 7,
      'patient_name': 'Amina Diallo',
      'from': 'low risk',
      'to': 'high risk',
      'escalation_type': 'risk_upgrade',
      'date': '2026-08-01',
      'whatsapp_sent': true,
    });
    expect(item.patientId, 7);
    expect(item.patientName, 'Amina Diallo');
    expect(item.from, 'low risk');
    expect(item.to, 'high risk');
    expect(item.whatsappSent, isTrue);
    expect(item.date, '2026-08-01');
  });

  test('fromLocalMessage derives fields from a local message', () {
    final item = EscalationFeedItem.fromLocalMessage(
      patientRef: 'Amina Diallo',
      riskLevel: 'high risk',
      message: 'BP 180/120',
      createdAt: DateTime(2026, 8, 1),
    );
    expect(item.patientName, 'Amina Diallo');
    expect(item.from, isNull);
    expect(item.to, 'high risk');
    expect(item.date, '2026-08-01');
  });
});
```

- [ ] **Step 2: Implement model + provider**

```dart
// append to dashboard_repository.dart
class EscalationFeedItem {
  final int? patientId;
  final String? patientName;
  final String? from;
  final String? to;
  final String? escalationType;
  final String? date;
  final bool whatsappSent;

  const EscalationFeedItem({
    this.patientId,
    this.patientName,
    this.from,
    this.to,
    this.escalationType,
    this.date,
    this.whatsappSent = false,
  });

  factory EscalationFeedItem.fromJson(Map<String, dynamic> json) =>
      EscalationFeedItem(
        patientId: json['patient_id'] as int?,
        patientName: json['patient_name'] as String?,
        from: json['from'] as String?,
        to: json['to'] as String?,
        escalationType: json['escalation_type'] as String?,
        date: json['date'] as String?,
        whatsappSent: json['whatsapp_sent'] as bool? ?? false,
      );

  factory EscalationFeedItem.fromLocalMessage({
    String? patientRef,
    String? riskLevel,
    String? message,
    DateTime? createdAt,
  }) =>
      EscalationFeedItem(
        patientName: patientRef,
        to: riskLevel,
        escalationType: message,
        date: createdAt?.toIso8601String().split('T').first,
        whatsappSent: false,
      );
}

final recentEscalationsProvider =
    FutureProvider<List<EscalationFeedItem>>((ref) async {
  final repo = ref.watch(dashboardSummaryRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  if (connectivity.currentValue) {
    try {
      final response = await _dio_get_escalations(repo);
      return response;
    } on DioException {
      // fall through to local
    }
  }

  final db = ref.read(appDatabaseProvider);
  final query = db.select(db.riskEscalations)
    ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ..limit(10);
  final rows = await query.get();
  return rows
      .map((r) => EscalationFeedItem.fromLocalMessage(
            patientRef: r.patientRef,
            riskLevel: r.riskLevel,
            message: r.message,
            createdAt: r.createdAt,
          ))
      .toList();
});
```

> Note: `_dio_get_escalations(repo)` is a helper defined below (kept as a plain function so it is unit-testable). Replace the inline comment with the real call:
> ```dart
> Future<List<EscalationFeedItem>> _dio_get_escalations(
>     DashboardSummaryRepository repo) async {
>   final response =
>       await repo.dio.get('/api/v1/risk-escalations/recent?days=7&limit=10');
>   final list = response.data as List<dynamic>;
>   return list
>       .map((e) => EscalationFeedItem.fromJson(e as Map<String, dynamic>))
>       .toList();
> }
> ```
> To support this, add a public `final Dio dio;` field to `DashboardSummaryRepository` and construct it in the constructor: `DashboardSummaryRepository(this.dio);`.

- [ ] **Step 3: Add the missing `dio` field, `dioProvider` import already present; run the test file — expect pass**

---

## Task 4: AdminDashboardData + WeekStats models (supervisor)

**Files:**
- Modify: `mobile/lib/features/supervisor/supervisor_repository.dart`
- Create: `mobile/test/features/supervisor/supervisor_repository_test.dart`

- [ ] **Step 1: Failing model tests**

```dart
// test/features/supervisor/supervisor_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/features/supervisor/supervisor_repository.dart';

void main() {
  group('WeekStats.fromJson', () {
    test('parses and defaults', () {
      final w = WeekStats.fromJson(const {'assessments': 5, 'referrals': 2});
      expect(w.assessments, 5);
      expect(w.referrals, 2);
      expect(w.deliveries, 0);
      expect(w.newPatients, 0);
    });
  });

  group('AdminDashboardData.fromJson', () {
    test('parses full payload', () {
      final d = AdminDashboardData.fromJson(const {
        'district': 'Dakar', 'region': 'Dakar',
        'total_chws': 10, 'active_chws_today': 4,
        'total_patients': 120, 'total_assessments': 300,
        'total_deliveries': 25, 'total_referrals': 40,
        'referral_completion_rate': 55.5,
        'high_risk_active': 8, 'mid_risk_active': 15, 'low_risk_active': 97,
        'pnc1_completion_rate': 80.0, 'phq2_positive_this_month': 3,
        'growth_alerts_active': 6, 'pending_escalations': 2,
        'this_week': {'assessments': 10, 'referrals': 3, 'deliveries': 1, 'new_patients': 4},
        'last_week': {'assessments': 8, 'referrals': 1, 'deliveries': 2, 'new_patients': 2},
      });
      expect(d.totalChws, 10);
      expect(d.activeChwsToday, 4);
      expect(d.totalPatients, 120);
      expect(d.totalAssessments, 300);
      expect(d.referralCompletionRate, 55.5);
      expect(d.highRiskActive, 8);
      expect(d.pnc1CompletionRate, 80.0);
      expect(d.phq2PositiveThisMonth, 3);
      expect(d.growthAlertsActive, 6);
      expect(d.pendingEscalations, 2);
      expect(d.thisWeek.assessments, 10);
      expect(d.lastWeek.newPatients, 2);
    });

    test('defaults missing numeric fields to zero', () {
      final d = AdminDashboardData.fromJson(const {});
      expect(d.totalChws, 0);
      expect(d.referralCompletionRate, 0.0);
      expect(d.thisWeek.assessments, 0);
      expect(d.lastWeek.assessments, 0);
    });
  });
}
```

- [ ] **Step 2: Implement models** (prepend to `supervisor_repository.dart`; replace the old `StatsData` class with `AdminDashboardData`, and delete `StatsData` entirely)

```dart
class WeekStats {
  final int assessments;
  final int referrals;
  final int deliveries;
  final int newPatients;

  const WeekStats({
    this.assessments = 0,
    this.referrals = 0,
    this.deliveries = 0,
    this.newPatients = 0,
  });

  factory WeekStats.fromJson(Map<String, dynamic> json) => WeekStats(
        assessments: json['assessments'] as int? ?? 0,
        referrals: json['referrals'] as int? ?? 0,
        deliveries: json['deliveries'] as int? ?? 0,
        newPatients: json['new_patients'] as int? ?? 0,
      );
}

class AdminDashboardData {
  final String district;
  final String region;
  final int totalChws;
  final int activeChwsToday;
  final int totalPatients;
  final int totalAssessments;
  final int totalDeliveries;
  final int totalReferrals;
  final double referralCompletionRate;
  final int highRiskActive;
  final int midRiskActive;
  final int lowRiskActive;
  final double pnc1CompletionRate;
  final int phq2PositiveThisMonth;
  final int growthAlertsActive;
  final int pendingEscalations;
  final WeekStats thisWeek;
  final WeekStats lastWeek;

  const AdminDashboardData({
    this.district = '',
    this.region = '',
    this.totalChws = 0,
    this.activeChwsToday = 0,
    this.totalPatients = 0,
    this.totalAssessments = 0,
    this.totalDeliveries = 0,
    this.totalReferrals = 0,
    this.referralCompletionRate = 0,
    this.highRiskActive = 0,
    this.midRiskActive = 0,
    this.lowRiskActive = 0,
    this.pnc1CompletionRate = 0,
    this.phq2PositiveThisMonth = 0,
    this.growthAlertsActive = 0,
    this.pendingEscalations = 0,
    this.thisWeek = const WeekStats(),
    this.lastWeek = const WeekStats(),
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) =>
      AdminDashboardData(
        district: json['district'] as String? ?? '',
        region: json['region'] as String? ?? '',
        totalChws: json['total_chws'] as int? ?? 0,
        activeChwsToday: json['active_chws_today'] as int? ?? 0,
        totalPatients: json['total_patients'] as int? ?? 0,
        totalAssessments: json['total_assessments'] as int? ?? 0,
        totalDeliveries: json['total_deliveries'] as int? ?? 0,
        totalReferrals: json['total_referrals'] as int? ?? 0,
        referralCompletionRate:
            (json['referral_completion_rate'] as num?)?.toDouble() ?? 0,
        highRiskActive: json['high_risk_active'] as int? ?? 0,
        midRiskActive: json['mid_risk_active'] as int? ?? 0,
        lowRiskActive: json['low_risk_active'] as int? ?? 0,
        pnc1CompletionRate:
            (json['pnc1_completion_rate'] as num?)?.toDouble() ?? 0,
        phq2PositiveThisMonth: json['phq2_positive_this_month'] as int? ?? 0,
        growthAlertsActive: json['growth_alerts_active'] as int? ?? 0,
        pendingEscalations: json['pending_escalations'] as int? ?? 0,
        thisWeek: WeekStats.fromJson(
            json['this_week'] as Map<String, dynamic>? ?? const {}),
        lastWeek: WeekStats.fromJson(
            json['last_week'] as Map<String, dynamic>? ?? const {}),
      );
}
```

- [ ] **Step 3: Run the new test file — expect pass**

---

## Task 5: SupervisorRepository.getDashboard() — replace getStats()

**Files:**
- Modify: `mobile/lib/features/supervisor/supervisor_repository.dart`
- Modify: `mobile/test/features/supervisor/supervisor_repository_test.dart`

- [ ] **Step 1: Failing repository test (mocktail Dio)**

```dart
// add to supervisor_repository_test.dart
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mamasafe/core/network/api_client.dart';
import 'package:mamasafe/features/supervisor/supervisor_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late SupervisorRepository repo;

  setUp(() {
    dio = MockDio();
    repo = SupervisorRepository(dio);
  });

  group('SupervisorRepository.getDashboard', () {
    test('fetches and parses admin dashboard', () async {
      when(() => dio.get('/api/v1/admin/dashboard')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/admin/dashboard'),
          statusCode: 200,
          data: const {
            'total_chws': 10,
            'active_chws_today': 4,
            'total_patients': 120,
            'total_assessments': 300,
            'total_deliveries': 25,
            'total_referrals': 40,
            'referral_completion_rate': 55.5,
            'high_risk_active': 8,
            'mid_risk_active': 15,
            'low_risk_active': 97,
            'pnc1_completion_rate': 80.0,
            'phq2_positive_this_month': 3,
            'growth_alerts_active': 6,
            'pending_escalations': 2,
            'this_week': {'assessments': 10, 'referrals': 3, 'deliveries': 1, 'new_patients': 4},
            'last_week': {'assessments': 8, 'referrals': 1, 'deliveries': 2, 'new_patients': 2},
          },
        ),
      );

      final data = await repo.getDashboard();
      expect(data.totalChws, 10);
      expect(data.highRiskActive, 8);
      expect(data.thisWeek.deliveries, 1);
      verify(() => dio.get('/api/v1/admin/dashboard')).called(1);
    });
  });
}
```

- [ ] **Step 2: Implement `getDashboard()` and update provider**

```dart
// in SupervisorRepository, replace getStats():
  Future<AdminDashboardData> getDashboard() async {
    final response = await _dio.get('/api/v1/admin/dashboard');
    return AdminDashboardData.fromJson(
        response.data as Map<String, dynamic>);
  }
```
Then delete `getRecentActivity()` (the fake feed is being removed) and update the providers at the bottom:
```dart
final supervisorDashboardProvider =
    FutureProvider<AdminDashboardData>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getDashboard();
});
```
Remove `supervisorStatsProvider` and `supervisorActivityProvider`. Delete the now-unused `StatsData` class (already removed in Task 4) and the `last_week` unused-variable warning is eliminated because `AdminDashboardData` holds `lastWeek`.

- [ ] **Step 3: Update any references to `supervisorStatsProvider`/`supervisorActivityProvider` (only `supervisor_dashboard_screen.dart` today) — will be fixed in Task 12; run test file now — expect pass**

---

## Task 6: ChwSummary model + listChws()

**Files:**
- Modify: `mobile/lib/features/supervisor/supervisor_repository.dart`
- Modify: `mobile/test/features/supervisor/supervisor_repository_test.dart`

- [ ] **Step 1: Failing tests (model + method)**

```dart
// add to supervisor_repository_test.dart
group('ChwSummary.fromJson', () {
  test('parses web shape', () {
    final c = ChwSummary.fromJson(const {
      'id': 1,
      'full_name': 'Moussa Fall',
      'username': 'moussa',
      'facility': 'Centre A',
      'district': 'Dakar',
      'is_active': true,
      'days_since_active': 1,
      'patient_count': 20,
      'assessment_count': 45,
      'referral_count': 6,
      'high_risk_count': 2,
      'referral_completion_rate': 66.7,
      'status': 'active',
    });
    expect(c.id, 1);
    expect(c.fullName, 'Moussa Fall');
    expect(c.isActive, isTrue);
    expect(c.status, 'active');
    expect(c.highRiskCount, 2);
    expect(c.referralCompletionRate, 66.7);
  });
});

group('SupervisorRepository.listChws', () {
  test('fetches CHW list', () async {
    when(() => dio.get('/api/v1/admin/chws')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/admin/chws'),
        statusCode: 200,
        data: const [
          {
            'id': 1, 'full_name': 'Moussa Fall', 'username': 'moussa',
            'facility': 'Centre A', 'district': 'Dakar',
            'is_active': true, 'days_since_active': 1,
            'patient_count': 20, 'assessment_count': 45,
            'referral_count': 6, 'high_risk_count': 2,
            'referral_completion_rate': 66.7, 'status': 'active',
          },
        ],
      ),
    );

    final chws = await repo.listChws();
    expect(chws, hasLength(1));
    expect(chws.first.fullName, 'Moussa Fall');
  });
});
```

- [ ] **Step 2: Implement model + method**

```dart
class ChwSummary {
  final int id;
  final String fullName;
  final String username;
  final String? facility;
  final String? district;
  final bool isActive;
  final int? daysSinceActive;
  final int patientCount;
  final int assessmentCount;
  final int referralCount;
  final int highRiskCount;
  final double referralCompletionRate;
  final String status;

  const ChwSummary({
    required this.id,
    required this.fullName,
    required this.username,
    this.facility,
    this.district,
    this.isActive = true,
    this.daysSinceActive,
    this.patientCount = 0,
    this.assessmentCount = 0,
    this.referralCount = 0,
    this.highRiskCount = 0,
    this.referralCompletionRate = 0,
    this.status = 'inactive',
  });

  factory ChwSummary.fromJson(Map<String, dynamic> json) => ChwSummary(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        username: json['username'] as String? ?? '',
        facility: json['facility'] as String?,
        district: json['district'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        daysSinceActive: json['days_since_active'] as int?,
        patientCount: json['patient_count'] as int? ?? 0,
        assessmentCount: json['assessment_count'] as int? ?? 0,
        referralCount: json['referral_count'] as int? ?? 0,
        highRiskCount: json['high_risk_count'] as int? ?? 0,
        referralCompletionRate:
            (json['referral_completion_rate'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'inactive',
      );
}
```
```dart
// in SupervisorRepository:
  Future<List<ChwSummary>> listChws() async {
    final response = await _dio.get('/api/v1/admin/chws');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ChwSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
```

- [ ] **Step 3: Run test file — expect pass**

---

## Task 7: ChwDetailStats model + getChwStats()

**Files:**
- Modify: `mobile/lib/features/supervisor/supervisor_repository.dart`
- Modify: `mobile/test/features/supervisor/supervisor_repository_test.dart`

- [ ] **Step 1: Failing tests**

```dart
// add to supervisor_repository_test.dart
group('ChwDetailStats.fromJson', () {
  test('parses nested maps', () {
    final s = ChwDetailStats.fromJson(const {
      'chw_id': 1,
      'full_name': 'Moussa Fall',
      'username': 'moussa',
      'facility': 'Centre A',
      'patient_count': 20,
      'assessment_count': 45,
      'referral_count': 6,
      'referral_completion_rate': 66.7,
      'risk_distribution': {'low': 10, 'mid': 8, 'high': 2},
      'anc_completion': {'visit_1': 80.0, 'visit_2': 50.0},
      'pnc_completion': {'pnc_1': 100.0},
      'weekly_activity': [
        {'week': '2026-07-25', 'assessments': 3, 'referrals': 1},
      ],
      'patients': [
        {'id': 2, 'full_name': 'Amina', 'risk_level': 'high risk', 'last_assessment': '2026-07-30'},
      ],
    });
    expect(s.riskDistribution['high'], 2);
    expect(s.ancCompletion['visit_2'], 50.0);
    expect(s.pncCompletion['pnc_1'], 100.0);
    expect(s.weeklyActivity, hasLength(1));
    expect(s.patients, hasLength(1));
    expect(s.patients.first.fullName, 'Amina');
  });
});

group('SupervisorRepository.getChwStats', () {
  test('fetches by id', () async {
    when(() => dio.get('/api/v1/admin/chws/1/stats')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/admin/chws/1/stats'),
        statusCode: 200,
        data: const {
          'chw_id': 1, 'full_name': 'Moussa Fall', 'username': 'moussa',
          'facility': 'Centre A',
          'patient_count': 20, 'assessment_count': 45, 'referral_count': 6,
          'referral_completion_rate': 66.7,
          'risk_distribution': {'low': 10, 'mid': 8, 'high': 2},
          'anc_completion': {}, 'pnc_completion': {},
          'weekly_activity': [], 'patients': [],
        },
      ),
    );

    final stats = await repo.getChwStats(1);
    expect(stats.fullName, 'Moussa Fall');
    verify(() => dio.get('/api/v1/admin/chws/1/stats')).called(1);
  });
});
```

- [ ] **Step 2: Implement models**

```dart
class ChwPatientRow {
  final int id;
  final String fullName;
  final String? riskLevel;
  final String? lastAssessment;

  const ChwPatientRow({
    required this.id,
    required this.fullName,
    this.riskLevel,
    this.lastAssessment,
  });

  factory ChwPatientRow.fromJson(Map<String, dynamic> json) => ChwPatientRow(
        id: json['id'] as int,
        fullName: json['full_name'] as String? ?? '',
        riskLevel: json['risk_level'] as String?,
        lastAssessment: json['last_assessment'] as String?,
      );
}

class ChwActivityWeek {
  final String week;
  final int assessments;
  final int referrals;

  const ChwActivityWeek({
    required this.week,
    this.assessments = 0,
    this.referrals = 0,
  });

  factory ChwActivityWeek.fromJson(Map<String, dynamic> json) =>
      ChwActivityWeek(
        week: json['week'] as String? ?? '',
        assessments: json['assessments'] as int? ?? 0,
        referrals: json['referrals'] as int? ?? 0,
      );
}

class ChwDetailStats {
  final int chwId;
  final String fullName;
  final String username;
  final String? facility;
  final int patientCount;
  final int assessmentCount;
  final int referralCount;
  final double referralCompletionRate;
  final Map<String, int> riskDistribution;
  final Map<String, double> ancCompletion;
  final Map<String, double> pncCompletion;
  final List<ChwActivityWeek> weeklyActivity;
  final List<ChwPatientRow> patients;

  const ChwDetailStats({
    required this.chwId,
    required this.fullName,
    this.username = '',
    this.facility,
    this.patientCount = 0,
    this.assessmentCount = 0,
    this.referralCount = 0,
    this.referralCompletionRate = 0,
    this.riskDistribution = const {},
    this.ancCompletion = const {},
    this.pncCompletion = const {},
    this.weeklyActivity = const [],
    this.patients = const [],
  });

  factory ChwDetailStats.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(String key) =>
        (json[key] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v as int? ?? 0));
    Map<String, double> doubleMap(String key) =>
        (json[key] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0));

    return ChwDetailStats(
      chwId: json['chw_id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      facility: json['facility'] as String?,
      patientCount: json['patient_count'] as int? ?? 0,
      assessmentCount: json['assessment_count'] as int? ?? 0,
      referralCount: json['referral_count'] as int? ?? 0,
      referralCompletionRate:
          (json['referral_completion_rate'] as num?)?.toDouble() ?? 0,
      riskDistribution: intMap('risk_distribution'),
      ancCompletion: doubleMap('anc_completion'),
      pncCompletion: doubleMap('pnc_completion'),
      weeklyActivity: (json['weekly_activity'] as List<dynamic>? ?? [])
          .map((e) => ChwActivityWeek.fromJson(e as Map<String, dynamic>))
          .toList(),
      patients: (json['patients'] as List<dynamic>? ?? [])
          .map((e) => ChwPatientRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
```
```dart
// in SupervisorRepository:
  Future<ChwDetailStats> getChwStats(int chwId) async {
    final response = await _dio.get('/api/v1/admin/chws/$chwId/stats');
    return ChwDetailStats.fromJson(response.data as Map<String, dynamic>);
  }
```

- [ ] **Step 3: Run test file — expect pass**

---

## Task 8: createChw / deactivateUser / activateUser

**Files:**
- Modify: `mobile/lib/features/supervisor/supervisor_repository.dart`
- Modify: `mobile/test/features/supervisor/supervisor_repository_test.dart`

- [ ] **Step 1: Failing tests**

```dart
// add to supervisor_repository_test.dart
group('SupervisorRepository.createChw', () {
  test('posts payload', () async {
    when(() => dio.post(
      '/api/v1/admin/users',
      data: any(named: 'data'),
    )).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: '/api/v1/admin/users'),
      statusCode: 201,
      data: const {'message': 'CHW account created', 'user_id': 9, 'username': 'newchw', 'temporary_password': 'pw'},
    ));

    final userId = await repo.createChw('newchw', 'pw', 'New Chw', 'Centre B');
    expect(userId, 9);
    verify(() => dio.post(
      '/api/v1/admin/users',
      data: {'username': 'newchw', 'password': 'pw', 'full_name': 'New Chw', 'facility': 'Centre B'},
    )).called(1);
  });
});

group('SupervisorRepository.deactivateUser / activateUser', () {
  test('deactivate', () async {
    when(() => dio.patch('/api/v1/admin/users/9/deactivate')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/admin/users/9/deactivate'),
        statusCode: 200,
        data: const {'message': 'User newchw deactivated'},
      ),
    );
    await repo.deactivateUser(9);
    verify(() => dio.patch('/api/v1/admin/users/9/deactivate')).called(1);
  });

  test('activate', () async {
    when(() => dio.patch('/api/v1/admin/users/9/activate')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/v1/admin/users/9/activate'),
        statusCode: 200,
        data: const {'message': 'User newchw activated'},
      ),
    );
    await repo.activateUser(9);
    verify(() => dio.patch('/api/v1/admin/users/9/activate')).called(1);
  });
});
```

- [ ] **Step 2: Implement methods**

```dart
// in SupervisorRepository:
  Future<int> createChw(
    String username,
    String password,
    String fullName,
    String facility,
  ) async {
    final response = await _dio.post('/api/v1/admin/users', data: {
      'username': username,
      'password': password,
      'full_name': fullName,
      'facility': facility,
    });
    final body = response.data as Map<String, dynamic>;
    return body['user_id'] as int? ?? 0;
  }

  Future<void> deactivateUser(int userId) async {
    await _dio.patch('/api/v1/admin/users/$userId/deactivate');
  }

  Future<void> activateUser(int userId) async {
    await _dio.patch('/api/v1/admin/users/$userId/activate');
  }
```

- [ ] **Step 3: Run test file — expect pass**

---

## Task 9: HighRiskPatient model + getHighRiskPatients()

**Files:**
- Modify: `mobile/lib/features/supervisor/supervisor_repository.dart`
- Modify: `mobile/test/features/supervisor/supervisor_repository_test.dart`

- [ ] **Step 1: Failing tests**

```dart
// add to supervisor_repository_test.dart
group('HighRiskPatient.fromJson', () {
  test('parses web shape', () {
    final p = HighRiskPatient.fromJson(const {
      'patient_id': 3,
      'full_name': 'Fatou Ndiaye',
      'age': 28,
      'facility': 'Centre A',
      'chw_name': 'Moussa Fall',
      'chw_id': 1,
      'risk_level': 'high risk',
      'confidence': 0.95,
      'last_assessment_date': '2026-07-25',
      'days_since_assessment': 7,
      'flagged': true,
      'systolic_bp': 180.0,
      'blood_sugar': 12.0,
      'referral_made': false,
    });
    expect(p.patientId, 3);
    expect(p.fullName, 'Fatou Ndiaye');
    expect(p.confidence, 0.95);
    expect(p.flagged, isTrue);
    expect(p.referralMade, isFalse);
  });
});

group('SupervisorRepository.getHighRiskPatients', () {
  test('uses days_since_assessment param', () async {
    when(() => dio.get(
      '/api/v1/admin/high-risk-patients',
      queryParameters: any(named: 'queryParameters'),
    )).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: '/api/v1/admin/high-risk-patients'),
      statusCode: 200,
      data: const [],
    ));

    final list = await repo.getHighRiskPatients(daysSince: 7);
    expect(list, isEmpty);
    verify(() => dio.get(
      '/api/v1/admin/high-risk-patients',
      queryParameters: {'days_since_assessment': 7},
    )).called(1);
  });
});
```

- [ ] **Step 2: Implement model + method**

```dart
class HighRiskPatient {
  final int patientId;
  final String fullName;
  final int? age;
  final String? facility;
  final String? chwName;
  final int? chwId;
  final String riskLevel;
  final double confidence;
  final String? lastAssessmentDate;
  final int daysSinceAssessment;
  final bool flagged;
  final double? systolicBp;
  final double? bloodSugar;
  final bool referralMade;

  const HighRiskPatient({
    required this.patientId,
    required this.fullName,
    this.age,
    this.facility,
    this.chwName,
    this.chwId,
    this.riskLevel = 'high risk',
    this.confidence = 0,
    this.lastAssessmentDate,
    this.daysSinceAssessment = 0,
    this.flagged = false,
    this.systolicBp,
    this.bloodSugar,
    this.referralMade = false,
  });

  factory HighRiskPatient.fromJson(Map<String, dynamic> json) =>
      HighRiskPatient(
        patientId: json['patient_id'] as int? ?? 0,
        fullName: json['full_name'] as String? ?? 'Unknown',
        age: json['age'] as int?,
        facility: json['facility'] as String?,
        chwName: json['chw_name'] as String?,
        chwId: json['chw_id'] as int?,
        riskLevel: json['risk_level'] as String? ?? 'high risk',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        lastAssessmentDate: json['last_assessment_date'] as String?,
        daysSinceAssessment: json['days_since_assessment'] as int? ?? 0,
        flagged: json['flagged'] as bool? ?? false,
        systolicBp: (json['systolic_bp'] as num?)?.toDouble(),
        bloodSugar: (json['blood_sugar'] as num?)?.toDouble(),
        referralMade: json['referral_made'] as bool? ?? false,
      );
}
```
```dart
// in SupervisorRepository:
  Future<List<HighRiskPatient>> getHighRiskPatients(
      {int daysSince = 7}) async {
    final response = await _dio.get(
      '/api/v1/admin/high-risk-patients',
      queryParameters: {'days_since_assessment': daysSince},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => HighRiskPatient.fromJson(e as Map<String, dynamic>))
        .toList();
  }
```

- [ ] **Step 3: Run test file — expect pass**

---

## Task 10: ReferralAnalytics model + getReferralAnalytics()

**Files:**
- Modify: `mobile/lib/features/supervisor/supervisor_repository.dart`
- Modify: `mobile/test/features/supervisor/supervisor_repository_test.dart`

- [ ] **Step 1: Failing tests**

```dart
// add to supervisor_repository_test.dart
group('ReferralAnalytics.fromJson', () {
  test('parses nested breakdowns', () {
    final a = ReferralAnalytics.fromJson(const {
      'total_referrals': 10,
      'sent': 3,
      'received': 2,
      'patient_arrived': 5,
      'completion_rate': 50.0,
      'avg_hours_to_receipt': 2.5,
      'avg_hours_to_arrival': null,
      'high_risk_referrals': 4,
      'by_facility': [
        {'facility_name': 'Hopital A', 'total': 6, 'arrived': 3, 'completion_rate': 50.0},
      ],
      'by_chw': [
        {'chw_name': 'Moussa Fall', 'total': 10, 'arrived': 5, 'completion_rate': 50.0},
      ],
    });
    expect(a.totalReferrals, 10);
    expect(a.completionRate, 50.0);
    expect(a.avgHoursToReceipt, 2.5);
    expect(a.avgHoursToArrival, isNull);
    expect(a.byFacility, hasLength(1));
    expect(a.byFacility.first.facilityName, 'Hopital A');
    expect(a.byChw.first.chwName, 'Moussa Fall');
  });
});
```

- [ ] **Step 2: Implement models + method**

```dart
class ReferralFacilityStats {
  final String facilityName;
  final int total;
  final int arrived;
  final double completionRate;

  const ReferralFacilityStats({
    required this.facilityName,
    this.total = 0,
    this.arrived = 0,
    this.completionRate = 0,
  });

  factory ReferralFacilityStats.fromJson(Map<String, dynamic> json) =>
      ReferralFacilityStats(
        facilityName: json['facility_name'] as String? ?? 'Unknown',
        total: json['total'] as int? ?? 0,
        arrived: json['arrived'] as int? ?? 0,
        completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      );
}

class ReferralChwStats {
  final String chwName;
  final int total;
  final int arrived;
  final double completionRate;

  const ReferralChwStats({
    required this.chwName,
    this.total = 0,
    this.arrived = 0,
    this.completionRate = 0,
  });

  factory ReferralChwStats.fromJson(Map<String, dynamic> json) =>
      ReferralChwStats(
        chwName: json['chw_name'] as String? ?? 'Unknown',
        total: json['total'] as int? ?? 0,
        arrived: json['arrived'] as int? ?? 0,
        completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      );
}

class ReferralAnalytics {
  final int totalReferrals;
  final int sent;
  final int received;
  final int patientArrived;
  final double completionRate;
  final double? avgHoursToReceipt;
  final double? avgHoursToArrival;
  final int highRiskReferrals;
  final List<ReferralFacilityStats> byFacility;
  final List<ReferralChwStats> byChw;

  const ReferralAnalytics({
    this.totalReferrals = 0,
    this.sent = 0,
    this.received = 0,
    this.patientArrived = 0,
    this.completionRate = 0,
    this.avgHoursToReceipt,
    this.avgHoursToArrival,
    this.highRiskReferrals = 0,
    this.byFacility = const [],
    this.byChw = const [],
  });

  factory ReferralAnalytics.fromJson(Map<String, dynamic> json) =>
      ReferralAnalytics(
        totalReferrals: json['total_referrals'] as int? ?? 0,
        sent: json['sent'] as int? ?? 0,
        received: json['received'] as int? ?? 0,
        patientArrived: json['patient_arrived'] as int? ?? 0,
        completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
        avgHoursToReceipt: (json['avg_hours_to_receipt'] as num?)?.toDouble(),
        avgHoursToArrival: (json['avg_hours_to_arrival'] as num?)?.toDouble(),
        highRiskReferrals: json['high_risk_referrals'] as int? ?? 0,
        byFacility: (json['by_facility'] as List<dynamic>? ?? [])
            .map((e) => ReferralFacilityStats.fromJson(e as Map<String, dynamic>))
            .toList(),
        byChw: (json['by_chw'] as List<dynamic>? ?? [])
            .map((e) => ReferralChwStats.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
```
```dart
// in SupervisorRepository:
  Future<ReferralAnalytics> getReferralAnalytics() async {
    final response = await _dio.get('/api/v1/admin/referral-analytics');
    return ReferralAnalytics.fromJson(response.data as Map<String, dynamic>);
  }
```

- [ ] **Step 3: Run test file — expect pass**

---

## Task 11: MonthlyReport model + getMonthlyReport() (fix getReports)

**Files:**
- Modify: `mobile/lib/features/supervisor/supervisor_repository.dart`
- Modify: `mobile/test/features/supervisor/supervisor_repository_test.dart`

- [ ] **Step 1: Failing tests**

```dart
// add to supervisor_repository_test.dart
group('MonthlyReport.fromJson', () {
  test('parses full payload', () {
    final r = MonthlyReport.fromJson(const {
      'district': 'Dakar', 'region': 'Dakar',
      'year': 2026, 'month': 8,
      'reporting_period': 'August 2026',
      'total_chws': 10, 'active_chws': 4,
      'total_patients_registered': 120, 'new_patients_this_month': 5,
      'total_assessments': 40, 'high_risk_detected': 6,
      'mid_risk_detected': 10, 'low_risk_detected': 24,
      'total_referrals': 8, 'referral_completion_rate': 62.5,
      'total_deliveries': 3, 'live_births': 3, 'stillbirths': 0,
      'pnc1_completion_rate': 100.0, 'pnc2_completion_rate': 66.7,
      'pnc3_completion_rate': 33.3,
      'phq2_screens_performed': 4, 'phq2_positive_count': 1,
      'growth_alerts_generated': 2,
      'exclusive_breastfeeding_rate': 80.0,
      'generated_at': '2026-08-01T00:00:00',
    });
    expect(r.reportingPeriod, 'August 2026');
    expect(r.newPatientsThisMonth, 5);
    expect(r.liveBirths, 3);
    expect(r.pnc1CompletionRate, 100.0);
  });
});

group('SupervisorRepository.getMonthlyReport', () {
  test('sends year and month params', () async {
    when(() => dio.get(
      '/api/v1/admin/report/monthly',
      queryParameters: any(named: 'queryParameters'),
    )).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: '/api/v1/admin/report/monthly'),
      statusCode: 200,
      data: const {'reporting_period': 'August 2026'},
    ));

    final report = await repo.getMonthlyReport(2026, 8);
    expect(report.reportingPeriod, 'August 2026');
    verify(() => dio.get(
      '/api/v1/admin/report/monthly',
      queryParameters: {'year': 2026, 'month': 8},
    )).called(1);
  });
});
```

- [ ] **Step 2: Implement model + method, delete old `getReports()`**

```dart
class MonthlyReport {
  final String district;
  final String region;
  final int year;
  final int month;
  final String reportingPeriod;
  final int totalChws;
  final int activeChws;
  final int totalPatientsRegistered;
  final int newPatientsThisMonth;
  final int totalAssessments;
  final int highRiskDetected;
  final int midRiskDetected;
  final int lowRiskDetected;
  final int totalReferrals;
  final double referralCompletionRate;
  final int totalDeliveries;
  final int liveBirths;
  final int stillbirths;
  final double pnc1CompletionRate;
  final double pnc2CompletionRate;
  final double pnc3CompletionRate;
  final int phq2ScreensPerformed;
  final int phq2PositiveCount;
  final int growthAlertsGenerated;
  final double exclusiveBreastfeedingRate;

  const MonthlyReport({
    this.district = '',
    this.region = '',
    this.year = 0,
    this.month = 0,
    this.reportingPeriod = '',
    this.totalChws = 0,
    this.activeChws = 0,
    this.totalPatientsRegistered = 0,
    this.newPatientsThisMonth = 0,
    this.totalAssessments = 0,
    this.highRiskDetected = 0,
    this.midRiskDetected = 0,
    this.lowRiskDetected = 0,
    this.totalReferrals = 0,
    this.referralCompletionRate = 0,
    this.totalDeliveries = 0,
    this.liveBirths = 0,
    this.stillbirths = 0,
    this.pnc1CompletionRate = 0,
    this.pnc2CompletionRate = 0,
    this.pnc3CompletionRate = 0,
    this.phq2ScreensPerformed = 0,
    this.phq2PositiveCount = 0,
    this.growthAlertsGenerated = 0,
    this.exclusiveBreastfeedingRate = 0,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) => MonthlyReport(
        district: json['district'] as String? ?? '',
        region: json['region'] as String? ?? '',
        year: json['year'] as int? ?? 0,
        month: json['month'] as int? ?? 0,
        reportingPeriod: json['reporting_period'] as String? ?? '',
        totalChws: json['total_chws'] as int? ?? 0,
        activeChws: json['active_chws'] as int? ?? 0,
        totalPatientsRegistered: json['total_patients_registered'] as int? ?? 0,
        newPatientsThisMonth: json['new_patients_this_month'] as int? ?? 0,
        totalAssessments: json['total_assessments'] as int? ?? 0,
        highRiskDetected: json['high_risk_detected'] as int? ?? 0,
        midRiskDetected: json['mid_risk_detected'] as int? ?? 0,
        lowRiskDetected: json['low_risk_detected'] as int? ?? 0,
        totalReferrals: json['total_referrals'] as int? ?? 0,
        referralCompletionRate:
            (json['referral_completion_rate'] as num?)?.toDouble() ?? 0,
        totalDeliveries: json['total_deliveries'] as int? ?? 0,
        liveBirths: json['live_births'] as int? ?? 0,
        stillbirths: json['stillbirths'] as int? ?? 0,
        pnc1CompletionRate:
            (json['pnc1_completion_rate'] as num?)?.toDouble() ?? 0,
        pnc2CompletionRate:
            (json['pnc2_completion_rate'] as num?)?.toDouble() ?? 0,
        pnc3CompletionRate:
            (json['pnc3_completion_rate'] as num?)?.toDouble() ?? 0,
        phq2ScreensPerformed: json['phq2_screens_performed'] as int? ?? 0,
        phq2PositiveCount: json['phq2_positive_count'] as int? ?? 0,
        growthAlertsGenerated: json['growth_alerts_generated'] as int? ?? 0,
        exclusiveBreastfeedingRate:
            (json['exclusive_breastfeeding_rate'] as num?)?.toDouble() ?? 0,
      );
}
```
```dart
// in SupervisorRepository — REPLACE getReports() with:
  Future<MonthlyReport> getMonthlyReport(int year, int month) async {
    final response = await _dio.get(
      '/api/v1/admin/report/monthly',
      queryParameters: {'year': year, 'month': month},
    );
    return MonthlyReport.fromJson(response.data as Map<String, dynamic>);
  }
```
Add a family provider:
```dart
final monthlyReportProvider =
    FutureProvider.family<MonthlyReport, ({int year, int month})>(
        (ref, args) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getMonthlyReport(args.year, args.month);
});
```

- [ ] **Step 3: Run test file — expect pass**

---

## Task 12: RiskDonutChart widget

**Files:**
- Create: `mobile/lib/features/dashboard/widgets/risk_donut_chart.dart`
- Create: `mobile/test/widgets/risk_donut_chart_test.dart`

- [ ] **Step 1: Failing widget test**

```dart
// test/widgets/risk_donut_chart_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/features/dashboard/widgets/risk_donut_chart.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders three segments and a center total', (tester) async {
    await tester.pumpWidget(wrap(const RiskDonutChart(
      highRisk: 2,
      midRisk: 5,
      lowRisk: 8,
      totalAssessments: 15,
    )));
    await tester.pumpAndSettle();
    expect(find.byType(RiskDonutChart), findsOneWidget);
  });

  testWidgets('renders empty state when nothing to show', (tester) async {
    await tester.pumpWidget(wrap(const RiskDonutChart(
      highRisk: 0,
      midRisk: 0,
      lowRisk: 0,
      totalAssessments: 0,
    )));
    await tester.pumpAndSettle();
    expect(find.text('No assessments yet'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Implement widget**

```dart
// lib/features/dashboard/widgets/risk_donut_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RiskDonutChart extends StatelessWidget {
  final int highRisk;
  final int midRisk;
  final int lowRisk;
  final int totalAssessments;

  const RiskDonutChart({
    super.key,
    required this.highRisk,
    required this.midRisk,
    required this.lowRisk,
    required this.totalAssessments,
  });

  @override
  Widget build(BuildContext context) {
    final values = [
      if (highRisk > 0) highRisk,
      if (midRisk > 0) midRisk,
      if (lowRisk > 0) lowRisk,
    ];
    if (values.isEmpty) {
      return const Center(
        child: Text('No assessments yet',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    final colors = [
      AppColors.error,
      AppColors.warning,
      AppColors.success,
    ];

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 48,
              sections: List.generate(values.length, (i) {
                final isLast = i == values.length - 1;
                final start = isLast ? 0 : 0.0;
                return PieChartSectionData(
                  value: values[i].toDouble(),
                  color: colors[i],
                  radius: isLast ? 36 : 36,
                  title: '',
                );
              }),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$totalAssessments',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Text('assessments',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
```

> Note: the `start` value in the section loop is vestigial (fl_chart auto-stacks). Simplify if the linter flags it: replace `final start = isLast ? 0 : 0.0;` with `final start = 0.0;` and remove the `isLast` variable.

- [ ] **Step 3: Run `flutter test test/widgets/risk_donut_chart_test.dart` — expect pass**

---

## Task 13: Home dashboard — add web data sections

**Files:**
- Modify: `mobile/lib/features/dashboard/screens/dashboard_screen.dart`

- [ ] **Step 1: Read the current `_buildContent` to locate where to insert sections** (above the Quick Actions section, currently around line 123) and confirm the two dead Reports buttons (lines 205, 279).

- [ ] **Step 2: Wire providers + overview cards**

```dart
// at top of DashboardScreen.build:
    final summaryAsync = ref.watch(homeDashboardProvider);
    final escalationsAsync = ref.watch(recentEscalationsProvider);
```
Then, inside `_buildContent`, before the `'Quick Actions'` header, insert:

```dart
                const SizedBox(height: 24),
                Text(
                  'Program Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                summaryAsync.when(
                  data: (s) => _OverviewSection(summary: s),
                  loading: () => const Center(
                      child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )),
                  error: (e, _) => _OverviewSection(
                      summary: DashboardSummaryRepository
                          .buildLocalSummary(
                    assessments: 0, highRisk: 0, midRisk: 0, lowRisk: 0,
                    patients: 0, activePregnancies: 0, pendingReferrals: 0,
                    upcomingVisits: 0, recentEscalations: 0,
                  )),
                ),
                const SizedBox(height: 24),
                Text(
                  'Risk Distribution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                summaryAsync.when(
                  data: (s) => RiskDonutChart(
                    highRisk: s.highRiskCount,
                    midRisk: s.midRiskCount,
                    lowRisk: s.lowRiskCount,
                    totalAssessments: s.totalAssessments,
                  ),
                  loading: () => const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => const SizedBox(height: 180),
                ),
                const SizedBox(height: 24),
                Text(
                  'Escalations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                _EscalationFeed(escalationsAsync: escalationsAsync),
```

- [ ] **Step 3: Add `_OverviewSection` and `_EscalationFeed` widgets** (private classes at the bottom of the file, reusing `AppCard`):

```dart
class _OverviewSection extends StatelessWidget {
  final DashboardSummaryData summary;
  const _OverviewSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (label: 'Patients', value: summary.totalPatients, icon: Icons.people_outline, color: AppColors.primary),
      (label: 'Assessments', value: summary.totalAssessments, icon: Icons.assignment_outlined, color: AppColors.primary),
      (label: 'Active Pregnancies', value: summary.activePregnancies, icon: Icons.pregnant_woman, color: AppColors.success),
      (label: 'Pending Referrals', value: summary.pendingReferrals, icon: Icons.directions_walk_outlined, color: AppColors.warning),
      (label: 'Upcoming Visits', value: summary.upcomingVisits, icon: Icons.event_outlined, color: AppColors.primary),
      (label: 'Escalations', value: summary.recentEscalations, icon: Icons.notifications_active_outlined, color: AppColors.error),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards
          .map((c) => AppCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c.icon, color: c.color, size: 24),
                    const SizedBox(height: 8),
                    Text('${c.value}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(c.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _EscalationFeed extends StatelessWidget {
  final AsyncValue<List<EscalationFeedItem>> escalationsAsync;
  const _EscalationFeed({required this.escalationsAsync});

  @override
  Widget build(BuildContext context) {
    return escalationsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_none,
            title: 'No recent escalations',
            subtitle: 'Escalations will appear here',
          );
        }
        return Column(
          children: items.take(5).map((e) {
            final escalatedTo = e.to?.replaceAll(' risk', '') ?? 'high';
            final color = escalatedTo == 'high' ? AppColors.error : AppColors.warning;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.arrow_upward,
                          color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.patientName ?? 'Unknown patient',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(
                            '${e.from ?? 'risk'}\u2192${e.to ?? 'risk'}  ${e.date ?? ''}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (e.whatsappSent)
                      const Icon(Icons.check_circle,
                          size: 16, color: AppColors.success),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Could not load escalations',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}
```

- [ ] **Step 4: Fix the two dead Reports buttons (lines ~205 and ~279)** — change `context.push('/supervisor/reports')` / any non-wired targets:
  - Line 205 area: the "Reports" quick action in the supervisor grid currently pushes a route that does not resolve to a real Reports screen for non-supervisor roles. Change its `onTap` to `context.push('/supervisor/reports')` (same as supervisor branch).
  - Line 279 area: same for the "View all reports" / secondary action.
  - Verify both targets resolve to `ReportsScreen` via the router after Task 21.

- [ ] **Step 5: `flutter analyze` — fix any issues in this file**

---

## Task 14: Supervisor dashboard — full web data

**Files:**
- Modify: `mobile/lib/features/supervisor/screens/supervisor_dashboard_screen.dart`

- [ ] **Step 1: Replace provider wiring** (top of `build`):

```dart
    final dashboardAsync = ref.watch(supervisorDashboardProvider);
```

- [ ] **Step 2: Replace the body** to render 6 overview cards, 3 risk cards, this-week stats, quality indicators, and quick links. Full replacement of the `build` method body:

```dart
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: dashboardAsync.when(
        data: (d) => _buildContent(context, ref, d),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
            error: e,
            onRetry: () => ref.invalidate(supervisorDashboardProvider)),
      ),
    );
```

- [ ] **Step 3: Add `_buildContent`, `_StatCard`, `_SectionTitle`, `_QualityRow`, `_WeekStatsTable`, `_QuickLink` helpers** (reuse existing `_StatCard`; add the new ones):

```dart
  Widget _buildContent(BuildContext context, WidgetRef ref, AdminDashboardData d) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.district.isNotEmpty ? 'Overview — ${d.district}' : 'Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monitor CHWs, patients, and program quality',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(title: 'Total CHWs', value: '${d.totalChws}', icon: Icons.people_outline, color: AppColors.primary),
              _StatCard(title: 'Active Today', value: '${d.activeChwsToday}', icon: Icons.check_circle_outline, color: AppColors.success),
              _StatCard(title: 'Total Patients', value: '${d.totalPatients}', icon: Icons.people_outline, color: AppColors.primary),
              _StatCard(title: 'Assessments', value: '${d.totalAssessments}', icon: Icons.assignment_outlined, color: AppColors.primary),
              _StatCard(title: 'Deliveries', value: '${d.totalDeliveries}', icon: Icons.child_friendly_outlined, color: AppColors.success),
              _StatCard(title: 'Referrals', value: '${d.totalReferrals}', icon: Icons.directions_walk_outlined, color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Risk Distribution'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(title: 'High Risk', value: '${d.highRiskActive}', icon: Icons.warning_amber_rounded, color: AppColors.error),
              _StatCard(title: 'Mid Risk', value: '${d.midRiskActive}', icon: Icons.warning_amber_rounded, color: AppColors.warning),
              _StatCard(title: 'Low Risk', value: '${d.lowRiskActive}', icon: Icons.check_circle_outline, color: AppColors.success),
              _StatCard(title: 'Pending Escalations', value: '${d.pendingEscalations}', icon: Icons.notifications_active_outlined, color: AppColors.error),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('This Week'),
          const SizedBox(height: 12),
          _WeekStatsTable(week: d.thisWeek, previous: d.lastWeek),
          const SizedBox(height: 24),
          const _SectionTitle('Quality Indicators'),
          const SizedBox(height: 12),
          _QualityRow(label: 'Referral completion', value: d.referralCompletionRate, icon: Icons.directions_walk_outlined),
          _QualityRow(label: 'PNC1 completion', value: d.pnc1CompletionRate, icon: Icons.child_care_outlined),
          _QualityRow(label: 'PHQ2 positive this month', value: d.phq2PositiveThisMonth.toDouble(), icon: Icons.psychology_outlined, suffix: ''),
          _QualityRow(label: 'Growth alerts active', value: d.growthAlertsActive.toDouble(), icon: Icons.trending_up, suffix: ''),
          const SizedBox(height: 24),
          const _SectionTitle('Quick Actions'),
          const SizedBox(height: 12),
          _QuickLink(label: 'CHW Management', icon: Icons.badge_outlined, onTap: () => context.push('/supervisor/chws')),
          _QuickLink(label: 'High Risk Patients', icon: Icons.warning_amber_rounded, onTap: () => context.push('/supervisor/high-risk')),
          _QuickLink(label: 'Referral Analytics', icon: Icons.analytics_outlined, onTap: () => context.push('/supervisor/referrals')),
          _QuickLink(label: 'Reports', icon: Icons.assessment_outlined, onTap: () => context.push('/supervisor/reports')),
          _QuickLink(label: 'Approvals', icon: Icons.approval_outlined, onTap: () => context.push('/supervisor/approvals')),
        ],
      ),
    );
  }
```

- [ ] **Step 4: Add the helper widgets** at the bottom (keep `_StatCard`; remove `_RecentActivityFeed`, `_activityColor`, `_activityIcon`):

```dart
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class _WeekStatsTable extends StatelessWidget {
  final WeekStats week;
  final WeekStats previous;
  const _WeekStatsTable({required this.week, required this.previous});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Assessments', week.assessments, previous.assessments),
      ('Referrals', week.referrals, previous.referrals),
      ('Deliveries', week.deliveries, previous.deliveries),
      ('New Patients', week.newPatients, previous.newPatients),
    ];
    return AppCard(
      child: Column(
        children: rows.map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(r.$1, style: const TextStyle(fontSize: 14))),
                Text('${r.$2}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(width: 8),
                Text('(prev ${r.$3})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QualityRow extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final String suffix;
  const _QualityRow({
    required this.label,
    required this.value,
    required this.icon,
    this.suffix = '%',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            Text('${value.toStringAsFixed(1)}$suffix',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickLink({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: `flutter analyze` — fix issues in this file**

---

## Task 15: CHW list screen

**Files:**
- Create: `mobile/lib/features/supervisor/screens/chw_list_screen.dart`

- [ ] **Step 1: Add providers to `supervisor_repository.dart`**

```dart
final chwsProvider = FutureProvider<List<ChwSummary>>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.listChws();
});
```

- [ ] **Step 2: Implement the screen**

```dart
// lib/features/supervisor/screens/chw_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../supervisor_repository.dart';

class ChwListScreen extends ConsumerWidget {
  const ChwListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chwsAsync = ref.watch(chwsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CHW Management'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/supervisor/chws/new'),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add CHW'),
      ),
      body: chwsAsync.when(
        data: (chws) {
          if (chws.isEmpty) {
            return const EmptyState(
              icon: Icons.badge_outlined,
              title: 'No CHWs',
              subtitle: 'Tap "Add CHW" to create the first account',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: chws.length,
            itemBuilder: (context, i) {
              final c = chws[i];
              final color = c.status == 'active'
                  ? AppColors.success
                  : c.status == 'inactive_warning'
                      ? AppColors.warning
                      : AppColors.error;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => context.push('/supervisor/chws/${c.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.fullName,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              c.status.replaceAll('_', ' '),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(c.facility ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _mini('${c.patientCount}', 'patients'),
                          _mini('${c.assessmentCount}', 'assessments'),
                          _mini('${c.highRiskCount}', 'high risk'),
                          _mini(
                              '${c.referralCompletionRate.toStringAsFixed(0)}%',
                              'ref. rate'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
            error: e, onRetry: () => ref.invalidate(chwsProvider)),
      ),
    );
  }

  Widget _mini(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
```

- [ ] **Step 3: `flutter analyze` — fix issues**

---

## Task 16: CHW form screen (create)

**Files:**
- Create: `mobile/lib/features/supervisor/screens/chw_form_screen.dart`

- [ ] **Step 1: Add a notifier provider for creating CHWs** to `supervisor_repository.dart`:

```dart
class CreateChwNotifier extends StateNotifier<AsyncValue<int?>> {
  final SupervisorRepository _repo;
  CreateChwNotifier(this._repo) : super(const AsyncData(null));

  Future<int?> create(
      String username, String password, String fullName, String facility) async {
    state = const AsyncLoading();
    try {
      final id = await _repo.createChw(username, password, fullName, facility);
      state = AsyncData(id);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createChwProvider =
    StateNotifierProvider<CreateChwNotifier, AsyncValue<int?>>((ref) {
  return CreateChwNotifier(ref.read(supervisorRepositoryProvider));
});
```

- [ ] **Step 2: Implement the screen** (reuses `AppTextField` from `core/widgets/app_text_field.dart` — verify exact API; it follows `labelText`, `controller`, `obscureText`, `enabled` pattern used elsewhere):

```dart
// lib/features/supervisor/screens/chw_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../supervisor_repository.dart';

class ChwFormScreen extends ConsumerStatefulWidget {
  const ChwFormScreen({super.key});

  @override
  ConsumerState<ChwFormScreen> createState() => _ChwFormScreenState();
}

class _ChwFormScreenState extends ConsumerState<ChwFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _facility = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _fullName.dispose();
    _facility.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(createChwProvider.notifier).create(
            _username.text.trim(),
            _password.text,
            _fullName.text.trim(),
            _facility.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CHW account created')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create CHW. Check the details and try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating =
        ref.watch(createChwProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Add CHW')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _fullName,
                labelText: 'Full name',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _username,
                labelText: 'Username',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _password,
                labelText: 'Temporary password',
                obscureText: true,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _facility,
                labelText: 'Facility',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                creating ? 'Creating…' : 'Create CHW Account',
                onPressed: creating ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

> Note: verify `AppTextField` exposes `labelText`, `controller`, `obscureText`, `enabled`, and `textCapitalization`. If it lacks `textCapitalization` or `enabled`, drop those parameters and conditionally guard `_submit` with a local `bool _submitting` instead.

- [ ] **Step 3: `flutter analyze` — fix issues**

---

## Task 17: CHW detail screen

**Files:**
- Create: `mobile/lib/features/supervisor/screens/chw_detail_screen.dart`

- [ ] **Step 1: Add family provider** to `supervisor_repository.dart`:

```dart
final chwStatsProvider = FutureProvider.family<ChwDetailStats, int>((ref, id) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getChwStats(id);
});
```

- [ ] **Step 2: Implement the screen**

```dart
// lib/features/supervisor/screens/chw_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../supervisor_repository.dart';

class ChwDetailScreen extends ConsumerWidget {
  final int chwId;
  const ChwDetailScreen({super.key, required this.chwId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(chwStatsProvider(chwId));

    return Scaffold(
      appBar: AppBar(title: const Text('CHW Details')),
      body: statsAsync.when(
        data: (s) => _buildContent(context, ref, s),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
            error: e, onRetry: () => ref.invalidate(chwStatsProvider(chwId))),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ChwDetailStats s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(s.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                )),
        const SizedBox(height: 4),
        Text(s.facility ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                )),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('${s.patientCount}', 'patients'),
            _stat('${s.assessmentCount}', 'assessments'),
            _stat('${s.referralCount}', 'referrals'),
            _stat('${s.referralCompletionRate.toStringAsFixed(0)}%',
                'ref. rate'),
          ],
        ),
        const SizedBox(height: 24),
        const _title('Risk Distribution'),
        const SizedBox(height: 8),
        _riskBars(s),
        const SizedBox(height: 24),
        const _title('ANC Completion'),
        const SizedBox(height: 8),
        _completionBars(s.ancCompletion, 9),
        const SizedBox(height: 24),
        const _title('PNC Completion'),
        const SizedBox(height: 8),
        _completionBars(s.pncCompletion, 4),
        const SizedBox(height: 24),
        const _title('Weekly Activity'),
        const SizedBox(height: 8),
        _activityTable(s),
        const SizedBox(height: 24),
        const _title('Patients'),
        const SizedBox(height: 8),
        if (s.patients.isEmpty)
          const EmptyState(
              icon: Icons.people_outline,
              title: 'No patients',
              subtitle: 'This CHW has no patients yet'),
        ...s.patients.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(p.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  if (p.riskLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (p.riskLevel == 'high risk'
                                ? AppColors.error
                                : p.riskLevel == 'mid risk'
                                    ? AppColors.warning
                                    : AppColors.success)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        p.riskLevel!,
                        style: TextStyle(
                            fontSize: 11,
                            color: p.riskLevel == 'high risk'
                                ? AppColors.error
                                : p.riskLevel == 'mid risk'
                                    ? AppColors.warning
                                    : AppColors.success),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton.outline(
          'Deactivate CHW',
          iconLeft: Icons.block_outlined,
          onPressed: () => _toggleActive(context, ref, s, false),
        ),
      ],
    );
  }

  Future<void> _toggleActive(
      BuildContext context, WidgetRef ref, ChwDetailStats s, bool activate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(activate ? 'Activate CHW?' : 'Deactivate CHW?'),
        content: Text(
            '${activate ? "Activate" : "Deactivate"} ${s.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final repo = ref.read(supervisorRepositoryProvider);
      if (activate) {
        await repo.activateUser(s.chwId);
      } else {
        await repo.deactivateUser(s.chwId);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(activate ? 'CHW activated' : 'CHW deactivated')),
      );
      ref.invalidate(chwStatsProvider(s.chwId));
      ref.invalidate(chwsProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed. Try again.')),
      );
    }
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      );

  Widget _riskBars(ChwDetailStats s) {
    final items = [
      (s.riskDistribution['high'] ?? 0, AppColors.error, 'High'),
      (s.riskDistribution['mid'] ?? 0, AppColors.warning, 'Mid'),
      (s.riskDistribution['low'] ?? 0, AppColors.success, 'Low'),
    ];
    final max = items.map((e) => e.$1).fold<int>(1, (a, b) => a > b ? a : b);
    return AppCard(
      child: Column(
        children: items.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 48, child: Text(e.$3, style: const TextStyle(fontSize: 13))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.$1 / max,
                      minHeight: 8,
                      backgroundColor: e.$2.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(e.$2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.$1}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _completionBars(Map<String, double> map, int count) {
    return AppCard(
      child: Column(
        children: List.generate(count, (i) {
          final key = map.containsKey('visit_$i')
              ? 'visit_$i'
              : 'pnc_${i}';
          final value = map[key] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 64, child: Text(key, style: const TextStyle(fontSize: 12))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value / 100,
                      minHeight: 8,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${value.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }).where((w) => w != null).toList(),
      ),
    );
  }

  Widget _activityTable(ChwDetailStats s) {
    return AppCard(
      child: Column(
        children: s.weeklyActivity.isEmpty
            ? const [Text('No activity recorded')]
            : s.weeklyActivity.map((w) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(w.week, style: const TextStyle(fontSize: 13))),
                      Text('${w.assessments} assessments',
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Text('${w.referrals} referrals',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }
}

class _title extends StatelessWidget {
  final String text;
  const _title(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
    );
  }
}
```

> Note: `_completionBars` above misuses `.where((w) => w != null)` on a non-nullable list. Replace the body with a plain loop version:
> ```dart
>   Widget _completionBars(Map<String, double> map, int count) {
>     final rows = <Widget>[];
>     for (var i = 1; i <= count; i++) {
>       final key = map.containsKey('visit_$i') ? 'visit_$i' : 'pnc_$i';
>       final value = map[key] ?? 0;
>       rows.add(Padding(
>         padding: const EdgeInsets.symmetric(vertical: 4),
>         child: Row(
>           children: [
// ...
```
> Use `visit_$i` for ANC (i in 1..8) and `pnc_$i` for PNC (i in 1..3) by passing a prefix argument: call `_completionBars(s.ancCompletion, 'visit_', 8)` and `_completionBars(s.pncCompletion, 'pnc_', 3)`. Implement accordingly.

- [ ] **Step 3: `flutter analyze` — fix issues**

---

## Task 18: High-risk patients screen

**Files:**
- Create: `mobile/lib/features/supervisor/screens/high_risk_patients_screen.dart`

- [ ] **Step 1: Add provider** to `supervisor_repository.dart`:

```dart
final highRiskPatientsProvider =
    FutureProvider<List<HighRiskPatient>>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getHighRiskPatients();
});
```

- [ ] **Step 2: Implement the screen**

```dart
// lib/features/supervisor/screens/high_risk_patients_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../supervisor_repository.dart';

class HighRiskPatientsScreen extends ConsumerWidget {
  const HighRiskPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(highRiskPatientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('High Risk Patients'),
        automaticallyImplyLeading: false,
      ),
      body: patientsAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_user_outlined,
              title: 'No high-risk patients',
              subtitle: 'All active patients are within assessment cadence',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: patients.length,
            itemBuilder: (context, i) {
              final p = patients[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.fullName,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (p.flagged)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Flagged',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (p.age != null) '${p.age} yrs',
                          if (p.facility != null) p.facility!,
                          if (p.chwName != null) 'CHW: ${p.chwName}',
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _chip(
                            '${p.daysSinceAssessment}d since last assessment',
                            p.flagged ? AppColors.error : AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            'Conf ${(p.confidence * 100).toStringAsFixed(0)}%',
                            AppColors.primary,
                          ),
                        ],
                      ),
                      if (p.systolicBp != null || p.bloodSugar != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          [
                            if (p.systolicBp != null)
                              'BP ${p.systolicBp!.toStringAsFixed(0)}',
                            if (p.bloodSugar != null)
                              'Glucose ${p.bloodSugar!.toStringAsFixed(1)}',
                          ].join(' · '),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                      if (!p.referralMade) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => context
                                .push('/pregnancies')
                                .then((_) => ref.invalidate(highRiskPatientsProvider)),
                            icon: const Icon(Icons.directions_walk_outlined,
                                size: 18),
                            label: const Text('Refer'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
            error: e,
            onRetry: () => ref.invalidate(highRiskPatientsProvider)),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
```

- [ ] **Step 3: `flutter analyze` — fix issues**

---

## Task 19: Referral analytics screen

**Files:**
- Create: `mobile/lib/features/supervisor/screens/referral_analytics_screen.dart`

- [ ] **Step 1: Add provider** to `supervisor_repository.dart`:

```dart
final referralAnalyticsProvider =
    FutureProvider<ReferralAnalytics>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getReferralAnalytics();
});
```

- [ ] **Step 2: Implement the screen**

```dart
// lib/features/supervisor/screens/referral_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../supervisor_repository.dart';

class ReferralAnalyticsScreen extends ConsumerWidget {
  const ReferralAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(referralAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Analytics'),
        automaticallyImplyLeading: false,
      ),
      body: analyticsAsync.when(
        data: (a) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const _title('Funnel'),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _row('Total referrals', '${a.totalReferrals}'),
                  _row('Sent', '${a.sent}'),
                  _row('Received', '${a.received}'),
                  _row('Patient arrived', '${a.patientArrived}'),
                  _row('Completion rate', '${a.completionRate.toStringAsFixed(1)}%'),
                  if (a.avgHoursToReceipt != null)
                    _row('Avg hours to receipt', '${a.avgHoursToReceipt!.toStringAsFixed(1)}'),
                  if (a.avgHoursToArrival != null)
                    _row('Avg hours to arrival', '${a.avgHoursToArrival!.toStringAsFixed(1)}'),
                  _row('High-risk referrals', '${a.highRiskReferrals}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _title('By Facility'),
            const SizedBox(height: 12),
            if (a.byFacility.isEmpty)
              const EmptyState(
                  icon: Icons.local_hospital_outlined,
                  title: 'No data',
                  subtitle: 'No referrals recorded yet')
            else
              ...a.byFacility.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BreakdownCard(
                    title: f.facilityName,
                    total: f.total,
                    arrived: f.arrived,
                    rate: f.completionRate,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const _title('By CHW'),
            const SizedBox(height: 12),
            if (a.byChw.isEmpty)
              const EmptyState(
                  icon: Icons.person_outline,
                  title: 'No data',
                  subtitle: 'No referrals recorded yet')
            else
              ...a.byChw.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BreakdownCard(
                    title: c.chwName,
                    total: c.total,
                    arrived: c.arrived,
                    rate: c.completionRate,
                  ),
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
            error: e,
            onRetry: () => ref.invalidate(referralAnalyticsProvider)),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final int total;
  final int arrived;
  final double rate;
  const _BreakdownCard({
    required this.title,
    required this.total,
    required this.arrived,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _metric('${total}', 'total'),
              const SizedBox(width: 20),
              _metric('${arrived}', 'arrived'),
              const SizedBox(width: 20),
              _metric('${rate.toStringAsFixed(1)}%', 'completion'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 6,
              backgroundColor: AppColors.success.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
}

class _title extends StatelessWidget {
  final String text;
  const _title(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
    );
  }
}
```

- [ ] **Step 3: `flutter analyze` — fix issues**

---

## Task 20: Reports screen rewrite

**Files:**
- Rewrite: `mobile/lib/features/supervisor/screens/reports_screen.dart`

- [ ] **Step 1: Implement the rewrite** (read current file first, then replace entirely):

```dart
// lib/features/supervisor/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_error_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../supervisor_repository.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final reportAsync =
        ref.watch(monthlyReportProvider((year: _year, month: _month)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _year,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                        value: DateTime.now().year - i,
                        child: Text('${DateTime.now().year - i}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _year = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _month,
                    decoration: const InputDecoration(labelText: 'Month'),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                            '${DateTime(0, i + 1).month} — ${_monthName(i + 1)}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _month = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reportAsync.when(
              data: (r) => _buildReport(context, r),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                error: e,
                onRetry: () => ref.invalidate(
                    monthlyReportProvider((year: _year, month: _month))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[m - 1];
  }

  Widget _buildReport(BuildContext context, MonthlyReport r) {
    final sections = <(String, List<(String, String)>)>[
      ('Workforce', [
        ('Total CHWs', '${r.totalChws}'),
        ('Active CHWs', '${r.activeChws}'),
      ]),
      ('Patients', [
        ('Total registered', '${r.totalPatientsRegistered}'),
        ('New this month', '${r.newPatientsThisMonth}'),
      ]),
      ('Assessments & Risk', [
        ('Total assessments', '${r.totalAssessments}'),
        ('High risk detected', '${r.highRiskDetected}'),
        ('Mid risk detected', '${r.midRiskDetected}'),
        ('Low risk detected', '${r.lowRiskDetected}'),
      ]),
      ('Referrals', [
        ('Total referrals', '${r.totalReferrals}'),
        ('Completion rate', '${r.referralCompletionRate.toStringAsFixed(1)}%'),
      ]),
      ('Deliveries & PNC', [
        ('Total deliveries', '${r.totalDeliveries}'),
        ('Live births', '${r.liveBirths}'),
        ('Stillbirths', '${r.stillbirths}'),
        ('PNC1 completion', '${r.pnc1CompletionRate.toStringAsFixed(1)}%'),
        ('PNC2 completion', '${r.pnc2CompletionRate.toStringAsFixed(1)}%'),
        ('PNC3 completion', '${r.pnc3CompletionRate.toStringAsFixed(1)}%'),
      ]),
      ('Maternal Health', [
        ('PHQ2 screens performed', '${r.phq2ScreensPerformed}'),
        ('PHQ2 positive', '${r.phq2PositiveCount}'),
        ('Growth alerts generated', '${r.growthAlertsGenerated}'),
        ('Exclusive breastfeeding', '${r.exclusiveBreastfeedingRate.toStringAsFixed(1)}%'),
      ]),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          r.reportingPeriod,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${r.district} · ${r.region}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 20),
        ...sections.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.$1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: s.$2
                        .map((row) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(row.$1,
                                          style: const TextStyle(
                                              fontSize: 14))),
                                  Text(row.$2,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
```

- [ ] **Step 2: `flutter analyze` — fix issues**

---

## Task 21: Router wiring + dead Reports buttons

**Files:**
- Modify: `mobile/lib/core/router/app_router.dart`
- Modify: `mobile/lib/features/dashboard/screens/dashboard_screen.dart`

- [ ] **Step 1: Add imports for the 5 new screens** at the top of `app_router.dart`:

```dart
import '../../features/supervisor/screens/chw_list_screen.dart';
import '../../features/supervisor/screens/chw_form_screen.dart';
import '../../features/supervisor/screens/chw_detail_screen.dart';
import '../../features/supervisor/screens/high_risk_patients_screen.dart';
import '../../features/supervisor/screens/referral_analytics_screen.dart';
```

- [ ] **Step 2: Add sub-routes** inside the `/supervisor` `GoRoute` under the `StatefulShellBranch` (the branch whose root is `/supervisor`), after the existing `reports` route:

```dart
                  GoRoute(
                      path: 'chws',
                      builder: (_, __) => const ChwListScreen()),
                  GoRoute(
                      path: 'chws/new',
                      builder: (_, __) => const ChwFormScreen()),
                  GoRoute(
                    path: 'chws/:id',
                    builder: (_, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return ChwDetailScreen(chwId: id);
                    },
                  ),
                  GoRoute(
                      path: 'high-risk',
                      builder: (_, __) => const HighRiskPatientsScreen()),
                  GoRoute(
                      path: 'referrals',
                      builder: (_, __) => const ReferralAnalyticsScreen()),
```

> Note: `/supervisor/chws/new` conflicts with `/supervisor/chws/:id` if go_router matches `new` as an `:id`. go_router prioritizes static segments over parameters, so `chws/new` resolves correctly. Verify with `flutter run` after wiring.

- [ ] **Step 3: Fix dead Reports buttons in `dashboard_screen.dart`** — grep for `'Reports'` and `reports`; ensure every Reports action calls `context.push('/supervisor/reports')` (and that the route exists on the `/home` branch too — add `GoRoute(path: 'reports', builder: (_, __) => const ReportsScreen())` inside the `/home` branch if `dashboard_screen.dart` pushes `/home/reports`; otherwise standardize on `/supervisor/reports`).

- [ ] **Step 4: `flutter analyze` + `flutter test` — expect 0 errors and all tests green**

---

## Task 22: i18n strings (EN/FR)

**Files:**
- Modify: `mobile/lib/l10n/app_en.dart`
- Modify: `mobile/lib/l10n/app_fr.dart`

- [ ] **Step 1: Add EN keys** following the existing flat-map format (under a `supervisor.` and `dashboard.` namespace):

```dart
  'supervisor.overview': 'Overview',
  'supervisor.totalChws': 'Total CHWs',
  'supervisor.activeToday': 'Active Today',
  'supervisor.totalPatients': 'Total Patients',
  'supervisor.assessments': 'Assessments',
  'supervisor.deliveries': 'Deliveries',
  'supervisor.referrals': 'Referrals',
  'supervisor.riskDistribution': 'Risk Distribution',
  'supervisor.highRisk': 'High Risk',
  'supervisor.midRisk': 'Mid Risk',
  'supervisor.lowRisk': 'Low Risk',
  'supervisor.pendingEscalations': 'Pending Escalations',
  'supervisor.thisWeek': 'This Week',
  'supervisor.qualityIndicators': 'Quality Indicators',
  'supervisor.referralCompletion': 'Referral completion',
  'supervisor.pnc1Completion': 'PNC1 completion',
  'supervisor.phq2PositiveMonth': 'PHQ2 positive this month',
  'supervisor.growthAlertsActive': 'Growth alerts active',
  'supervisor.chwManagement': 'CHW Management',
  'supervisor.highRiskPatients': 'High Risk Patients',
  'supervisor.referralAnalytics': 'Referral Analytics',
  'supervisor.reports': 'Reports',
  'supervisor.approvals': 'Approvals',
  'supervisor.addChw': 'Add CHW',
  'supervisor.createChwAccount': 'Create CHW Account',
  'supervisor.chwDetails': 'CHW Details',
  'supervisor.deactivateChw': 'Deactivate CHW',
  'supervisor.activateChw': 'Activate CHW',
  'supervisor.monthlyReport': 'Monthly Report',
  'supervisor.noChws': 'No CHWs',
  'supervisor.noHighRisk': 'No high-risk patients',
  'supervisor.noReferralData': 'No data',
  'dashboard.programOverview': 'Program Overview',
  'dashboard.riskDistribution': 'Risk Distribution',
  'dashboard.escalations': 'Escalations',
  'dashboard.noRecentEscalations': 'No recent escalations',
  'dashboard.activePregnancies': 'Active Pregnancies',
  'dashboard.pendingReferrals': 'Pending Referrals',
  'dashboard.upcomingVisits': 'Upcoming Visits',
  'dashboard.noAssessments': 'No assessments yet',
```

- [ ] **Step 2: Add FR keys** with the same keys and French values (e.g. `'supervisor.overview': 'Vue d\u2019ensemble'`, `'supervisor.totalChws': 'Agents de santé'`, `'supervisor.monthlyReport': 'Rapport mensuel'`, `'dashboard.programOverview': 'Vue d\u2019ensemble du programme'`, etc.).

- [ ] **Step 3: Wire the new screens/sections to use `tr(ref, 'supervisor.monthlyReport')`-style lookups for titles and section headers.** The existing `dashboard_screen.dart` already uses `tr(ref, '...')` for quick actions; match that pattern. If the volume of wiring is high, apply it at least to all section titles and AppBar titles in the new screens.

- [ ] **Step 4: `flutter analyze` — 0 errors**

---

## Task 23: Full static analysis + test suite

**Files:** none (verification)

- [ ] **Step 1: `cd mobile && flutter analyze`** — fix every error until 0
- [ ] **Step 2: `cd mobile && flutter test`** — all tests green (existing + new)
- [ ] **Step 3: Grep for leftover references** to removed symbols:
  - `supervisorStatsProvider`, `supervisorActivityProvider`, `StatsData`, `getReports`, `getRecentActivity` — all must be gone
- [ ] **Step 4: Grep for dead routes** in `dashboard_screen.dart` that push paths not registered in `app_router.dart` (`context.push('/...')` strings), and reconcile

---

## Task 24: Device verification

**Files:** none (manual)

- [ ] **Step 1: Start the backend** (`uvicorn app.main:app --host 0.0.0.0 --port 8000` from `backend/`) and confirm the web app still works at `http://localhost:5173`
- [ ] **Step 2: Run the Flutter app** on a device/emulator pointed at `http://192.168.1.121:8000`
- [ ] **Step 3: Log in as admin** → verify Home shows Program Overview cards, Risk Distribution donut, Escalations feed, and quick actions still work
- [ ] **Step 4: Open Supervisor tab** → verify 6 overview cards, risk cards, this-week table, quality indicators, quick links all populate from `/api/v1/admin/dashboard`
- [ ] **Step 5: CHW Management** → list loads; tap a CHW → detail with risk bars/ANC/PNC/weekly activity/patients; "Add CHW" creates an account (verify it appears in the list and can log in); deactivate/activate reflects immediately
- [ ] **Step 6: High Risk Patients** → list matches web; flagged badge on stale assessments
- [ ] **Step 7: Referral Analytics** → funnel + by-facility + by-CHW match web
- [ ] **Step 8: Reports** → pick Aug 2026 → values match web MonthlyReportPage; switch months updates
- [ ] **Step 9: Offline fallback** → enable airplane mode → Home summary + escalation feed still render from local drift; supervisor screens show retryable error states (they are live-only)
- [ ] **Step 10: Switch app locale to FR** → new section titles render in French
- [ ] **Step 11: Log in as supervisor role** (not admin) → supervisor tab visible, data scoped to district; CHW actions hidden if backend rejects them (verify graceful error)

---

## Verification / Definition of Done

1. `flutter analyze` reports **0 errors**
2. `flutter test` — all tests pass (new model/repo/widget tests + existing suite)
3. All 5 supervisor pages + Home sections mirror the web app's live data
4. Offline mode: Home summary + escalation feed fall back to drift; other views show clear retryable errors
5. No dead buttons: every Quick Action/Reports entry resolves to a real screen
6. EN/FR toggle covers all new UI strings
7. Supervisor and admin roles both verified on-device
