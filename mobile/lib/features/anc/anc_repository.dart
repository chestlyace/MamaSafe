import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';

class CreateAncVisitData {
  final int pregnancyId;
  final int visitNumber;
  final DateTime date;
  final int? gestationalAgeWeeks;
  final double? weight;
  final double? systolicBp;
  final double? diastolicBp;
  final double? fundalHeight;
  final double? fetalHeartRate;
  final String? presentation;
  final String? urinalysis;
  final bool? oedema;
  final bool? ttVaccine;
  final bool? malariaProphylaxis;
  final bool? ironSupplements;
  final String? notes;
  final DateTime? nextVisitDate;

  CreateAncVisitData({
    required this.pregnancyId,
    required this.visitNumber,
    required this.date,
    this.gestationalAgeWeeks,
    this.weight,
    this.systolicBp,
    this.diastolicBp,
    this.fundalHeight,
    this.fetalHeartRate,
    this.presentation,
    this.urinalysis,
    this.oedema,
    this.ttVaccine,
    this.malariaProphylaxis,
    this.ironSupplements,
    this.notes,
    this.nextVisitDate,
  });

  Map<String, dynamic> toJson() => {
        'pregnancy_id': pregnancyId,
        'visit_number': visitNumber,
        'date': date.toIso8601String(),
        'gestational_age_weeks': gestationalAgeWeeks,
        'weight': weight,
        'systolic_bp': systolicBp,
        'diastolic_bp': diastolicBp,
        'fundal_height': fundalHeight,
        'fetal_heart_rate': fetalHeartRate,
        'presentation': presentation,
        'urinalysis': urinalysis,
        'oedema': oedema,
        'tt_vaccine': ttVaccine,
        'malaria_prophylaxis': malariaProphylaxis,
        'iron_supplements': ironSupplements,
        'notes': notes,
        if (nextVisitDate != null) 'next_visit_date': nextVisitDate!.toIso8601String(),
      };
}

class AncRepository {
  final AppDatabase _db;
  final Dio _dio;

  AncRepository(this._db, this._dio);

  Future<List<AncVisit>> getAncVisits(int pregnancyId) async {
    try {
      final response = await _dio.get('$apiPrefix/pregnancies/$pregnancyId/anc-visits');
      final data = response.data as List? ?? [];
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        await _db.into(_db.ancVisits).insertOnConflictUpdate(
          AncVisitsCompanion.insert(
            id: Value(map['id'] as int),
            pregnancyId: map['pregnancy_id'] as int,
            visitNumber: map['visit_number'] as int,
            date: DateTime.parse(map['date'] as String),
            gestationalAgeWeeks: map['gestational_age_weeks'] != null
                ? Value(map['gestational_age_weeks'] as int)
                : const Value.absent(),
            weight: map['weight'] != null
                ? Value((map['weight'] as num).toDouble())
                : const Value.absent(),
            systolicBp: map['systolic_bp'] != null
                ? Value((map['systolic_bp'] as num).toDouble())
                : const Value.absent(),
            diastolicBp: map['diastolic_bp'] != null
                ? Value((map['diastolic_bp'] as num).toDouble())
                : const Value.absent(),
            fundalHeight: map['fundal_height'] != null
                ? Value((map['fundal_height'] as num).toDouble())
                : const Value.absent(),
            fetalHeartRate: map['fetal_heart_rate'] != null
                ? Value((map['fetal_heart_rate'] as num).toDouble())
                : const Value.absent(),
            presentation: map['presentation'] != null
                ? Value(map['presentation'] as String)
                : const Value.absent(),
            urinalysis: map['urinalysis'] != null
                ? Value(map['urinalysis'] as String)
                : const Value.absent(),
            oedema: map['oedema'] != null
                ? Value(map['oedema'] as bool)
                : const Value.absent(),
            ttVaccine: map['tt_vaccine'] != null
                ? Value(map['tt_vaccine'] as bool)
                : const Value.absent(),
            malariaProphylaxis: map['malaria_prophylaxis'] != null
                ? Value(map['malaria_prophylaxis'] as bool)
                : const Value.absent(),
            ironSupplements: map['iron_supplements'] != null
                ? Value(map['iron_supplements'] as bool)
                : const Value.absent(),
            notes: map['notes'] != null
                ? Value(map['notes'] as String)
                : const Value.absent(),
            nextVisitDate: map['next_visit_date'] != null
                ? Value(DateTime.parse(map['next_visit_date'] as String))
                : const Value.absent(),
            createdAt: DateTime.parse(map['created_at'] as String),
          ),
        );
      }
    } on DioException {
      // Offline — serve from local DB
    }

    final query = _db.select(_db.ancVisits)
      ..where((t) => t.pregnancyId.equals(pregnancyId))
      ..orderBy([(t) => OrderingTerm(expression: t.visitNumber, mode: OrderingMode.asc)]);
    return query.get();
  }

  Future<AncVisit> createAncVisit(CreateAncVisitData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;

    try {
      final response = await _dio.post('$apiPrefix/anc-visits', data: jsonData);
      final body = response.data as Map<String, dynamic>;
      final remoteId = body['id'] as int?;

      await _db.into(_db.ancVisits).insertOnConflictUpdate(
        AncVisitsCompanion.insert(
          id: Value(remoteId ?? id),
          pregnancyId: data.pregnancyId,
          visitNumber: data.visitNumber,
          date: data.date,
          gestationalAgeWeeks: data.gestationalAgeWeeks != null
              ? Value(data.gestationalAgeWeeks!)
              : const Value.absent(),
          weight: data.weight != null
              ? Value(data.weight!)
              : const Value.absent(),
          systolicBp: data.systolicBp != null
              ? Value(data.systolicBp!)
              : const Value.absent(),
          diastolicBp: data.diastolicBp != null
              ? Value(data.diastolicBp!)
              : const Value.absent(),
          fundalHeight: data.fundalHeight != null
              ? Value(data.fundalHeight!)
              : const Value.absent(),
          fetalHeartRate: data.fetalHeartRate != null
              ? Value(data.fetalHeartRate!)
              : const Value.absent(),
          presentation: data.presentation != null
              ? Value(data.presentation!)
              : const Value.absent(),
          urinalysis: data.urinalysis != null
              ? Value(data.urinalysis!)
              : const Value.absent(),
          oedema: data.oedema != null
              ? Value(data.oedema!)
              : const Value.absent(),
          ttVaccine: data.ttVaccine != null
              ? Value(data.ttVaccine!)
              : const Value.absent(),
          malariaProphylaxis: data.malariaProphylaxis != null
              ? Value(data.malariaProphylaxis!)
              : const Value.absent(),
          ironSupplements: data.ironSupplements != null
              ? Value(data.ironSupplements!)
              : const Value.absent(),
          notes: data.notes != null
              ? Value(data.notes!)
              : const Value.absent(),
          nextVisitDate: data.nextVisitDate != null
              ? Value(data.nextVisitDate!)
              : const Value.absent(),
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.ancVisits)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.ancVisits).insert(
        AncVisitsCompanion.insert(
          id: Value(id),
          pregnancyId: data.pregnancyId,
          visitNumber: data.visitNumber,
          date: data.date,
          gestationalAgeWeeks: data.gestationalAgeWeeks != null
              ? Value(data.gestationalAgeWeeks!)
              : const Value.absent(),
          weight: data.weight != null
              ? Value(data.weight!)
              : const Value.absent(),
          systolicBp: data.systolicBp != null
              ? Value(data.systolicBp!)
              : const Value.absent(),
          diastolicBp: data.diastolicBp != null
              ? Value(data.diastolicBp!)
              : const Value.absent(),
          fundalHeight: data.fundalHeight != null
              ? Value(data.fundalHeight!)
              : const Value.absent(),
          fetalHeartRate: data.fetalHeartRate != null
              ? Value(data.fetalHeartRate!)
              : const Value.absent(),
          presentation: data.presentation != null
              ? Value(data.presentation!)
              : const Value.absent(),
          urinalysis: data.urinalysis != null
              ? Value(data.urinalysis!)
              : const Value.absent(),
          oedema: data.oedema != null
              ? Value(data.oedema!)
              : const Value.absent(),
          ttVaccine: data.ttVaccine != null
              ? Value(data.ttVaccine!)
              : const Value.absent(),
          malariaProphylaxis: data.malariaProphylaxis != null
              ? Value(data.malariaProphylaxis!)
              : const Value.absent(),
          ironSupplements: data.ironSupplements != null
              ? Value(data.ironSupplements!)
              : const Value.absent(),
          notes: data.notes != null
              ? Value(data.notes!)
              : const Value.absent(),
          nextVisitDate: data.nextVisitDate != null
              ? Value(data.nextVisitDate!)
              : const Value.absent(),
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_anc_visit',
          endpoint: '/api/v1/anc-visits',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.ancVisits)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }

  Future<AncVisit> getAncVisitById(int id) async {
    return (_db.select(_db.ancVisits)..where((t) => t.id.equals(id)))
        .getSingle();
  }
}

final ancRepositoryProvider = Provider<AncRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return AncRepository(db, dio);
});

final ancVisitsProvider =
    FutureProvider.family<List<AncVisit>, int>((ref, pregnancyId) async {
  final repo = ref.watch(ancRepositoryProvider);
  return repo.getAncVisits(pregnancyId);
});

class CreateAncVisitNotifier extends StateNotifier<AsyncValue<AncVisit?>> {
  final AncRepository _repo;

  CreateAncVisitNotifier(this._repo) : super(const AsyncData(null));

  Future<AncVisit> create(CreateAncVisitData data) async {
    state = const AsyncLoading();
    try {
      final visit = await _repo.createAncVisit(data);
      state = AsyncData(visit);
      return visit;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createAncVisitProvider =
    StateNotifierProvider<CreateAncVisitNotifier, AsyncValue<AncVisit?>>(
        (ref) {
  return CreateAncVisitNotifier(ref.read(ancRepositoryProvider));
});
