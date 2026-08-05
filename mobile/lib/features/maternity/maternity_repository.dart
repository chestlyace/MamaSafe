import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';
import '../../core/utils/date_calc.dart';

class CreatePregnancyData {
  final String patientName;
  final String? patientRef;
  final int age;
  final int? gravida;
  final int? parity;
  final String? lmp;
  final String? edd;
  final String? notes;

  CreatePregnancyData({
    required this.patientName,
    this.patientRef,
    required this.age,
    this.gravida,
    this.parity,
    this.lmp,
    this.edd,
    this.notes,
  });
}

class MaternityRepository {
  final AppDatabase _db;
  final Dio _dio;

  MaternityRepository(this._db, this._dio);

  Future<List<Pregnancy>> getPregnancies() async {
    final query = _db.select(_db.pregnancies)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<Pregnancy> createPregnancy(CreatePregnancyData data) async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;
    String? edd;
    int? gestationalAgeWeeks;

    if (data.lmp != null) {
      final lmpDate = DateTime.tryParse(data.lmp!);
      if (lmpDate != null) {
        edd = data.edd ?? formatDate(eddFromLmp(lmpDate));
        gestationalAgeWeeks = gestationalAge(lmpDate, now);
      }
    }

    try {
      await _dio.post('/pregnancies', data: {
        'patient_name': data.patientName,
        'patient_ref': data.patientRef,
        'age': data.age,
        'gravida': data.gravida,
        'parity': data.parity,
        'lmp': data.lmp,
        'edd': edd,
        'gestational_age_weeks': gestationalAgeWeeks,
        'status': 'active',
        'notes': data.notes,
      });
    } on DioException {
      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_pregnancy',
          endpoint: '/pregnancies',
          payload: jsonEncode({
            'patient_name': data.patientName,
            'patient_ref': data.patientRef,
            'age': data.age,
          }),
          createdAt: now,
        ),
      );
    }

    await _db.into(_db.pregnancies).insert(
      PregnanciesCompanion.insert(
        id: Value(id),
        patientName: data.patientName,
        patientRef: Value(data.patientRef),
        age: data.age,
        gravida: Value(data.gravida),
        parity: Value(data.parity),
        lmp: Value(data.lmp),
        edd: Value(edd),
        gestationalAgeWeeks: Value(gestationalAgeWeeks),
        status: 'active',
        riskLevel: const Value(null),
        notes: Value(data.notes),
        createdAt: now,
      ),
    );

    return (_db.select(_db.pregnancies)..where((t) => t.id.equals(id)))
        .getSingle();
  }
}

final maternityRepositoryProvider = Provider<MaternityRepository>((ref) {
  return MaternityRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dioProvider),
  );
});

final pregnanciesProvider = FutureProvider<List<Pregnancy>>((ref) async {
  final repo = ref.watch(maternityRepositoryProvider);
  return repo.getPregnancies();
});

class CreatePregnancyNotifier extends StateNotifier<AsyncValue<Pregnancy?>> {
  final MaternityRepository _repo;

  CreatePregnancyNotifier(this._repo) : super(const AsyncData(null));

  Future<Pregnancy> create(CreatePregnancyData data) async {
    state = const AsyncLoading();
    try {
      final pregnancy = await _repo.createPregnancy(data);
      state = AsyncData(pregnancy);
      return pregnancy;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createPregnancyProvider =
    StateNotifierProvider<CreatePregnancyNotifier, AsyncValue<Pregnancy?>>(
        (ref) {
  return CreatePregnancyNotifier(ref.read(maternityRepositoryProvider));
});
