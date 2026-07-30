import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';

class CreateReferralData {
  final int assessmentId;
  final String? patientRef;
  final String referredTo;
  final String reason;
  final String? notes;
  final DateTime referralDate;

  const CreateReferralData({
    required this.assessmentId,
    this.patientRef,
    required this.referredTo,
    required this.reason,
    this.notes,
    required this.referralDate,
  });

  Map<String, dynamic> toJson() => {
    'assessment_id': assessmentId,
    if (patientRef != null) 'patient_ref': patientRef,
    'referred_to': referredTo,
    'reason': reason,
    if (notes != null) 'notes': notes,
    'referral_date': referralDate.toIso8601String(),
  };
}

class ReferralRepository {
  final AppDatabase _db;
  final Dio _dio;

  ReferralRepository(this._db, this._dio);

  Future<List<Referral>> getReferrals() async {
    final query = _db.select(_db.referrals)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<Referral> createReferral(CreateReferralData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;

    try {
      final response = await _dio.post('/referrals', data: jsonData);
      final body = response.data as Map<String, dynamic>;
      final remoteId = body['id'] as int?;

      await _db.into(_db.referrals).insertOnConflictUpdate(
        ReferralsCompanion.insert(
          id: remoteId != null ? Value(remoteId) : const Value.absent(),
          assessmentId: data.assessmentId,
          patientRef: data.patientRef != null ? Value(data.patientRef) : const Value.absent(),
          referredTo: data.referredTo,
          reason: data.reason,
          status: 'pending',
          notes: data.notes != null ? Value(data.notes) : const Value.absent(),
          referralDate: data.referralDate,
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.referrals)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.referrals).insert(
        ReferralsCompanion.insert(
          id: Value(id),
          assessmentId: data.assessmentId,
          patientRef: data.patientRef != null ? Value(data.patientRef) : const Value.absent(),
          referredTo: data.referredTo,
          reason: data.reason,
          status: 'pending',
          notes: data.notes != null ? Value(data.notes) : const Value.absent(),
          referralDate: data.referralDate,
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_referral',
          endpoint: '/referrals',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.referrals)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }

  Future<void> updateReferralStatus(int id, String status) async {
    try {
      await _dio.patch('/referrals/$id', data: {'status': status});
    } on DioException {
      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'update_referral_status',
          endpoint: '/referrals/$id',
          payload: jsonEncode({'status': status}),
          createdAt: DateTime.now(),
        ),
      );
    }

    (_db.update(_db.referrals)..where((t) => t.id.equals(id)))
        .write(ReferralsCompanion(status: Value(status)));
  }
}

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return ReferralRepository(db, dio);
});

final referralsProvider = FutureProvider<List<Referral>>((ref) async {
  final repo = ref.watch(referralRepositoryProvider);
  return repo.getReferrals();
});

class CreateReferralNotifier extends StateNotifier<AsyncValue<Referral?>> {
  final ReferralRepository _repo;

  CreateReferralNotifier(this._repo) : super(const AsyncData(null));

  Future<Referral> create(CreateReferralData data) async {
    state = const AsyncLoading();
    try {
      final referral = await _repo.createReferral(data);
      state = AsyncData(referral);
      return referral;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createReferralProvider =
    StateNotifierProvider<CreateReferralNotifier, AsyncValue<Referral?>>((ref) {
  return CreateReferralNotifier(ref.read(referralRepositoryProvider));
});
