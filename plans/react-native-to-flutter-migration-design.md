# React Native → Flutter Migration Design

## Overview

This document specifies the migration of the MamaSafe mobile app from Expo/React Native to Flutter, using a big-bang rewrite approach. The existing backend (FastAPI + PostgreSQL + XGBoost), ML model, and web frontend remain unchanged.

**Date:** 2026-07-30  
**Status:** Draft  
**Approach:** Big-bang rewrite, Flutter + Riverpod + Drift + Dio

## 1. Project Context

### Current Mobile App (React Native)
- **Framework:** Expo SDK 52, React 18.3, TypeScript 5.3, NativeWind 4
- **State:** Zustand (auth, assessments, referrals) with AsyncStorage persistence
- **Navigation:** Expo Router with 2 groups (auth/main), 4 tabs
- **Features:** Auth, Assessment, History, Dashboard, Referrals
- **i18n:** i18next, English + French
- **Offline:** AsyncStorage queue for assessments + referrals, auto-sync on reconnect
- **Testing:** Jest + React Native Testing Library (6 test files)
- **Backend API:** FastAPI returning `snake_case` JSON

### Why Flutter?
- **Performance on low-end Android:** No JS bridge, compiles to native ARM, better on devices common in Cameroon
- **Developer experience:** Cohesive tooling, type-safe by default, single-language ecosystem

## 2. Technology Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Framework** | Flutter 3.x + Dart 3.x | Latest stable |
| **State Management** | Riverpod 2 + Repository pattern | Compile-safe, no context dependency, testable |
| **Navigation** | GoRouter | Declarative, deep linking, auth redirect guards |
| **Local DB** | Drift (SQLite) | Type-safe queries, relational model for offline-first |
| **Networking** | Dio + freezed for DTOs | JWT interceptor, offline queue support |
| **Serialization** | freezed + json_serializable | Immutable models, `snake_case` via `@JsonKey` |
| **i18n** | slang | Compile-safe, Dart-first, no runtime overhead |
| **Offline Sync** | Drift + PendingOps table | Relational cache + mutation queue |
| **Testing** | flutter_test + integration_test | Framework-native |
| **SHAP Viz** | CustomPainter | Lightweight, native-drawn, no extra deps |
| **Env Config** | flutter_dotenv | Environment-specific API URLs |

## 3. Architecture

### 3.1 Folder Structure

```
mobile/
├── lib/
│   ├── main.dart                    # App entry, provider scope
│   ├── app/
│   │   ├── app.dart                 # MaterialApp widget
│   │   ├── router.dart              # GoRouter config
│   │   └── theme.dart               # Design tokens, theme
│   ├── core/
│   │   ├── network/
│   │   │   ├── api_client.dart      # Dio instance + JWT interceptor
│   │   │   ├── api_exceptions.dart  # Typed error classes
│   │   │   └── connectivity.dart    # Network state stream
│   │   ├── storage/
│   │   │   ├── database.dart        # Drift database definition
│   │   │   └── pending_ops.dart     # Offline mutation queue
│   │   ├── widgets/                 # Shared UI components
│   │   │   ├── button.dart
│   │   │   ├── card.dart
│   │   │   ├── input.dart
│   │   │   ├── risk_badge.dart
│   │   │   ├── language_toggle.dart
│   │   │   └── shap_chart.dart      # CustomPainter SHAP viz
│   │   └── utils/
│   │       ├── extensions.dart
│   │       └── formatters.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/        # Login screen
│   │   ├── assessment/
│   │   │   ├── data/                # API DTOs, repository impl
│   │   │   ├── domain/              # Models, repository interface
│   │   │   └── presentation/        # Assess form + Result screen
│   │   ├── history/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/        # List + search
│   │   ├── dashboard/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/        # Stats + alerts
│   │   ├── referrals/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/        # List + create
│   │   ├── anc/                     # Phase 3
│   │   ├── postnatal/               # Phase 3
│   │   └── growth/                  # Phase 3
│   ├── models/                      # Shared domain models
│   └── l10n/                        # slang-generated localization
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── pubspec.yaml
└── .env
```

### 3.2 Data Flow

```
                     ┌──────────────────┐
                     │   FastAPI Backend │
                     │  (snake_case JSON)│
                     └────────┬─────────┘
                              │ Dio + JWT interceptor
                     ┌────────▼─────────┐
                     │   Repository     │
                     │  (snake→camel    │
                     │   @JsonKey)      │
                     └──┬──────────┬────┘
                        │          │
               ┌────────▼──┐  ┌────▼────────┐
               │  Drift DB  │  │  PendingOps │
               │  (SQLite)  │  │  (offline)  │
               └────────┬───┘  └────┬────────┘
                        │           │
               ┌────────▼───────────▼────┐
               │      Riverpod Provider  │
               │      (StreamProvider)   │
               └────────────────┬────────┘
                                │
                     ┌──────────▼──────────┐
                     │  Widget (Consumer)  │
                     │  Build → Show data  │
                     └─────────────────────┘
```

### 3.3 Offline-First Strategy

- **Cache layer:** Drift database mirrors server data (patients, assessments, referrals, facilities). Repository always reads from Drift first.
- **Pending operations:** Mutations made offline (create assessment, create referral) are stored in a `pending_ops` table with: operation type, endpoint, payload, created_at.
- **Sync trigger:** `connectivity_plus` package detects network changes. On reconnect, replay pending ops in FIFO order. On success, update Drift cache. On conflict, resolve by `updated_at` timestamp.
- **Optimistic UI:** Repositories write to Drift immediately for mutations, then sync to server. UI rebuilds from Drift streams, so the user always sees their latest data regardless of connectivity.

## 4. Feature Map & Build Phases

### Phase 1 — Core Flows
| Screen | Route | Notes |
|--------|-------|-------|
| Login | `/login` | JWT auth, store token securely |
| Assess | `/assess` | Form with 6 vital inputs (age, BP, BS, temp, HR) + validation |
| Result | `/assess/result` | Risk badge, probability distribution, SHAP bar chart via CustomPainter |
| History | `/history` | Paginated list, pull-to-refresh, search by date/patient |
| Language Toggle | — | Persistent via SharedPreferences, rebuild with slang |

### Phase 2 — Operations & Referrals
| Screen | Route | Notes |
|--------|-------|-------|
| Dashboard | `/dashboard` | Risk distribution bar chart, critical alerts count |
| Referrals | `/referrals` | Status badges (pending/sent/received/arrived), filterable list |
| Referral Create | `/referrals/new` | Emergency referral form (high-risk assessments only) |
| Facility Directory | `/facilities` | Searchable facility list with suggestions |

### Phase 3 — Maternity & Growth (new features)
| Screen | Route | Notes |
|--------|-------|-------|
| Patient Registration | `/patients/new` | Register patient + pregnancy |
| ANC Schedule | `/anc` | Visit list, auto-scheduled from LMP |
| ANC Visit Form | `/anc/visit` | Log visit data |
| Postnatal | `/postnatal` | Delivery logging, PNC visit list |
| PNC Visit Form | `/postnatal/visit` | Log PNC visit |
| Growth Tracker | `/growth` | Weight entry, WHO z-score chart |
| Growth Alert | `/growth/alerts` | Faltering alerts |

### Phase 4 — Supervisor & Advanced
| Screen | Route | Notes |
|--------|-------|-------|
| Supervisor Dashboard | `/supervisor` | CHW performance, high-risk registry |
| Monthly Reports | `/reports` | CHW-level monthly statistics |
| MH Screening | `/mh-screening` | PHQ-2 questionnaire |
| CHW Management | `/supervisor/chws` | Manage CHW accounts |

## 5. Navigation & Routing

GoRouter with redirect guards:

```
/login                    → AuthGuard (redirect to /assess if logged in)
/assess                   → AuthGuard (redirect to /login if not authenticated)
/assess/result
/history
/dashboard
/referrals
/referrals/new
/facilities
```

GoRouter's `redirect` callback checks for a valid JWT token. No token → redirect to `/login`.

## 6. State Management

Riverpod providers by layer:

| Provider Type | Purpose | Example |
|---|---|---|
| `Repository` | Data access (API + Drift) | `assessmentRepositoryProvider` |
| `NotifierProvider` | UI state + actions | `assessmentFormProvider` |
| `StreamProvider` | Reactive DB queries | `assessmentListProvider` |
| `FutureProvider` | One-shot fetches | `dashboardStatsProvider` |

Each feature module owns its providers. No global state except auth token + locale preference.

## 7. Networking & API Integration

- **Dio** instance configured with base URL from `.env`, JWT interceptor, timeout
- **401 interceptor** clears stored token, redirects to `/login`
- **Response DTOs** use `@JsonKey(name: ...)` for all `snake_case` fields
- **Repository layer** maps DTOs → domain models, caches in Drift
- **Offline queue** intercepts Dio requests when offline, stores in PendingOps, replays on reconnect

## 8. Localization

- **slang** with English + French `.i18n.yaml` files
- Translations extracted from existing RN app (87 keys) and expanded for new features
- Locale persisted in SharedPreferences, provider rebuilds MaterialApp on change
- Riverpod provider exposes current locale + translation functions

## 9. SHAP Visualization

Custom widget using `CustomPainter`:

- Input: List of `FeatureContribution { name, value, direction }`
- Output: Horizontally stacked bars (red = risk-increasing, green = risk-decreasing)
- Bar length proportional to `|SHAP value|`
- Feature name label + numeric value label per bar

## 10. Testing Strategy

| Layer | Tool | Scope |
|---|---|---|
| Unit | `flutter_test` | Repository logic, model serialization, offline queue |
| Provider | riverpod test utilities | Provider state transitions |
| Widget | `flutter_test` | Key widget behavior |
| Integration | `integration_test` | Auth → Assess → Result path |
| E2E | patrol | Full referral flow including offline |

## 11. Migration Plan

1. Scaffold Flutter project with pubspec dependencies
2. Set up project structure (folders, router, theme, Drift schema)
3. Build core networking layer (Dio, JWT interceptor, Drift cache, PendingOps)
4. Implement Phase 1 screens (Auth, Assess, Result, History)
5. Implement Phase 2 screens (Dashboard, Referrals, Facilities)
6. Implement Phase 3 screens (ANC, Postnatal, Growth)
7. Implement Phase 4 screens (Supervisor, Reports, MH)
8. Add offline sync, polish, and edge case handling
9. Test on low-end Android device
10. Submit to Play Store

## 12. Non-Goals

- Migrating the web frontend to Flutter — stays as React 19
- Running ML inference on-device — backend handles predictions
- iOS support in initial release — Android-first for Cameroonian CHWs
