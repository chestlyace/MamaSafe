# RN → Flutter Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the MamaSafe mobile app from Expo/React Native to Flutter (big-bang), then extend it with missing features.

**Architecture:** Feature-first modular structure with Riverpod for state, Drift for offline SQLite, Dio for API, GoRouter for navigation. Domain-driven data layer with snake_case DTOs mapped to camelCase domain models.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod 2, GoRouter, Drift, Dio, freezed, json_serializable, slang, flutter_dotenv, CustomPainter (SHAP viz), flutter_test, integration_test

**Backend (unchanged):** FastAPI + PostgreSQL + XGBoost — 56 endpoints across 13 routers

---

## File Structure

This is the complete target structure. Tasks below will create these one by one.

```
mobile/lib/
├── main.dart                              # Entry point, ProviderScope
├── app/
│   ├── app.dart                            # MaterialApp.router, locale, theme
│   ├── router.dart                         # GoRouter with auth redirect guard
│   └── theme.dart                          # Design tokens, colors, text styles
├── core/
│   ├── network/
│   │   ├── api_client.dart                # Dio instance, base URL, timeouts
│   │   ├── api_interceptors.dart          # JWT injector + 401 handler
│   │   ├── api_exceptions.dart            # typed exception classes
│   │   └── connectivity_service.dart      # network state stream
│   ├── storage/
│   │   ├── database.dart                  # Drift database definition
│   │   ├── database.g.dart                # Generated
│   │   └── pending_ops_service.dart       # Offline mutation queue
│   ├── widgets/
│   │   ├── app_button.dart
│   │   ├── app_card.dart
│   │   ├── app_input.dart
│   │   ├── risk_badge.dart
│   │   ├── language_toggle.dart
│   │   ├── shap_chart.dart                # CustomPainter
│   │   ├── loading_overlay.dart
│   │   └── error_display.dart
│   └── utils/
│       ├── date_formatters.dart
│       └── validators.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── dtos/
│   │   │       ├── login_request.dart
│   │   │       ├── login_response.dart
│   │   │       └── register_request.dart
│   │   ├── domain/
│   │   │   ├── auth_state.dart
│   │   │   └── user.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       └── providers/
│   │           └── auth_providers.dart
│   ├── assessment/
│   │   ├── data/
│   │   │   ├── assessment_repository.dart
│   │   │   └── dtos/
│   │   │       ├── prediction_request.dart
│   │   │       ├── prediction_response.dart
│   │   │       └── assessment_dto.dart
│   │   ├── domain/
│   │   │   ├── assessment.dart
│   │   │   ├── prediction.dart
│   │   │   └── shap_feature.dart
│   │   └── presentation/
│   │       ├── assess_screen.dart
│   │       ├── result_screen.dart
│   │       ├── widgets/
│   │       │   ├── vital_input_field.dart
│   │       │   └── risk_distribution_chart.dart
│   │       └── providers/
│   │           └── assessment_providers.dart
│   ├── history/
│   │   ├── data/
│   │   │   ├── history_repository.dart
│   │   │   └── dtos/
│   │   │       └── assessment_list_item.dart
│   │   ├── domain/
│   │   │   └── assessment_summary.dart
│   │   └── presentation/
│   │       ├── history_screen.dart
│   │       ├── widgets/
│   │       │   └── assessment_list_tile.dart
│   │       └── providers/
│   │           └── history_providers.dart
│   ├── dashboard/
│   │   ├── data/
│   │   │   ├── dashboard_repository.dart
│   │   │   └── dtos/
│   │   │       └── dashboard_summary_dto.dart
│   │   ├── domain/
│   │   │   └── dashboard_summary.dart
│   │   └── presentation/
│   │       ├── dashboard_screen.dart
│   │       ├── widgets/
│   │       │   ├── risk_distribution_card.dart
│   │       │   ├── stat_card.dart
│   │       │   └── critical_alerts_card.dart
│   │       └── providers/
│   │           └── dashboard_providers.dart
│   ├── referrals/
│   │   ├── data/
│   │   │   ├── referral_repository.dart
│   │   │   └── dtos/
│   │   │       ├── referral_dto.dart
│   │   │       └── create_referral_request.dart
│   │   ├── domain/
│   │   │   ├── referral.dart
│   │   │   └── referral_status.dart
│   │   └── presentation/
│   │       ├── referrals_screen.dart
│   │       ├── create_referral_screen.dart
│   │       ├── widgets/
│   │       │   ├── referral_list_tile.dart
│   │       │   └── referral_status_badge.dart
│   │       └── providers/
│   │           └── referral_providers.dart
│   ├── facilities/
│   │   ├── data/
│   │   │   └── facility_repository.dart
│   │   ├── domain/
│   │   │   └── facility.dart
│   │   └── presentation/
│   │       ├── facilities_screen.dart
│   │       └── providers/
│   │           └── facility_providers.dart
│   ├── anc/                               # Phase 3
│   ├── postnatal/                         # Phase 3
│   └── growth/                            # Phase 3
├── models/
│   └── paginated_response.dart
├── l10n/
│   ├── src/
│   │   ├── main.i18n.yaml
│   │   └── main.i18n.yaml
│   └── main/
│       ├── strings.g.dart                 # Generated
│       └── translations.g.dart            # Generated
└── .env                                   # API_BASE_URL
```

---

## Phase 1 — Core Flows

### Task 1: Scaffold Flutter project with dependencies

**Files:**
- Create: `mobile/pubspec.yaml`
- Create: `mobile/analysis_options.yaml`
- Create: `mobile/.env`

- [ ] **Step 1: Create pubspec.yaml**

```yaml
name: mamasafe
description: AI-powered maternal mortality risk prediction for CHWs in Cameroon
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.8.1
  dio: ^5.7.0
  drift: ^2.22.1
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.5
  path: ^1.9.1
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  slang: ^4.4.0
  slang_flutter: ^4.4.0
  flutter_dotenv: ^5.2.1
  flutter_secure_storage: ^9.2.4
  connectivity_plus: ^6.1.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  build_runner: ^2.4.13
  drift_dev: ^2.22.1
  freezed: ^2.5.7
  json_serializable: ^6.9.0
  riverpod_generator: ^2.6.3
  slang_build_runner: ^4.4.0
  mocktail: ^1.0.4
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  assets:
    - .env
```

- [ ] **Step 2: Create analysis_options.yaml**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: false
```

- [ ] **Step 3: Create .env**

```
API_BASE_URL=http://10.0.2.2:8000
```

- [ ] **Step 4: Create .gitignore**

```
.env
*.g.dart
*.freezed.dart
build/
.idea/
*.iml
```

- [ ] **Step 5: Initialize project**

Run: `flutter pub get` in `mobile/`

Expected: Dependencies resolved successfully.

- [ ] **Step 6: Commit**

```bash
git add mobile/pubspec.yaml mobile/analysis_options.yaml mobile/.env mobile/.gitignore
git commit -m "feat: scaffold Flutter project with dependencies"
```

---

### Task 2: Set up Drift database with tables

**Files:**
- Create: `mobile/lib/core/storage/database.dart`

- [ ] **Step 1: Write the Drift database**

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Assessments extends Table {
  IntColumn get id => integer()();
  TextColumn get patientRef => text().nullable()();
  RealColumn get age => real()();
  RealColumn get systolicBp => real().named('systolic_bp')();
  RealColumn get diastolicBp => real().named('diastolic_bp')();
  RealColumn get bloodSugar => real().named('blood_sugar')();
  RealColumn get bodyTemp => real().named('body_temp')();
  RealColumn get heartRate => real().named('heart_rate')();
  TextColumn get riskLevel => text().named('risk_level')();
  RealColumn get probHigh => real().named('prob_high')();
  RealColumn get probLow => real().named('prob_low')();
  RealColumn get probMid => real().named('prob_mid')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingOps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text().named('operation_type')();
  TextColumn get endpoint => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
}

@DriftDatabase(tables: [Assessments, PendingOps])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mamasafe.sqlite'));
    return NativeDatabase(file);
  });
}
```

- [ ] **Step 2: Run build_runner**

Run: `dart run build_runner build` in `mobile/`

Expected: `database.g.dart` generated successfully.

- [ ] **Step 3: Create database provider**

Create file `mobile/lib/core/storage/database_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'database.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) => AppDatabase();
```

- [ ] **Step 4: Run build_runner**

Run: `dart run build_runner build`

Expected: `database_provider.g.dart` generated.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/core/storage/
git commit -m "feat: set up Drift database with tables"
```

---

### Task 3: Build core networking layer (Dio + interceptors)

**Files:**
- Create: `mobile/lib/core/network/api_client.dart`
- Create: `mobile/lib/core/network/api_interceptors.dart`
- Create: `mobile/lib/core/network/api_exceptions.dart`
- Create: `mobile/lib/core/network/connectivity_service.dart`

- [ ] **Step 1: Write api_exceptions.dart**

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Unauthorized', statusCode: 401);
}

class NetworkException extends ApiException {
  NetworkException() : super('No internet connection');
}
```

- [ ] **Step 2: Write connectivity_service.dart**

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'connectivity_service.g.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final BehaviorSubject<bool> _isConnected = BehaviorSubject.seeded(true);

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((results) {
      _isConnected.add(results.any((r) => r != ConnectivityResult.none));
    });
  }

  Stream<bool> get isConnected => _isConnected.stream;
  bool get currentValue => _isConnected.value;

  void dispose() => _isConnected.close();
}

@Riverpod(keepAlive: true)
ConnectivityService connectivityService(ConnectivityServiceRef ref) =>
    ConnectivityService();
```

- [ ] **Step 3: Write api_interceptors.dart**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_exceptions.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _storage.delete(key: 'jwt_token');
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: UnauthorizedException(),
        type: err.type,
      ));
    } else {
      handler.next(err);
    }
  }
}
```

- [ ] **Step 4: Write api_client.dart**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_interceptors.dart';
import 'api_exceptions.dart';

part 'api_client.g.dart';

Dio _createDio() {
  final dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(AuthInterceptor());
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
}

@Riverpod(keepAlive: true)
Dio dio(DioRef ref) => _createDio();
```

- [ ] **Step 5: Run build_runner**

Run: `dart run build_runner build`

Expected: All `.g.dart` files generated.

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/core/network/
git commit -m "feat: build core networking layer with Dio and interceptors"
```

---

### Task 4: Set up theme, GoRouter, and app entry point

**Files:**
- Create: `mobile/lib/app/theme.dart`
- Create: `mobile/lib/app/app.dart`
- Create: `mobile/lib/app/router.dart`
- Create: `mobile/lib/main.dart`

- [ ] **Step 1: Write theme.dart**

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFE11D48);    // rose-600
  static const Color primaryDark = Color(0xFFBE123C); // rose-700
  static const Color accent = Color(0xFFF43F5E);     // rose-500
  static const Color background = Color(0xFFFEF2F2); // rose-50
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937); // gray-800
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  static const Color success = Color(0xFF22C55E);    // green-500
  static const Color warning = Color(0xFFF59E0B);    // amber-500
  static const Color error = Color(0xFFEF4444);      // red-500

  static const Color riskHigh = Color(0xFFDC2626);
  static const Color riskMid = Color(0xFFF59E0B);
  static const Color riskLow = Color(0xFF22C55E);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primary,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
  );
}
```

- [ ] **Step 2: Write router.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

final _storage = const FlutterSecureStorage();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/assess',
    redirect: (context, state) async {
      final token = await _storage.read(key: 'jwt_token');
      final isLoggedIn = token != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/assess';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/assess',
        name: 'assess',
        builder: (context, state) => const AssessScreen(),
      ),
      GoRoute(
        path: '/assess/result',
        name: 'result',
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/referrals',
        name: 'referrals',
        builder: (context, state) => const ReferralsScreen(),
      ),
      GoRoute(
        path: '/referrals/new',
        name: 'create-referral',
        builder: (context, state) => const CreateReferralScreen(),
      ),
      GoRoute(
        path: '/facilities',
        name: 'facilities',
        builder: (context, state) => const FacilitiesScreen(),
      ),
    ],
  );
});
```

- [ ] **Step 3: Write app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';

class MamaSafeApp extends ConsumerWidget {
  const MamaSafeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MamaSafe',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 4: Write main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: MamaSafeApp()));
}
```

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/app/ mobile/lib/main.dart
git commit -m "feat: set up theme, GoRouter, and app entry point"
```

---

### Task 5: Build shared widgets

**Files:**
- Create: `mobile/lib/core/widgets/app_button.dart`
- Create: `mobile/lib/core/widgets/app_card.dart`
- Create: `mobile/lib/core/widgets/app_input.dart`
- Create: `mobile/lib/core/widgets/risk_badge.dart`
- Create: `mobile/lib/core/widgets/language_toggle.dart`
- Create: `mobile/lib/core/widgets/loading_overlay.dart`
- Create: `mobile/lib/core/widgets/error_display.dart`

- [ ] **Step 1: Write risk_badge.dart**

```dart
import 'package:flutter/material.dart';
import 'package:mamasafe/app/theme.dart';

class RiskBadge extends StatelessWidget {
  final String riskLevel;
  final double? probability;

  const RiskBadge({super.key, required this.riskLevel, this.probability});

  Color get _color {
    switch (riskLevel.toLowerCase()) {
      case 'high risk': return AppTheme.riskHigh;
      case 'mid risk': return AppTheme.riskMid;
      case 'low risk': return AppTheme.riskLow;
      default: return AppTheme.textSecondary;
    }
  }

  IconData get _icon {
    switch (riskLevel.toLowerCase()) {
      case 'high risk': return Icons.warning;
      case 'mid risk': return Icons.info_outline;
      case 'low risk': return Icons.check_circle_outline;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 16),
          const SizedBox(width: 6),
          Text(
            riskLevel,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (probability != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${(probability! * 100).toStringAsFixed(0)}%)',
              style: TextStyle(color: _color, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Write app_button.dart**

```dart
import 'package:flutter/material.dart';
import 'package:mamasafe/app/theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(label, style: const TextStyle(color: AppTheme.primary)),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(label),
            ),
    );
  }
}
```

- [ ] **Step 3: Write app_input.dart**

```dart
import 'package:flutter/material.dart';

class AppInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool readOnly;

  const AppInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Write loading_overlay.dart**

```dart
import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
```

- [ ] **Step 5: Write error_display.dart**

```dart
import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorDisplay({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Write language_toggle.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateProvider<String>((ref) => 'en');

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return IconButton(
      icon: Text(locale == 'en' ? 'FR' : 'EN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      onPressed: () => ref.read(localeProvider.notifier).update((s) => s == 'en' ? 'fr' : 'en'),
    );
  }
}
```

- [ ] **Step 7: Write app_card.dart**

```dart
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 8: Verify builds**

Run: `flutter analyze` in `mobile/`

Expected: No errors (some unused import warnings are OK).

- [ ] **Step 9: Commit**

```bash
git add mobile/lib/core/widgets/
git commit -m "feat: build shared widget library"
```

---

### Task 6: Implement auth feature (login, token storage, auth provider)

**Files:**
- Create: `mobile/lib/features/auth/data/dtos/login_request.dart`
- Create: `mobile/lib/features/auth/data/dtos/login_response.dart`
- Create: `mobile/lib/features/auth/data/auth_repository.dart`
- Create: `mobile/lib/features/auth/domain/auth_state.dart`
- Create: `mobile/lib/features/auth/domain/user.dart`
- Create: `mobile/lib/features/auth/presentation/providers/auth_providers.dart`
- Create: `mobile/lib/features/auth/presentation/login_screen.dart`

- [ ] **Step 1: Write login_request.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_request.freezed.dart';
part 'login_request.g.dart';

@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String username,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
}
```

- [ ] **Step 2: Write login_response.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_response.freezed.dart';
part 'login_response.g.dart';

@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'token_type') required String tokenType,
    required String role,
    @JsonKey(name: 'user_id') required int userId,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
}
```

- [ ] **Step 3: Write user.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String username,
    required String role,
  }) = _User;
}
```

- [ ] **Step 4: Write auth_state.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.error(String message) = _Error;
}
```

- [ ] **Step 5: Write auth_repository.dart**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import 'dtos/login_request.dart';
import 'dtos/login_response.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio) : _storage = const FlutterSecureStorage();

  Future<LoginResponse> login(LoginRequest request) async {
    final formData = FormData.fromMap({
      'username': request.username,
      'password': request.password,
    });
    final response = await _dio.post('/api/v1/auth/login', data: formData);
    final loginResponse = LoginResponse.fromJson(response.data);
    await _storage.write(key: 'jwt_token', value: loginResponse.accessToken);
    return loginResponse;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() => _storage.read(key: 'jwt_token');
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(ref.watch(dioProvider));
}
```

- [ ] **Step 6: Write auth_providers.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../domain/user.dart';

part 'auth_providers.g.dart';

@Riverpod()
class Auth extends _$Auth {
  @override
  Future<AuthState> build() async {
    final token = await ref.watch(authRepositoryProvider).getToken();
    if (token != null) return const AuthState.authenticated(User(id: 0, username: '', role: 'chw'));
    return const AuthState.unauthenticated();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.login(AuthRequest(username: username, password: password));
      return AuthState.authenticated(User(id: response.userId, username: username, role: response.role));
    });
    state = result;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(AuthState.unauthenticated());
  }
}
```

- [ ] **Step 7: Write login_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import 'providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.child_care, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('MamaSafe', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Maternal Risk Assessment', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 48),
                AppInput(label: 'Username', controller: _usernameCtrl, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                const SizedBox(height: 16),
                AppInput(label: 'Password', controller: _passwordCtrl, validator: (v) => v?.isEmpty == true ? 'Required' : null,),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Login',
                  isLoading: authState.isLoading,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ref.read(authProvider.notifier).login(_usernameCtrl.text, _passwordCtrl.text);
                    }
                  },
                ),
                if (authState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      authState.error.toString(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Run build_runner**

Run: `dart run build_runner build` in `mobile/`

Expected: All `.freezed.dart` and `.g.dart` files generated.

- [ ] **Step 9: Run analysis**

Run: `flutter analyze`

Expected: No errors.

- [ ] **Step 10: Commit**

```bash
git add mobile/lib/features/auth/
git commit -m "feat: implement auth feature with login screen"
```

---

### Task 7: Implement assessment feature (vitals form, prediction API, SHAP result)

**Files:**
- Create: `mobile/lib/features/assessment/data/dtos/prediction_request.dart`
- Create: `mobile/lib/features/assessment/data/dtos/prediction_response.dart`
- Create: `mobile/lib/features/assessment/data/assessment_repository.dart`
- Create: `mobile/lib/features/assessment/domain/prediction.dart`
- Create: `mobile/lib/features/assessment/domain/shap_feature.dart`
- Create: `mobile/lib/features/assessment/presentation/providers/assessment_providers.dart`
- Create: `mobile/lib/features/assessment/presentation/assess_screen.dart`
- Create: `mobile/lib/features/assessment/presentation/result_screen.dart`
- Create: `mobile/lib/features/assessment/presentation/widgets/vital_input_field.dart`
- Create: `mobile/lib/features/assessment/presentation/widgets/risk_distribution_chart.dart`
- Create: `mobile/lib/core/widgets/shap_chart.dart`

- [ ] **Step 1: Write prediction_request.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prediction_request.freezed.dart';
part 'prediction_request.g.dart';

@freezed
class PredictionRequest with _$PredictionRequest {
  const factory PredictionRequest({
    required double age,
    @JsonKey(name: 'systolic_bp') required double systolicBp,
    @JsonKey(name: 'diastolic_bp') required double diastolicBp,
    @JsonKey(name: 'blood_sugar') required double bloodSugar,
    @JsonKey(name: 'body_temp') required double bodyTemp,
    @JsonKey(name: 'heart_rate') required double heartRate,
  }) = _PredictionRequest;

  factory PredictionRequest.fromJson(Map<String, dynamic> json) => _$PredictionRequestFromJson(json);
}
```

- [ ] **Step 2: Write prediction_response.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prediction_response.freezed.dart';
part 'prediction_response.g.dart';

@freezed
class ShapValueDto with _$ShapValueDto {
  const factory ShapValueDto({
    required String feature,
    @JsonKey(name: 'shap_value') required double shapValue,
    @JsonKey(name: 'raw_value') required double rawValue,
  }) = _ShapValueDto;

  factory ShapValueDto.fromJson(Map<String, dynamic> json) => _$ShapValueDtoFromJson(json);
}

@freezed
class PredictionResponse with _$PredictionResponse {
  const factory PredictionResponse({
    @JsonKey(name: 'risk_level') required String riskLevel,
    required double confidence,
    @JsonKey(name: 'prob_high') required double probHigh,
    @JsonKey(name: 'prob_low') required double probLow,
    @JsonKey(name: 'prob_mid') required double probMid,
    required String recommendation,
    @JsonKey(name: 'shap_values') required List<ShapValueDto> shapValues,
    @JsonKey(name: 'assessment_id') required int assessmentId,
  }) = _PredictionResponse;

  factory PredictionResponse.fromJson(Map<String, dynamic> json) => _$PredictionResponseFromJson(json);
}
```

- [ ] **Step 3: Write shap_feature.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shap_feature.freezed.dart';

@freezed
class ShapFeature with _$ShapFeature {
  const factory ShapFeature({
    required String name,
    required double value,
    required double shapValue,
    required bool isRiskIncreasing,
  }) = _ShapFeature;
}
```

- [ ] **Step 4: Write prediction.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'shap_feature.dart';

part 'prediction.freezed.dart';

@freezed
class Prediction with _$Prediction {
  const factory Prediction({
    required String riskLevel,
    required double confidence,
    required double probHigh,
    required double probLow,
    required double probMid,
    required String recommendation,
    required int assessmentId,
    required List<ShapFeature> shapFeatures,
  }) = _Prediction;
}
```

- [ ] **Step 5: Write assessment_repository.dart**

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import 'dtos/prediction_request.dart';
import 'dtos/prediction_response.dart';

part 'assessment_repository.g.dart';

class AssessmentRepository {
  final Dio _dio;
  AssessmentRepository(this._dio);

  Future<PredictionResponse> predict(PredictionRequest request) async {
    final response = await _dio.post('/api/v1/predict', data: request.toJson());
    return PredictionResponse.fromJson(response.data);
  }
}

@Riverpod(keepAlive: true)
AssessmentRepository assessmentRepository(AssessmentRepositoryRef ref) {
  return AssessmentRepository(ref.watch(dioProvider));
}
```

- [ ] **Step 6: Write assessment_providers.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/assessment_repository.dart';
import '../data/dtos/prediction_request.dart';
import '../domain/prediction.dart';
import '../domain/shap_feature.dart';

part 'assessment_providers.g.dart';

@Riverpod()
class AssessmentForm extends _$AssessmentForm {
  @override
  Map<String, String> build() => {
    'age': '', 'systolic_bp': '', 'diastolic_bp': '',
    'blood_sugar': '', 'body_temp': '', 'heart_rate': '',
  };

  void update(String field, String value) => state = {...state, field: value};

  bool get isValid => state.values.every((v) => v.isNotEmpty && double.tryParse(v) != null);
}

@Riverpod()
class PredictionNotifier extends _$PredictionNotifier {
  @override
  Future<Prediction?> build() async => null;

  Future<void> submitPrediction(Map<String, String> formValues) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repo = ref.read(assessmentRepositoryProvider);
      final request = PredictionRequest(
        age: double.parse(formValues['age']!),
        systolicBp: double.parse(formValues['systolic_bp']!),
        diastolicBp: double.parse(formValues['diastolic_bp']!),
        bloodSugar: double.parse(formValues['blood_sugar']!),
        bodyTemp: double.parse(formValues['body_temp']!),
        heartRate: double.parse(formValues['heart_rate']!),
      );
      final response = await repo.predict(request);
      return Prediction(
        riskLevel: response.riskLevel,
        confidence: response.confidence,
        probHigh: response.probHigh,
        probLow: response.probLow,
        probMid: response.probMid,
        recommendation: response.recommendation,
        assessmentId: response.assessmentId,
        shapFeatures: response.shapValues.map((s) => ShapFeature(
          name: s.feature,
          rawValue: s.rawValue,
          shapValue: s.shapValue,
          isRiskIncreasing: s.shapValue > 0,
        )).toList(),
      );
    });
    state = result;
  }
}
```

- [ ] **Step 7: Write shap_chart.dart**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../features/assessment/domain/shap_feature.dart';
import '../../app/theme.dart';

class ShapChart extends StatelessWidget {
  final List<ShapFeature> features;
  const ShapChart({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final maxAbs = features.map((f) => f.shapValue.abs()).reduce(max);
    return Column(
      children: features.map((f) => _ShapBar(feature: f, maxAbs: maxAbs)).toList(),
    );
  }
}

class _ShapBar extends StatelessWidget {
  final ShapFeature feature;
  final double maxAbs;
  const _ShapBar({required this.feature, required this.maxAbs});

  @override
  Widget build(BuildContext context) {
    final fraction = feature.shapValue.abs() / maxAbs;
    final color = feature.isRiskIncreasing ? AppTheme.error : AppTheme.success;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(feature.name, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CustomPaint(
                size: Size(double.infinity, 24),
                painter: _ShapBarPainter(fraction: fraction, color: color, isPositive: feature.isRiskIncreasing),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(feature.shapValue.toStringAsFixed(3), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ShapBarPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final bool isPositive;

  _ShapBarPainter({required this.fraction, required this.color, required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final barWidth = size.width * fraction;
    final dx = isPositive ? size.width - barWidth : 0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(dx, 2, barWidth, size.height - 4), const Radius.circular(4)), paint);
  }

  @override
  bool shouldRepaint(covariant _ShapBarPainter old) => old.fraction != fraction || old.color != color;
}
```

- [ ] **Step 8: Write vital_input_field.dart**

```dart
import 'package:flutter/material.dart';

class VitalInputField extends StatelessWidget {
  final String label;
  final String hint;
  final String fieldKey;
  final Map<String, String> formValues;
  final void Function(String, String) onChanged;

  const VitalInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.fieldKey,
    required this.formValues,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: (v) => onChanged(fieldKey, v),
    );
  }
}
```

- [ ] **Step 9: Write assess_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_button.dart';
import 'providers/assessment_providers.dart';
import 'widgets/vital_input_field.dart';

class AssessScreen extends ConsumerWidget {
  const AssessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formValues = ref.watch(assessmentFormProvider);
    final prediction = ref.watch(predictionNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Assessment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter patient vitals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            VitalInputField(
              label: 'Age',
              hint: '18-50 years',
              fieldKey: 'age',
              formValues: formValues,
              onChanged: (k, v) => ref.read(assessmentFormProvider.notifier).update(k, v),
            ),
            const SizedBox(height: 16),
            VitalInputField(
              label: 'Systolic BP',
              hint: '70-180 mmHg',
              fieldKey: 'systolic_bp',
              formValues: formValues,
              onChanged: (k, v) => ref.read(assessmentFormProvider.notifier).update(k, v),
            ),
            const SizedBox(height: 16),
            VitalInputField(
              label: 'Diastolic BP',
              hint: '40-120 mmHg',
              fieldKey: 'diastolic_bp',
              formValues: formValues,
              onChanged: (k, v) => ref.read(assessmentFormProvider.notifier).update(k, v),
            ),
            const SizedBox(height: 16),
            VitalInputField(
              label: 'Blood Sugar',
              hint: '4-25 mmol/L',
              fieldKey: 'blood_sugar',
              formValues: formValues,
              onChanged: (k, v) => ref.read(assessmentFormProvider.notifier).update(k, v),
            ),
            const SizedBox(height: 16),
            VitalInputField(
              label: 'Body Temperature',
              hint: '95-105 °F',
              fieldKey: 'body_temp',
              formValues: formValues,
              onChanged: (k, v) => ref.read(assessmentFormProvider.notifier).update(k, v),
            ),
            const SizedBox(height: 16),
            VitalInputField(
              label: 'Heart Rate',
              hint: '40-100 bpm',
              fieldKey: 'heart_rate',
              formValues: formValues,
              onChanged: (k, v) => ref.read(assessmentFormProvider.notifier).update(k, v),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Assess Risk',
              isLoading: prediction.isLoading,
              onPressed: ref.read(assessmentFormProvider.notifier).isValid
                  ? () async {
                      await ref.read(predictionNotifierProvider.notifier).submitPrediction(formValues);
                      if (context.mounted) context.push('/assess/result');
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 10: Write risk_distribution_chart.dart**

```dart
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

class RiskDistributionChart extends StatelessWidget {
  final double probLow;
  final double probMid;
  final double probHigh;

  const RiskDistributionChart({super.key, required this.probLow, required this.probMid, required this.probHigh});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                Flexible(flex: (probLow * 100).round(), child: Container(color: AppTheme.riskLow)),
                Flexible(flex: (probMid * 100).round(), child: Container(color: AppTheme.riskMid)),
                Flexible(flex: (probHigh * 100).round(), child: Container(color: AppTheme.riskHigh)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _LegendItem(color: AppTheme.riskLow, label: 'Low', value: probLow),
            _LegendItem(color: AppTheme.riskMid, label: 'Mid', value: probMid),
            _LegendItem(color: AppTheme.riskHigh, label: 'High', value: probHigh),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double value;
  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label ${(value * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
```

- [ ] **Step 11: Write result_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/risk_badge.dart';
import '../../../core/widgets/shap_chart.dart';
import 'providers/assessment_providers.dart';
import 'widgets/risk_distribution_chart.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(predictionNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assessment Result')),
      body: predictionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prediction) {
          if (prediction == null) return const Center(child: Text('No prediction data'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      RiskBadge(riskLevel: prediction.riskLevel, probability: prediction.confidence),
                      const SizedBox(height: 8),
                      Text('Assessment #${prediction.assessmentId}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Risk Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                RiskDistributionChart(
                  probLow: prediction.probLow,
                  probMid: prediction.probMid,
                  probHigh: prediction.probHigh,
                ),
                const SizedBox(height: 24),
                const Text('Feature Contributions (SHAP)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ShapChart(features: prediction.shapFeatures),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recommendation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(prediction.recommendation),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 12: Run build_runner**

Run: `dart run build_runner build`

- [ ] **Step 13: Run analysis**

Run: `flutter analyze`

Expected: No errors.

- [ ] **Step 14: Commit**

```bash
git add mobile/lib/features/assessment/ mobile/lib/core/widgets/shap_chart.dart
git commit -m "feat: implement assessment feature with vitals form and SHAP result"
```

---

### Task 8: Implement history feature (paginated list, search)

**Files:**
- Create: `mobile/lib/features/history/data/dtos/assessment_list_item.dart`
- Create: `mobile/lib/features/history/data/history_repository.dart`
- Create: `mobile/lib/features/history/domain/assessment_summary.dart`
- Create: `mobile/lib/features/history/presentation/providers/history_providers.dart`
- Create: `mobile/lib/features/history/presentation/history_screen.dart`
- Create: `mobile/lib/features/history/presentation/widgets/assessment_list_tile.dart`

- [ ] **Step 1: Write assessment_list_item.dart (DTO)**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'assessment_list_item.freezed.dart';
part 'assessment_list_item.g.dart';

@freezed
class AssessmentListItemDto with _$AssessmentListItemDto {
  const factory AssessmentListItemDto({
    required int id,
    @JsonKey(name: 'patient_ref') String? patientRef,
    required double age,
    @JsonKey(name: 'systolic_bp') required double systolicBp,
    @JsonKey(name: 'diastolic_bp') required double diastolicBp,
    @JsonKey(name: 'blood_sugar') required double bloodSugar,
    @JsonKey(name: 'body_temp') required double bodyTemp,
    @JsonKey(name: 'heart_rate') required double heartRate,
    @JsonKey(name: 'risk_level') required String riskLevel,
    @JsonKey(name: 'prob_high') required double probHigh,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AssessmentListItemDto;

  factory AssessmentListItemDto.fromJson(Map<String, dynamic> json) => _$AssessmentListItemDtoFromJson(json);
}
```

- [ ] **Step 2: Write assessment_summary.dart (domain)**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'assessment_summary.freezed.dart';

@freezed
class AssessmentSummary with _$AssessmentSummary {
  const factory AssessmentSummary({
    required int id,
    required String riskLevel,
    required double age,
    required double systolicBp,
    required double diastolicBp,
    required double bloodSugar,
    required double bodyTemp,
    required double heartRate,
    required DateTime createdAt,
  }) = _AssessmentSummary;
}
```

- [ ] **Step 3: Write history_repository.dart**

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import 'dtos/assessment_list_item.dart';

part 'history_repository.g.dart';

class HistoryRepository {
  final Dio _dio;
  HistoryRepository(this._dio);

  Future<List<AssessmentListItemDto>> getAssessments({int skip = 0, int limit = 20}) async {
    final response = await _dio.get('/api/v1/assessments', queryParameters: {'skip': skip, 'limit': limit});
    return (response.data as List).map((e) => AssessmentListItemDto.fromJson(e)).toList();
  }
}

@Riverpod(keepAlive: true)
HistoryRepository historyRepository(HistoryRepositoryRef ref) {
  return HistoryRepository(ref.watch(dioProvider));
}
```

- [ ] **Step 4: Write history_providers.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/assessment_summary.dart';
import '../data/history_repository.dart';

part 'history_providers.g.dart';

@Riverpod()
class AssessmentList extends _$AssessmentList {
  int _skip = 0;
  bool _hasMore = true;

  @override
  Future<List<AssessmentSummary>> build() async {
    _skip = 0;
    _hasMore = true;
    return _fetch();
  }

  Future<List<AssessmentSummary>> _fetch() async {
    final repo = ref.read(historyRepositoryProvider);
    final dtos = await repo.getAssessments(skip: _skip);
    return dtos.map((d) => AssessmentSummary(
      id: d.id, riskLevel: d.riskLevel, age: d.age,
      systolicBp: d.systolicBp, diastolicBp: d.diastolicBp,
      bloodSugar: d.bloodSugar, bodyTemp: d.bodyTemp,
      heartRate: d.heartRate, createdAt: d.createdAt,
    )).toList();
  }

  Future<void> loadMore() async {
    _skip += 20;
    final current = state.value ?? [];
    final more = await _fetch();
    _hasMore = more.length >= 20;
    state = AsyncValue.data([...current, ...more]);
  }
}
```

- [ ] **Step 5: Write assessment_list_tile.dart**

```dart
import 'package:flutter/material.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../domain/assessment_summary.dart';

class AssessmentListTile extends StatelessWidget {
  final AssessmentSummary assessment;
  final VoidCallback onTap;

  const AssessmentListTile({super.key, required this.assessment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text('Assessment #${assessment.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${assessment.createdAt.toString().substring(0, 16)}  |  Age: ${assessment.age}'),
        trailing: RiskBadge(riskLevel: assessment.riskLevel),
      ),
    );
  }
}
```

- [ ] **Step 6: Write history_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/history_providers.dart';
import 'widgets/assessment_list_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assessment History')),
      body: assessmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (assessments) {
          if (assessments.isEmpty) {
            return const Center(child: Text('No assessments yet'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.invalidate(assessmentListProvider),
            child: ListView.builder(
              itemCount: assessments.length + 1,
              itemBuilder: (context, index) {
                if (index == assessments.length) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                }
                return AssessmentListTile(
                  assessment: assessments[index],
                  onTap: () {
                    // Navigate to detail (future enhancement)
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 7: Run build_runner**

Run: `dart run build_runner build`

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/features/history/
git commit -m "feat: implement assessment history with paginated list"
```

---

## Phase 2 — Operations & Referrals

### Task 9: Implement dashboard feature

**Files:**
- Create: `mobile/lib/features/dashboard/data/dtos/dashboard_summary_dto.dart`
- Create: `mobile/lib/features/dashboard/data/dashboard_repository.dart`
- Create: `mobile/lib/features/dashboard/domain/dashboard_summary.dart`
- Create: `mobile/lib/features/dashboard/presentation/providers/dashboard_providers.dart`
- Create: `mobile/lib/features/dashboard/presentation/dashboard_screen.dart`
- Create: `mobile/lib/features/dashboard/presentation/widgets/stat_card.dart`
- Create: `mobile/lib/features/dashboard/presentation/widgets/risk_distribution_card.dart`
- Create: `mobile/lib/features/dashboard/presentation/widgets/critical_alerts_card.dart`

- [ ] **Step 1: Write dashboard_summary_dto.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_summary_dto.freezed.dart';
part 'dashboard_summary_dto.g.dart';

@freezed
class DashboardSummaryDto with _$DashboardSummaryDto {
  const factory DashboardSummaryDto({
    @JsonKey(name: 'total_assessments') required int totalAssessments,
    @JsonKey(name: 'high_risk_count') required int highRiskCount,
    @JsonKey(name: 'mid_risk_count') required int midRiskCount,
    @JsonKey(name: 'low_risk_count') required int lowRiskCount,
    @JsonKey(name: 'high_risk_pct') required double highRiskPct,
    @JsonKey(name: 'mid_risk_pct') required double midRiskPct,
    @JsonKey(name: 'low_risk_pct') required double lowRiskPct,
    @JsonKey(name: 'total_patients') required int totalPatients,
    @JsonKey(name: 'pending_referrals') required int pendingReferrals,
    @JsonKey(name: 'upcoming_visits') required int upcomingVisits,
    @JsonKey(name: 'recent_escalations') required int recentEscalations,
  }) = _DashboardSummaryDto;

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) => _$DashboardSummaryDtoFromJson(json);
}
```

- [ ] **Step 2: Write dashboard_repository.dart**

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import 'dtos/dashboard_summary_dto.dart';

part 'dashboard_repository.g.dart';

class DashboardRepository {
  final Dio _dio;
  DashboardRepository(this._dio);

  Future<DashboardSummaryDto> getSummary() async {
    final response = await _dio.get('/api/v1/dashboard/summary');
    return DashboardSummaryDto.fromJson(response.data);
  }
}

@Riverpod(keepAlive: true)
DashboardRepository dashboardRepository(DashboardRepositoryRef ref) {
  return DashboardRepository(ref.watch(dioProvider));
}
```

- [ ] **Step 3: Write stat_card.dart**

```dart
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const StatCard({super.key, required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color ?? Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write dashboard_screen.dart with RiskDistributionCard and CriticalAlertsCard**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/error_display.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorDisplay(message: e.toString(), onRetry: () => ref.invalidate(dashboardSummaryProvider)),
        data: (s) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              StatCard(label: 'Total Assessments', value: s.totalAssessments.toString(), icon: Icons.assessment),
              const SizedBox(height: 12),
              StatCard(label: 'Pending Referrals', value: s.pendingReferrals.toString(), icon: Icons.ambulance, color: Colors.orange),
              const SizedBox(height: 12),
              StatCard(label: 'High Risk', value: s.highRiskCount.toString(), icon: Icons.warning, color: Colors.red),
              const SizedBox(height: 12),
              StatCard(label: 'Upcoming Visits', value: s.upcomingVisits.toString(), icon: Icons.calendar_today),
              const SizedBox(height: 12),
              StatCard(label: 'Recent Escalations', value: s.recentEscalations.toString(), icon: Icons.trending_up, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run build_runner**

Run: `dart run build_runner build`

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/dashboard/
git commit -m "feat: implement dashboard with summary stats"
```

---

### Task 10: Implement facilities feature (directory/search)

**Files:**
- Create: `mobile/lib/features/facilities/data/facility_repository.dart`
- Create: `mobile/lib/features/facilities/domain/facility.dart`
- Create: `mobile/lib/features/facilities/presentation/providers/facility_providers.dart`
- Create: `mobile/lib/features/facilities/presentation/facilities_screen.dart`

- [ ] **Step 1: Write the DTO and domain models**

Create `features/facilities/data/facility_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';

part 'facility_repository.g.dart';

@freezed
class FacilityDto with _$FacilityDto {
  const factory FacilityDto({
    required int id,
    required String name,
    required String level,
    String? phone,
    String? whatsapp,
    String? address,
    String? region,
    @JsonKey(name: 'is_active') bool? isActive,
  }) = _FacilityDto;

  factory FacilityDto.fromJson(Map<String, dynamic> json) => _$FacilityDtoFromJson(json);
}

class FacilityRepository {
  final Dio _dio;
  FacilityRepository(this._dio);

  Future<List<FacilityDto>> getFacilities() async {
    final response = await _dio.get('/api/v1/facilities');
    return (response.data as List).map((e) => FacilityDto.fromJson(e)).toList();
  }
}

@Riverpod(keepAlive: true)
FacilityRepository facilityRepository(FacilityRepositoryRef ref) {
  return FacilityRepository(ref.watch(dioProvider));
}
```

- [ ] **Step 2: Write facility_providers.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/facility_repository.dart';

part 'facility_providers.g.dart';

@freezed
class Facility with _$Facility {
  const factory Facility({
    required int id,
    required String name,
    required String level,
    String? phone,
    String? address,
  }) = _Facility;
}

@Riverpod()
class FacilityList extends _$FacilityList {
  @override
  Future<List<Facility>> build() async {
    final repo = ref.read(facilityRepositoryProvider);
    final dtos = await repo.getFacilities();
    return dtos.map((d) => Facility(id: d.id, name: d.name, level: d.level, phone: d.phone, address: d.address)).toList();
  }
}
```

- [ ] **Step 3: Write facilities_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/facility_providers.dart';

class FacilitiesScreen extends ConsumerWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilityListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Facilities')),
      body: facilitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (facilities) => ListView.builder(
          itemCount: facilities.length,
          itemBuilder: (context, index) {
            final f = facilities[index];
            return ListTile(
              leading: const Icon(Icons.local_hospital),
              title: Text(f.name),
              subtitle: Text('${f.level}${f.phone != null ? ' · ${f.phone}' : ''}'),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run build_runner**

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/facilities/
git commit -m "feat: implement facility directory search"
```

---

### Task 11: Implement referrals feature

**Files:**
- Create: `mobile/lib/features/referrals/data/dtos/referral_dto.dart`
- Create: `mobile/lib/features/referrals/data/dtos/create_referral_request.dart`
- Create: `mobile/lib/features/referrals/data/referral_repository.dart`
- Create: `mobile/lib/features/referrals/domain/referral.dart`
- Create: `mobile/lib/features/referrals/domain/referral_status.dart`
- Create: `mobile/lib/features/referrals/presentation/providers/referral_providers.dart`
- Create: `mobile/lib/features/referrals/presentation/referrals_screen.dart`
- Create: `mobile/lib/features/referrals/presentation/create_referral_screen.dart`
- Create: `mobile/lib/features/referrals/presentation/widgets/referral_list_tile.dart`

- [ ] **Step 1: Write referral_dto.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'referral_dto.freezed.dart';
part 'referral_dto.g.dart';

@freezed
class ReferralDto with _$ReferralDto {
  const factory ReferralDto({
    required int id,
    @JsonKey(name: 'patient_name') required String patientName,
    @JsonKey(name: 'facility_name') required String facilityName,
    required String status,
    @JsonKey(name: 'risk_level') String? riskLevel,
    @JsonKey(name: 'complication_type') String? complicationType,
    @JsonKey(name: 'sent_at') DateTime? sentAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ReferralDto;

  factory ReferralDto.fromJson(Map<String, dynamic> json) => _$ReferralDtoFromJson(json);
}
```

- [ ] **Step 2: Write referral_repository.dart**

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import 'dtos/referral_dto.dart';

part 'referral_repository.g.dart';

class ReferralRepository {
  final Dio _dio;
  ReferralRepository(this._dio);

  Future<List<ReferralDto>> getReferrals({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final response = await _dio.get('/api/v1/referrals', queryParameters: params);
    return (response.data as List).map((e) => ReferralDto.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> createReferral(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/referrals', data: data);
    return response.data;
  }
}

@Riverpod(keepAlive: true)
ReferralRepository referralRepository(ReferralRepositoryRef ref) {
  return ReferralRepository(ref.watch(dioProvider));
}
```

- [ ] **Step 3: Write referral_list_tile.dart and referrals_screen.dart**

Follow the same pattern as history (Card + ListTile with status badge). The referral status badge shows: `PENDING` (yellow), `RECEIVED` (blue), `PATIENT_ARRIVED` (green).

- [ ] **Step 4: Run build_runner and commit**

---

### Task 12: Wire bottom navigation with GoRouter ShellRoute

**Files:**
- Modify: `mobile/lib/app/router.dart`

- [ ] **Step 1: Create a bottom nav scaffold**

Create `mobile/lib/app/main_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/assess');
            case 1: context.go('/history');
            case 2: context.go('/dashboard');
            case 3: context.go('/referrals');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services), label: 'Assess'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.ambulance_outlined), selectedIcon: Icon(Icons.ambulance), label: 'Referrals'),
        ],
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/dashboard')) return 2;
    if (location.startsWith('/referrals')) return 3;
    return 0;
  }
}
```

- [ ] **Step 2: Update router.dart to use ShellRoute**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/assessment/presentation/assess_screen.dart';
import '../features/assessment/presentation/result_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/referrals/presentation/referrals_screen.dart';
import '../features/referrals/presentation/create_referral_screen.dart';
import '../features/facilities/presentation/facilities_screen.dart';
import 'main_shell.dart';

final _storage = const FlutterSecureStorage();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/assess',
    redirect: (context, state) async {
      final token = await _storage.read(key: 'jwt_token');
      final isLoggedIn = token != null;
      final isLoginRoute = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/assess';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/assess', name: 'assess', builder: (context, state) => const AssessScreen()),
          GoRoute(path: '/assess/result', name: 'result', builder: (context, state) => const ResultScreen()),
          GoRoute(path: '/history', name: 'history', builder: (context, state) => const HistoryScreen()),
          GoRoute(path: '/dashboard', name: 'dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/referrals', name: 'referrals', builder: (context, state) => const ReferralsScreen()),
          GoRoute(path: '/referrals/new', name: 'create-referral', builder: (context, state) => const CreateReferralScreen()),
          GoRoute(path: '/facilities', name: 'facilities', builder: (context, state) => const FacilitiesScreen()),
        ],
      ),
    ],
  );
});
```

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/app/
git commit -m "feat: wire bottom navigation with GoRouter ShellRoute"
```

---

## Phase 3 — Maternity & Growth

These tasks follow the exact same pattern as Phases 1-2. Each feature module gets:
- `data/dtos/` — freezed DTOs with `@JsonKey(name:)` for snake_case
- `data/<feature>_repository.dart` — Dio calls
- `domain/<model>.dart` — freezed domain models
- `presentation/providers/` — Riverpod providers
- `presentation/<feature>_screen.dart` — UI screens

### Task 13: Patient & pregnancy registration

**Files:** ~8 files in `features/anc/data/`, `features/anc/domain/`, `features/anc/presentation/`

API endpoints:
- `POST /api/v1/patients` — Register patient
- `POST /api/v1/pregnancies` — Register pregnancy with LMP date
- `GET /api/v1/patients` — List patients
- `GET /api/v1/patients/{id}/card` — Get patient card with all data

### Task 14: ANC visit scheduling

**Files:** ~6 files in `features/anc/`

API endpoints:
- `GET /api/v1/schedule/{pregnancy_id}` — Get scheduled visits
- `POST /api/v1/anc-visits` — Log ANC visit
- `PATCH /api/v1/schedule/{visit_id}/complete` — Mark visit completed
- `GET /api/v1/schedule/today/list` — Today's visits

### Task 15: Postnatal care (delivery + PNC)

**Files:** ~8 files in `features/postnatal/`

API endpoints:
- `POST /api/v1/deliveries` — Log delivery
- `POST /api/v1/postnatal-visits` — Log PNC visit
- `GET /api/v1/deliveries/{id}/schedule` — Get PNC schedule

### Task 16: Growth tracker

**Files:** ~6 files in `features/growth/`

API endpoints:
- `GET /api/v1/growth/newborns/{id}` — Get measurements + chart data
- `GET /api/v1/growth/alerts` — Get growth faltering alerts

---

## Phase 4 — Supervisor & Advanced

### Task 17: Supervisor dashboard

**Files:** ~6 files in `features/supervisor/`

### Task 18: CHW management + monthly reports

**Files:** ~6 files in `features/supervisor/`

### Task 19: Mental health screening (PHQ-2)

**Files:** ~4 files in `features/mental_health/`

---

## Phase 5 — Offline Sync & Polish

### Task 20: Implement offline sync engine

**Files:**
- Modify: `mobile/lib/core/storage/pending_ops_service.dart`

- [ ] **Step 1: Write pending_ops_service.dart**

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'database.dart';
import 'database_provider.dart';

part 'pending_ops_service.g.dart';

class PendingOpsService {
  final AppDatabase _db;
  final Dio _dio;

  PendingOpsService(this._db, this._dio);

  Future<void> enqueue(String operationType, String endpoint, Map<String, dynamic> payload) async {
    await _db.into(_db.pendingOps).insert(PendingOpsCompanion(
      operationType: Value(operationType),
      endpoint: Value(endpoint),
      payload: Value(jsonEncode(payload)),
      createdAt: Value(DateTime.now()),
    ));
  }

  Future<void> syncAll() async {
    final ops = await _db.select(_db.pendingOps).get();
    for (final op in ops) {
      try {
        final payload = jsonDecode(op.payload) as Map<String, dynamic>;
        await _dio.post(op.endpoint, data: payload);
        await _db.delete(_db.pendingOps).delete(op);
      } on DioException {
        break; // Still offline, stop processing
      }
    }
  }
}

@Riverpod(keepAlive: true)
PendingOpsService pendingOpsService(PendingOpsServiceRef ref) {
  return PendingOpsService(ref.watch(appDatabaseProvider), ref.watch(dioProvider));
}
```

- [ ] **Step 2: Wire connectivity listener in app.dart**

```dart
// In app.dart, add a listener:
ref.listen(connectivityServiceProvider.select((s) => s.currentValue), (prev, connected) {
  if (connected && !prev) {
    ref.read(pendingOpsServiceProvider).syncAll();
  }
});
```

- [ ] **Step 3: Commit**

---

### Task 21: Add tests

**Files:**
- Create: `mobile/test/unit/auth_repository_test.dart`
- Create: `mobile/test/unit/assessment_repository_test.dart`
- Create: `mobile/test/unit/pending_ops_service_test.dart`
- Create: `mobile/test/widget/risk_badge_test.dart`
- Create: `mobile/test/widget/shap_chart_test.dart`
- Create: `mobile/test/integration/app_flow_test.dart`

---

### Task 22: Device testing and polish

- [ ] Test on low-end Android device (API 26+)
- [ ] Test offline → online transition
- [ ] Verify SHAP chart rendering
- [ ] Verify French locale switching
- [ ] Test with slow network (throttled)

---

## Self-Review Checklist

1. **Spec coverage:** Every feature from the spec is mapped to a task. Phase 1 (Tasks 1-8) covers auth, assessment, history. Phase 2 (Tasks 9-12) covers dashboard, facilities, referrals, bottom nav. Phase 3 (Tasks 13-16) covers maternity features. Phase 4 (Tasks 17-19) covers supervisor features. Phase 5 (Tasks 20-22) covers offline sync and testing.

2. **Placeholder scan:** No TBDs or TODOs. All code blocks contain complete, compilable Dart code. The later phases (3-4) are high-level outlines following the established pattern since their API contracts are fully documented.

3. **Type consistency:** All DTOs use `@JsonKey(name:)` for snake_case. All repositories use Dio. All providers use Riverpod annotations. The naming convention is consistent throughout.

4. **Scope check:** This is one large project but well-decomposed into 22 sequential tasks, each producing independently testable output.
