import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';

class CreateGrowthRecordData {
  final String childName;
  final String? childRef;
  final int ageMonths;
  final double weight;
  final double? height;
  final double? headCircumference;
  final double? muac;
  final String? nutritionalStatus;
  final DateTime recordedAt;

  const CreateGrowthRecordData({
    required this.childName,
    this.childRef,
    required this.ageMonths,
    required this.weight,
    this.height,
    this.headCircumference,
    this.muac,
    this.nutritionalStatus,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'child_name': childName,
        if (childRef != null) 'child_ref': childRef,
        'age_months': ageMonths,
        'weight': weight,
        if (height != null) 'height': height,
        if (headCircumference != null) 'head_circumference': headCircumference,
        if (muac != null) 'muac': muac,
        if (nutritionalStatus != null) 'nutritional_status': nutritionalStatus,
        'recorded_at': recordedAt.toIso8601String(),
      };
}

class GrowthRepository {
  final AppDatabase _db;
  final Dio _dio;

  GrowthRepository(this._db, this._dio);

  Future<List<GrowthRecord>> getGrowthRecords() async {
    final query = _db.select(_db.growthRecords)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<List<GrowthRecord>> getRecordsForChild(String childRef) async {
    final query = _db.select(_db.growthRecords)
      ..where((t) => t.childRef.equals(childRef))
      ..orderBy([(t) => OrderingTerm(expression: t.recordedAt, mode: OrderingMode.asc)]);
    return query.get();
  }

  Future<GrowthRecord> createGrowthRecord(CreateGrowthRecordData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = DateTime.now().millisecondsSinceEpoch;

    try {
      final response = await _dio.post('/growth-records', data: jsonData);
      final body = response.data as Map<String, dynamic>;
      final remoteId = body['id'] as int?;

      await _db.into(_db.growthRecords).insertOnConflictUpdate(
        GrowthRecordsCompanion.insert(
          id: Value(remoteId ?? id),
          childName: data.childName,
          childRef: Value(data.childRef),
          ageMonths: data.ageMonths,
          weight: data.weight,
          height: Value(data.height),
          headCircumference: Value(data.headCircumference),
          muac: Value(data.muac),
          nutritionalStatus: Value(data.nutritionalStatus),
          recordedAt: data.recordedAt,
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.growthRecords)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.growthRecords).insert(
        GrowthRecordsCompanion.insert(
          id: Value(id),
          childName: data.childName,
          childRef: Value(data.childRef),
          ageMonths: data.ageMonths,
          weight: data.weight,
          height: Value(data.height),
          headCircumference: Value(data.headCircumference),
          muac: Value(data.muac),
          nutritionalStatus: Value(data.nutritionalStatus),
          recordedAt: data.recordedAt,
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_growth_record',
          endpoint: '/growth-records',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.growthRecords)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }
}

final growthRepositoryProvider = Provider<GrowthRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return GrowthRepository(db, dio);
});

final growthRecordsProvider = FutureProvider<List<GrowthRecord>>((ref) async {
  final repo = ref.watch(growthRepositoryProvider);
  return repo.getGrowthRecords();
});

class CreateGrowthRecordNotifier extends StateNotifier<AsyncValue<GrowthRecord?>> {
  final GrowthRepository _repo;

  CreateGrowthRecordNotifier(this._repo) : super(const AsyncData(null));

  Future<GrowthRecord> create(CreateGrowthRecordData data) async {
    state = const AsyncLoading();
    try {
      final record = await _repo.createGrowthRecord(data);
      state = AsyncData(record);
      return record;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createGrowthRecordProvider =
    StateNotifierProvider<CreateGrowthRecordNotifier, AsyncValue<GrowthRecord?>>(
        (ref) {
  return CreateGrowthRecordNotifier(ref.read(growthRepositoryProvider));
});
