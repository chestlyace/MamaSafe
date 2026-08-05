# MamaSafe Web-to-Mobile Data Parity Design

## Overview

Port the web app's supervisor/admin data views and the web CHW dashboard data to the Flutter mobile app so that all roles (CHW, supervisor, admin) see the same database data on mobile that the web currently displays.

**Date:** 2026-08-01
**Status:** Approved (design reviewed by user)
**Approach:** Full parity, live API with offline fallback

## 1. Goals

- Mirror every web data view on mobile:
  - CHW dashboard (`DashboardPage`)
  - Supervisor dashboard (`SupervisorDashboardPage`)
  - CHW list + create + activate/deactivate (`CHWListPage`, `CHWDetailPage`)
  - High-risk patients (`HighRiskPatientsPage`)
  - Referral analytics (`ReferralAnalyticsPage`)
  - Monthly ministry report (`MonthlyReportPage`)
- Source data from the backend API like web does (live), falling back to the local drift DB when offline or the API is unreachable.
- Keep existing architecture: Riverpod + go_router + drift offline-first, 5-branch shell navigation, EN/FR i18n, Material 2 web-matching theme, `fl_chart` (already a dependency).
- Fix existing broken supervisor UI (fake activity feed, `getReports()` calling the monthly endpoint without `year`/`month`, dead "Reports" buttons).

## 2. Current State

### Web data sources (all exist in backend, no backend changes required)

| Web page | Endpoint | Key fields |
|---|---|---|
| `DashboardPage` | `GET /api/v1/dashboard/summary` | total_assessments, high/mid/low_risk_count + pct, total_patients, active_pregnancies, pending_referrals, upcoming_visits, recent_escalations |
| `SupervisorDashboardPage` | `GET /api/v1/admin/dashboard` | district, region, total_chws, active_chws_today, total_patients, total_assessments, total_deliveries, total_referrals, referral_completion_rate, high/mid/low_risk_active, pnc1_completion_rate, phq2_positive_this_month, growth_alerts_active, pending_escalations, this_week{assessments,referrals,deliveries,new_patients}, last_week |
| `CHWListPage` | `GET /api/v1/admin/chws` | id, full_name, username, facility, district, is_active, last_active, days_since_active, patient_count, assessment_count, referral_count, high_risk_count, referral_completion_rate, status |
| `CHWDetailPage` | `GET /api/v1/admin/chws/{id}/stats` | chw info, patient_count, assessment_count, referral_count, referral_completion_rate, risk_distribution{low,mid,high}, anc_completion{visit_1..8}, pnc_completion{pnc_1..3}, weekly_activity[4], patients[] |
| `HighRiskPatientsPage` | `GET /api/v1/admin/high-risk-patients?days_since_assessment=7` | patient_id, full_name, age, facility, chw_name, risk_level, confidence, last_assessment_date, days_since_assessment, flagged, systolic_bp, blood_sugar, referral_made |
| `ReferralAnalyticsPage` | `GET /api/v1/admin/referral-analytics` | total_referrals, sent, received, patient_arrived, completion_rate, avg_hours_to_receipt, avg_hours_to_arrival, high_risk_referrals, by_facility[], by_chw[] |
| `MonthlyReportPage` | `GET /api/v1/admin/report/monthly?year&month` | district, region, reporting_period, total_chws, active_chws, total_patients_registered, new_patients_this_month, total_assessments, high/mid/low_risk_detected, total_referrals, referral_completion_rate, total_deliveries, live_births, stillbirths, pnc1/2/3_completion_rate, phq2_screens_performed, phq2_positive_count, growth_alerts_generated, exclusive_breastfeeding_rate |
| (web `DashboardPage` escalation feed) | `GET /api/v1/risk-escalations/recent?days=7` | recent escalation events |

Also used by web CHW create/deactivate/activate:
`POST /api/v1/admin/users`, `PATCH /api/v1/admin/users/{id}/deactivate`, `PATCH /api/v1/admin/users/{id}/activate`

### Mobile current state

- **Home `DashboardScreen`** reads only local drift providers (assessments, patients, pregnancies, referrals). No live data, no donut/trend/escalation sections.
- **`SupervisorRepository`** (`features/supervisor/supervisor_repository.dart`) is minimal:
  - `getStats()` → `/api/v1/admin/dashboard` mapped to sparse `StatsData` (totalPatients, highRiskPatients, pendingEscalations, pendingApprovals=0)
  - `getRecentActivity()` → synthesizes a fake 3-item feed from `this_week` (not real activity)
  - `getReports()` → calls `/api/v1/admin/report/monthly` with **no year/month** (broken)
- **`SupervisorDashboardScreen`** shows 4 stat cards + fake activity feed + quick actions. Missing most web data and quick links.
- **`ReportsScreen`** has a weekly/monthly/quarterly selector and fake report list; the underlying `getReports()` is broken.
- **Home screen dead buttons**: "Reports" quick action (`dashboard_screen.dart:205`) and supervisor quick action "Reports" (`dashboard_screen.dart:279`) have `onPressed: () {}`.
- **i18n**: custom `LocalizationService` with `enStrings`/`frStrings` maps in `lib/l10n/`.

## 3. Architecture Decisions

### 3.1 Offline-fallback pattern (Approach A)

A single aggregate `FutureProvider` per screen that:
1. Checks `connectivityServiceProvider.currentValue`.
2. If online → calls the live API endpoint.
3. If offline, or the call throws → computes the same shape from the local drift DB.

The screen consumes the aggregate provider only. Local providers (`assessmentsProvider`, `patientsProvider`, `pregnanciesProvider`, `referralsProvider`) are reused for the fallback.

### 3.2 Data layer

**New file `features/dashboard/dashboard_repository.dart`:**
- `DashboardSummaryData` model: totalAssessments, highRiskCount, midRiskCount, lowRiskCount, highRiskPct, midRiskPct, lowRiskPct, totalPatients, activePregnancies, pendingReferrals, upcomingVisits, recentEscalations
- `DashboardSummaryRepository.getSummary()` → `GET /api/v1/dashboard/summary`
- `homeDashboardProvider` (FutureProvider<HomeDashboardData>): live-first, local-fallback aggregate
- `EscalationFeedItem` model: patientName, fromRisk, toRisk, escalationType, date, whatsappSent
- `recentEscalationsProvider`: live `GET /api/v1/risk-escalations/recent?days=7` (web feed shape), falling back to local `RiskEscalation` records from the existing `escalationsProvider` when offline/unreachable

**Enrich `features/supervisor/supervisor_repository.dart`:**
- Models: `AdminDashboardData`, `ChwSummary`, `ChwDetailStats`, `HighRiskPatient`, `ReferralAnalytics`, `ReferralFacilityStats`, `ReferralChwStats`, `MonthlyReport`
- Methods:
  - `getDashboard()` → `AdminDashboardData` (replaces `getStats()`; keep `StatsData`/`supervisorStatsProvider` names or migrate — prefer keeping existing provider names to limit churn, enriching the model behind `supervisorStatsProvider`)
  - `listChws()` → `List<ChwSummary>`
  - `getChwStats(int chwId)` → `ChwDetailStats`
  - `createChw(...)` → POST
  - `deactivateUser(int id)` / `activateUser(int id)` → PATCH
  - `getHighRiskPatients()` → `List<HighRiskPatient>`
  - `getReferralAnalytics()` → `ReferralAnalytics`
  - `getMonthlyReport(int year, int month)` → `MonthlyReport`
  - Fix `getReports()` — remove or repurpose; the monthly report is obtained via `getMonthlyReport(year, month)`.
- Providers: `chwListProvider`, `chwStatsProvider(id)`, `highRiskPatientsProvider`, `referralAnalyticsProvider`, `monthlyReportProvider(year, month)`, `createChwProvider`, `toggleUserActiveProvider`.

**Escalation feed (Home):** reuse existing `escalationsProvider` (`features/escalations/escalation_repository.dart`) which already syncs `/escalations` then falls back to local.

### 3.3 Screen plan

| Screen | File | Route | Content |
|---|---|---|---|
| Home dashboard | `dashboard_screen.dart` (edit) | `/home` | Keep header + quick actions + recent activity; add web data sections above quick actions: overview stat cards, risk cards, donut (fl_chart), weekly trend stacked bar, escalation feed, critical alerts |
| Supervisor dashboard | `supervisor_dashboard_screen.dart` (edit) | `/supervisor` | 6 overview cards, 3 risk cards, this-week section, quality indicators, quick links to new screens; remove fake activity feed |
| CHW list | new `features/supervisor/screens/chw_list_screen.dart` | `/supervisor/chws` | CHW rows + status badge + counts + create-CHW FAB |
| CHW create | new `features/supervisor/screens/chw_form_screen.dart` | `/supervisor/chws/new` | username, full_name, password, facility, district, region, whatsapp_number |
| CHW detail | new `features/supervisor/screens/chw_detail_screen.dart` | `/supervisor/chws/:id` | summary cards, risk donut, ANC/PNC completion bars, weekly activity, patient list, activate/deactivate |
| High-risk patients | new `features/supervisor/screens/high_risk_patients_screen.dart` | `/supervisor/high-risk` | patient rows (age, CHW, facility, days since assessment, BP, sugar, referral badge) |
| Referral analytics | new `features/supervisor/screens/referral_analytics_screen.dart` | `/supervisor/referrals` | summary cards, by-facility + by-CHW progress lists |
| Monthly report | `reports_screen.dart` (rewrite) | `/supervisor/reports` | year/month selectors + report sections |

### 3.4 Navigation changes (`app_router.dart`)

Add sub-routes under the supervisor branch:
- `/supervisor/chws`
- `/supervisor/chws/new`
- `/supervisor/chws/:id`
- `/supervisor/high-risk`
- `/supervisor/referrals`

Fix dead buttons: dashboard quick-action "Reports" and supervisor quick-action "Reports" → `context.push('/supervisor/reports')`.

### 3.5 i18n

Add all new UI strings to `lib/l10n/app_en.dart` and `lib/l10n/app_fr.dart` (English + French). Existing screens currently use hard-coded English; new screens will use `tr(ref, 'key')` for consistency with the localization service. Translate the new keys into French matching web translations where they exist (`t('manage_chws')`, `t('high_risk_patients')`, `t('referral_analytics')`, `t('monthly_report')`, `t('total_chws')`, `t('active_today')`, etc.).

### 3.6 Theme / widgets

Reuse existing `AppCard`, `AppButton` (primary/outline/secondary/text), `EmptyState`, `AppColors` (primary #E8637A, error, warning, success, accent, textPrimary, textSecondary, border, surfaceAlt). Donut via `fl_chart` `PieChart` with center total, matching web colors (red #ef4444, amber #d97706, green #16a34a → map to `AppColors.error/warning/success`).

## 4. Out of Scope

- New backend endpoints (all required data already exposed).
- Web changes.
- CSV download of monthly report on mobile (web-only; note as future).
- Changing the offline-first sync engine.

## 5. Verification

- `flutter analyze` → 0 errors, 0 warnings (including the pre-existing unused `lastWeek` warning fix in `supervisor_repository.dart:40`).
- Manual test on device against `http://192.168.1.121:8000` (admin + supervisor + CHW logins):
  - Home shows live summary when online; local counts when airplane-mode/offline.
  - Supervisor dashboard shows all 6 + 3 + quality indicators.
  - CHW list/detail create/deactivate round-trip works.
  - High-risk patients, referral analytics, monthly report render data matching web.
  - EN/FR switch covers new strings.
- No backend regression: `GET /api/v1/admin/dashboard` still 200.

## 6. Implementation Phases

1. **Repositories + models** (dashboard_repository.dart, supervisor_repository.dart enrichment, providers)
2. **Home screen** (web data sections + donut + trend + escalations + critical alerts)
3. **Supervisor dashboard + monthly report rewrite**
4. **CHW list / create / detail** (with activate/deactivate)
5. **High-risk patients + referral analytics**
6. **Router wiring + dead-button fixes + i18n strings**
7. `flutter analyze` + device verification
