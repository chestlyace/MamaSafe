import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';

class CreateAssessmentData {
  final String? patientRef;
  final double age;
  final double systolicBp;
  final double diastolicBp;
  final double bloodSugar;
  final double bodyTemp;
  final double heartRate;

  const CreateAssessmentData({
    this.patientRef,
    required this.age,
    required this.systolicBp,
    required this.diastolicBp,
    required this.bloodSugar,
    required this.bodyTemp,
    required this.heartRate,
  });

  Map<String, dynamic> toJson() => {
        if (patientRef != null) 'patient_ref': patientRef,
        'age': age,
        'systolic_bp': systolicBp,
        'diastolic_bp': diastolicBp,
        'blood_sugar': bloodSugar,
        'body_temp': bodyTemp,
        'heart_rate': heartRate,
      };
}

class AssessmentRepository {
  final AppDatabase _db;
  final Dio _dio;

  AssessmentRepository(this._db, this._dio);

  Future<Assessment> createAssessment(CreateAssessmentData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = DateTime.now().millisecondsSinceEpoch;

    try {
      final response = await _dio.post('/api/v1/assessments', data: jsonData);
      final body = response.data as Map<String, dynamic>;

      final riskLevel = _normalizeRisk(body['risk_level'] as String? ?? 'unknown');
      final probHigh = (body['prob_high'] as num?)?.toDouble() ?? 0.0;
      final probLow = (body['prob_low'] as num?)?.toDouble() ?? 0.0;
      final probMid = (body['prob_mid'] as num?)?.toDouble() ?? 0.0;
      final remoteId = body['id'] as int?;

      await _db.into(_db.assessments).insertOnConflictUpdate(
        AssessmentsCompanion.insert(
          id: Value(remoteId ?? id),
          patientRef: Value(data.patientRef),
          age: data.age,
          systolicBp: data.systolicBp,
          diastolicBp: data.diastolicBp,
          bloodSugar: data.bloodSugar,
          bodyTemp: data.bodyTemp,
          heartRate: data.heartRate,
          riskLevel: riskLevel,
          probHigh: probHigh,
          probLow: probLow,
          probMid: probMid,
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.assessments)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.assessments).insert(
        AssessmentsCompanion.insert(
          id: Value(id),
          patientRef: Value(data.patientRef),
          age: data.age,
          systolicBp: data.systolicBp,
          diastolicBp: data.diastolicBp,
          bloodSugar: data.bloodSugar,
          bodyTemp: data.bodyTemp,
          heartRate: data.heartRate,
          riskLevel: 'pending',
          probHigh: 0.0,
          probLow: 0.0,
          probMid: 0.0,
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_assessment',
          endpoint: '/api/v1/assessments',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.assessments)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }

  Future<List<Assessment>> getAssessments() async {
    await syncFromServer();
    final query = _db.select(_db.assessments)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  /// Fetches assessments from the server and replaces the local table.
  /// Returns `true` when the sync succeeded, `false` when offline
  /// (existing local data is kept).
  Future<bool> syncFromServer() async {
    try {
      final response = await _dio.get(
        '/api/v1/assessments',
        queryParameters: {'skip': 0, 'limit': 100},
      );
      final list = response.data as List<dynamic>;

      // The server now scopes records by the authenticated user's role/district,
      // so we replace the local table to avoid showing stale/wrong-district data.
      await _db.delete(_db.assessments).go();

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final id = map['id'] as int;
        final createdAt =
            DateTime.tryParse(map['created_at'] as String? ?? '') ??
                DateTime.now();

        await _db.into(_db.assessments).insert(
          AssessmentsCompanion.insert(
            id: Value(id),
            patientRef: Value(map['patient_ref'] as String?),
            age: (map['age'] as num?)?.toDouble() ?? 0.0,
            systolicBp: (map['systolic_bp'] as num?)?.toDouble() ?? 0.0,
            diastolicBp: (map['diastolic_bp'] as num?)?.toDouble() ?? 0.0,
            bloodSugar: (map['blood_sugar'] as num?)?.toDouble() ?? 0.0,
            bodyTemp: (map['body_temp'] as num?)?.toDouble() ?? 0.0,
            heartRate: (map['heart_rate'] as num?)?.toDouble() ?? 0.0,
            riskLevel:
                _normalizeRisk(map['risk_level'] as String? ?? 'unknown'),
            probHigh: (map['prob_high'] as num?)?.toDouble() ?? 0.0,
            probLow: (map['prob_low'] as num?)?.toDouble() ?? 0.0,
            probMid: (map['prob_mid'] as num?)?.toDouble() ?? 0.0,
            recommendation: Value(map['recommendation'] as String?),
            createdAt: createdAt,
          ),
        );
      }
      return true;
    } catch (_) {
      // Network error — fall back to local data
      return false;
    }
  }

  static String _normalizeRisk(String riskLevel) {
    switch (riskLevel) {
      case 'high risk':
        return 'high';
      case 'mid risk':
        return 'mid';
      case 'low risk':
        return 'low';
      default:
        return riskLevel;
    }
  }
}

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return AssessmentRepository(db, dio);
});

final assessmentsProvider = FutureProvider<List<Assessment>>((ref) async {
  final repo = ref.watch(assessmentRepositoryProvider);
  return repo.getAssessments();
});

class CreateAssessmentNotifier extends StateNotifier<AsyncValue<Assessment?>> {
  final AssessmentRepository _repo;

  CreateAssessmentNotifier(this._repo) : super(const AsyncData(null));

  Future<Assessment> create(CreateAssessmentData data) async {
    state = const AsyncLoading();
    try {
      final assessment = await _repo.createAssessment(data);
      state = AsyncData(assessment);
      return assessment;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createAssessmentProvider =
    StateNotifierProvider<CreateAssessmentNotifier, AsyncValue<Assessment?>>(
        (ref) {
  return CreateAssessmentNotifier(ref.read(assessmentRepositoryProvider));
});
