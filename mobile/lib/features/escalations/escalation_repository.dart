import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';

class RiskEscalationRepository {
  final AppDatabase _db;
  final Dio _dio;

  RiskEscalationRepository(this._db, this._dio);

  Future<List<RiskEscalation>> getEscalations() async {
    try {
      final response = await _dio.get('/escalations');
      final data = response.data as List;
      for (final json in data) {
        final remote = json as Map<String, dynamic>;
        await _db.into(_db.riskEscalations).insertOnConflictUpdate(
          RiskEscalationsCompanion.insert(
            id: Value(remote['id'] as int),
            patientId: Value(remote['patient_id'] as int?),
            patientRef: Value(remote['patient_ref'] as String?),
            assessmentId: remote['assessment_id'] as int,
            riskLevel: remote['risk_level'] as String,
            confidenceScore: Value((remote['confidence_score'] as num?)?.toDouble()),
            message: remote['message'] as String,
            acknowledged: remote['acknowledged'] as bool? ?? false,
            createdAt: DateTime.parse(remote['created_at'] as String),
            acknowledgedAt: Value(remote['acknowledged_at'] != null ? DateTime.parse(remote['acknowledged_at'] as String) : null),
          ),
        );
      }
    } on DioException {
      // fallback to local
    }

    final query = _db.select(_db.riskEscalations)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<List<RiskEscalation>> getUnacknowledgedEscalations() async {
    final query = _db.select(_db.riskEscalations)
      ..where((t) => t.acknowledged.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<void> acknowledgeEscalation(int id) async {
    try {
      await _dio.patch('/escalations/$id/acknowledge');
    } on DioException {
      // best effort
    }

    await (_db.update(_db.riskEscalations)..where((t) => t.id.equals(id))).write(
      RiskEscalationsCompanion(
        acknowledged: const Value(true),
        acknowledgedAt: Value(DateTime.now()),
      ),
    );
  }
}

class GrowthAlertRepository {
  final AppDatabase _db;
  final Dio _dio;

  GrowthAlertRepository(this._db, this._dio);

  Future<List<GrowthAlert>> getAlerts() async {
    try {
      final response = await _dio.get('/growth-alerts');
      final data = response.data as List;
      for (final json in data) {
        final remote = json as Map<String, dynamic>;
        await _db.into(_db.growthAlerts).insertOnConflictUpdate(
          GrowthAlertsCompanion.insert(
            id: Value(remote['id'] as int),
            newbornId: remote['newborn_id'] as int,
            growthRecordId: Value(remote['growth_record_id'] as int?),
            alertType: remote['alert_type'] as String,
            severity: remote['severity'] as String,
            message: remote['message'] as String,
            messageFr: Value(remote['message_fr'] as String?),
            resolved: remote['resolved'] as bool? ?? false,
            createdAt: DateTime.parse(remote['created_at'] as String),
            resolvedAt: Value(remote['resolved_at'] != null ? DateTime.parse(remote['resolved_at'] as String) : null),
          ),
        );
      }
    } on DioException {
      // fallback to local
    }

    final query = _db.select(_db.growthAlerts)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<List<GrowthAlert>> getUnresolvedAlerts() async {
    final query = _db.select(_db.growthAlerts)
      ..where((t) => t.resolved.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<void> resolveAlert(int id) async {
    try {
      await _dio.patch('/growth-alerts/$id/resolve');
    } on DioException {
      // best effort
    }

    await (_db.update(_db.growthAlerts)..where((t) => t.id.equals(id))).write(
      GrowthAlertsCompanion(
        resolved: const Value(true),
        resolvedAt: Value(DateTime.now()),
      ),
    );
  }
}

final escalationRepositoryProvider = Provider<RiskEscalationRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return RiskEscalationRepository(db, dio);
});

final escalationsProvider = FutureProvider<List<RiskEscalation>>((ref) async {
  final repo = ref.watch(escalationRepositoryProvider);
  return repo.getEscalations();
});

final unacknowledgedEscalationsProvider = FutureProvider<List<RiskEscalation>>((ref) async {
  final repo = ref.watch(escalationRepositoryProvider);
  return repo.getUnacknowledgedEscalations();
});

final acknowledgeEscalationProvider = Provider<Future<void> Function(int)>((ref) {
  final repo = ref.watch(escalationRepositoryProvider);
  return (int id) => repo.acknowledgeEscalation(id);
});

final growthAlertRepositoryProvider = Provider<GrowthAlertRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return GrowthAlertRepository(db, dio);
});

final alertsProvider = FutureProvider<List<GrowthAlert>>((ref) async {
  final repo = ref.watch(growthAlertRepositoryProvider);
  return repo.getAlerts();
});

final unresolvedAlertsProvider = FutureProvider<List<GrowthAlert>>((ref) async {
  final repo = ref.watch(growthAlertRepositoryProvider);
  return repo.getUnresolvedAlerts();
});

final resolveAlertProvider = Provider<Future<void> Function(int)>((ref) {
  final repo = ref.watch(growthAlertRepositoryProvider);
  return (int id) => repo.resolveAlert(id);
});
