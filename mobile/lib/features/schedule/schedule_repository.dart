import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';

class CreateScheduledVisitData {
  final int pregnancyId;
  final int visitNumber;
  final DateTime scheduledDate;
  final String status;

  const CreateScheduledVisitData({
    required this.pregnancyId,
    required this.visitNumber,
    required this.scheduledDate,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'pregnancy_id': pregnancyId,
        'visit_number': visitNumber,
        'scheduled_date': scheduledDate.toIso8601String(),
        'status': status,
      };
}

class CreatePostnatalScheduledVisitData {
  final int deliveryId;
  final int visitNumber;
  final DateTime scheduledDate;
  final String status;

  const CreatePostnatalScheduledVisitData({
    required this.deliveryId,
    required this.visitNumber,
    required this.scheduledDate,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'delivery_id': deliveryId,
        'visit_number': visitNumber,
        'scheduled_date': scheduledDate.toIso8601String(),
        'status': status,
      };
}

class ScheduleRepository {
  final AppDatabase _db;
  final Dio _dio;

  ScheduleRepository(this._db, this._dio);

  Future<List<ScheduledVisit>> getScheduledVisits(int pregnancyId) async {
    try {
      final response = await _dio.get('/pregnancies/$pregnancyId/scheduled-visits');
      final data = response.data as List;
      for (final json in data) {
        final remote = json as Map<String, dynamic>;
        await _db.into(_db.scheduledVisits).insertOnConflictUpdate(
          ScheduledVisitsCompanion.insert(
            id: Value(remote['id'] as int),
            pregnancyId: remote['pregnancy_id'] as int,
            visitNumber: remote['visit_number'] as int,
            scheduledDate: DateTime.parse(remote['scheduled_date'] as String),
            status: remote['status'] as String? ?? 'pending',
            completedVisitId: Value(remote['completed_visit_id'] as int?),
            rescheduleReason: Value(remote['reschedule_reason'] as String?),
            createdAt: DateTime.parse(remote['created_at'] as String),
          ),
        );
      }
    } on DioException {
      // fallback to local
    }

    final query = _db.select(_db.scheduledVisits)
      ..where((t) => t.pregnancyId.equals(pregnancyId))
      ..orderBy([(t) => OrderingTerm(expression: t.visitNumber, mode: OrderingMode.asc)]);
    return query.get();
  }

  Future<List<ScheduledVisit>> getUpcomingVisits() async {
    final now = DateTime.now();
    final query = _db.select(_db.scheduledVisits)
      ..where((t) => t.status.equals('pending'))
      ..orderBy([(t) => OrderingTerm(expression: t.scheduledDate, mode: OrderingMode.asc)]);
    final all = await query.get();
    return all.where((v) => v.scheduledDate.isAfter(now)).toList();
  }

  Future<ScheduledVisit> createScheduledVisit(CreateScheduledVisitData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;

    try {
      final response = await _dio.post('/scheduled-visits', data: jsonData);
      final body = response.data as Map<String, dynamic>;
      final remoteId = body['id'] as int?;

      await _db.into(_db.scheduledVisits).insertOnConflictUpdate(
        ScheduledVisitsCompanion.insert(
          id: Value(remoteId ?? id),
          pregnancyId: data.pregnancyId,
          visitNumber: data.visitNumber,
          scheduledDate: data.scheduledDate,
          status: data.status,
          completedVisitId: const Value(null),
          rescheduleReason: const Value(null),
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.scheduledVisits)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.scheduledVisits).insert(
        ScheduledVisitsCompanion.insert(
          id: Value(id),
          pregnancyId: data.pregnancyId,
          visitNumber: data.visitNumber,
          scheduledDate: data.scheduledDate,
          status: data.status,
          completedVisitId: const Value(null),
          rescheduleReason: const Value(null),
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_scheduled_visit',
          endpoint: '/scheduled-visits',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.scheduledVisits)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }

  Future<void> rescheduleVisit(int id, DateTime newDate, String reason) async {
    try {
      await _dio.patch('/scheduled-visits/$id', data: {
        'scheduled_date': newDate.toIso8601String(),
        'reschedule_reason': reason,
      });
    } on DioException {
      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'reschedule_visit',
          endpoint: '/scheduled-visits/$id',
          payload: jsonEncode({'scheduled_date': newDate.toIso8601String(), 'reschedule_reason': reason}),
          createdAt: DateTime.now(),
        ),
      );
    }

    await (_db.update(_db.scheduledVisits)..where((t) => t.id.equals(id))).write(
      ScheduledVisitsCompanion(
        scheduledDate: Value(newDate),
        rescheduleReason: Value(reason),
      ),
    );
  }

  Future<void> completeVisit(int id, int completedVisitId) async {
    try {
      await _dio.patch('/scheduled-visits/$id', data: {
        'status': 'completed',
        'completed_visit_id': completedVisitId,
      });
    } on DioException {
      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'complete_visit',
          endpoint: '/scheduled-visits/$id',
          payload: jsonEncode({'status': 'completed', 'completed_visit_id': completedVisitId}),
          createdAt: DateTime.now(),
        ),
      );
    }

    await (_db.update(_db.scheduledVisits)..where((t) => t.id.equals(id))).write(
      ScheduledVisitsCompanion(
        status: const Value('completed'),
        completedVisitId: Value(completedVisitId),
      ),
    );
  }
}

class PostnatalScheduleRepository {
  final AppDatabase _db;
  final Dio _dio;

  PostnatalScheduleRepository(this._db, this._dio);

  Future<List<PostnatalScheduledVisit>> getPostnatalScheduledVisits(int deliveryId) async {
    try {
      final response = await _dio.get('/deliveries/$deliveryId/postnatal-scheduled-visits');
      final data = response.data as List;
      for (final json in data) {
        final remote = json as Map<String, dynamic>;
        await _db.into(_db.postnatalScheduledVisits).insertOnConflictUpdate(
          PostnatalScheduledVisitsCompanion.insert(
            id: Value(remote['id'] as int),
            deliveryId: remote['delivery_id'] as int,
            visitNumber: remote['visit_number'] as int,
            scheduledDate: DateTime.parse(remote['scheduled_date'] as String),
            status: remote['status'] as String? ?? 'pending',
            completedVisitId: Value(remote['completed_visit_id'] as int?),
            rescheduleReason: Value(remote['reschedule_reason'] as String?),
            createdAt: DateTime.parse(remote['created_at'] as String),
          ),
        );
      }
    } on DioException {
      // fallback to local
    }

    final query = _db.select(_db.postnatalScheduledVisits)
      ..where((t) => t.deliveryId.equals(deliveryId))
      ..orderBy([(t) => OrderingTerm(expression: t.visitNumber, mode: OrderingMode.asc)]);
    return query.get();
  }

  Future<PostnatalScheduledVisit> createPostnatalScheduledVisit(CreatePostnatalScheduledVisitData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;

    try {
      final response = await _dio.post('/postnatal-scheduled-visits', data: jsonData);
      final body = response.data as Map<String, dynamic>;
      final remoteId = body['id'] as int?;

      await _db.into(_db.postnatalScheduledVisits).insertOnConflictUpdate(
        PostnatalScheduledVisitsCompanion.insert(
          id: Value(remoteId ?? id),
          deliveryId: data.deliveryId,
          visitNumber: data.visitNumber,
          scheduledDate: data.scheduledDate,
          status: data.status,
          completedVisitId: const Value(null),
          rescheduleReason: const Value(null),
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.postnatalScheduledVisits)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.postnatalScheduledVisits).insert(
        PostnatalScheduledVisitsCompanion.insert(
          id: Value(id),
          deliveryId: data.deliveryId,
          visitNumber: data.visitNumber,
          scheduledDate: data.scheduledDate,
          status: data.status,
          completedVisitId: const Value(null),
          rescheduleReason: const Value(null),
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_postnatal_scheduled_visit',
          endpoint: '/postnatal-scheduled-visits',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.postnatalScheduledVisits)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }

  Future<void> reschedulePostnatalVisit(int id, DateTime newDate, String reason) async {
    try {
      await _dio.patch('/postnatal-scheduled-visits/$id', data: {
        'scheduled_date': newDate.toIso8601String(),
        'reschedule_reason': reason,
      });
    } on DioException {
      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'reschedule_postnatal_visit',
          endpoint: '/postnatal-scheduled-visits/$id',
          payload: jsonEncode({'scheduled_date': newDate.toIso8601String(), 'reschedule_reason': reason}),
          createdAt: DateTime.now(),
        ),
      );
    }

    await (_db.update(_db.postnatalScheduledVisits)..where((t) => t.id.equals(id))).write(
      PostnatalScheduledVisitsCompanion(
        scheduledDate: Value(newDate),
        rescheduleReason: Value(reason),
      ),
    );
  }

  Future<void> completePostnatalVisit(int id, int completedVisitId) async {
    try {
      await _dio.patch('/postnatal-scheduled-visits/$id', data: {
        'status': 'completed',
        'completed_visit_id': completedVisitId,
      });
    } on DioException {
      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'complete_postnatal_visit',
          endpoint: '/postnatal-scheduled-visits/$id',
          payload: jsonEncode({'status': 'completed', 'completed_visit_id': completedVisitId}),
          createdAt: DateTime.now(),
        ),
      );
    }

    await (_db.update(_db.postnatalScheduledVisits)..where((t) => t.id.equals(id))).write(
      PostnatalScheduledVisitsCompanion(
        status: const Value('completed'),
        completedVisitId: Value(completedVisitId),
      ),
    );
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return ScheduleRepository(db, dio);
});

final postnatalScheduleProvider = Provider<PostnatalScheduleRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return PostnatalScheduleRepository(db, dio);
});

final scheduledVisitsProvider = FutureProvider.family<List<ScheduledVisit>, int>((ref, pregnancyId) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  return repo.getScheduledVisits(pregnancyId);
});

final upcomingVisitsProvider = FutureProvider<List<ScheduledVisit>>((ref) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  return repo.getUpcomingVisits();
});

class CreateScheduleNotifier extends StateNotifier<AsyncValue<ScheduledVisit?>> {
  final ScheduleRepository _repo;

  CreateScheduleNotifier(this._repo) : super(const AsyncData(null));

  Future<ScheduledVisit> create(CreateScheduledVisitData data) async {
    state = const AsyncLoading();
    try {
      final visit = await _repo.createScheduledVisit(data);
      state = AsyncData(visit);
      return visit;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createScheduleProvider =
    StateNotifierProvider<CreateScheduleNotifier, AsyncValue<ScheduledVisit?>>((ref) {
  return CreateScheduleNotifier(ref.read(scheduleRepositoryProvider));
});

class CreatePostnatalScheduleNotifier extends StateNotifier<AsyncValue<PostnatalScheduledVisit?>> {
  final PostnatalScheduleRepository _repo;

  CreatePostnatalScheduleNotifier(this._repo) : super(const AsyncData(null));

  Future<PostnatalScheduledVisit> create(CreatePostnatalScheduledVisitData data) async {
    state = const AsyncLoading();
    try {
      final visit = await _repo.createPostnatalScheduledVisit(data);
      state = AsyncData(visit);
      return visit;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createPostnatalScheduleProvider =
    StateNotifierProvider<CreatePostnatalScheduleNotifier, AsyncValue<PostnatalScheduledVisit?>>((ref) {
  return CreatePostnatalScheduleNotifier(ref.read(postnatalScheduleProvider));
});
