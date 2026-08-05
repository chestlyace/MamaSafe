import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';

class CreateDeliveryData {
  final int patientId;
  final int pregnancyId;
  final DateTime date;
  final String location;
  final String deliveredBy;
  final String? complications;

  const CreateDeliveryData({
    required this.patientId,
    required this.pregnancyId,
    required this.date,
    required this.location,
    required this.deliveredBy,
    this.complications,
  });

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'pregnancy_id': pregnancyId,
        'date': date.toIso8601String(),
        'location': location,
        'delivered_by': deliveredBy,
        if (complications != null) 'complications': complications,
      };
}

class CreateNewbornData {
  final int deliveryId;
  final String name;
  final String? sex;
  final double? birthWeight;
  final int? apgarScore;
  final bool? crying;
  final bool? breastfeeding;
  final String status;

  const CreateNewbornData({
    required this.deliveryId,
    required this.name,
    this.sex,
    this.birthWeight,
    this.apgarScore,
    this.crying,
    this.breastfeeding,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'delivery_id': deliveryId,
        'name': name,
        if (sex != null) 'sex': sex,
        if (birthWeight != null) 'birth_weight': birthWeight,
        if (apgarScore != null) 'apgar_score': apgarScore,
        if (crying != null) 'crying': crying,
        if (breastfeeding != null) 'breastfeeding': breastfeeding,
        'status': status,
      };
}

class CreatePostnatalVisitData {
  final int deliveryId;
  final int? newbornId;
  final DateTime visitDate;
  final int visitNumber;
  final String? motherStatus;
  final double? newbornWeight;
  final String? breastfeedingStatus;
  final double? muac;
  final String? physicalExam;
  final String? labs;
  final String? mentalHealthNotes;

  const CreatePostnatalVisitData({
    required this.deliveryId,
    this.newbornId,
    required this.visitDate,
    required this.visitNumber,
    this.motherStatus,
    this.newbornWeight,
    this.breastfeedingStatus,
    this.muac,
    this.physicalExam,
    this.labs,
    this.mentalHealthNotes,
  });

  Map<String, dynamic> toJson() => {
        'delivery_id': deliveryId,
        if (newbornId != null) 'newborn_id': newbornId,
        'visit_date': visitDate.toIso8601String(),
        'visit_number': visitNumber,
        if (motherStatus != null) 'mother_status': motherStatus,
        if (newbornWeight != null) 'newborn_weight': newbornWeight,
        if (breastfeedingStatus != null) 'breastfeeding_status': breastfeedingStatus,
        if (muac != null) 'muac': muac,
        if (physicalExam != null) 'physical_exam': physicalExam,
        if (labs != null) 'labs': labs,
        if (mentalHealthNotes != null) 'mental_health_notes': mentalHealthNotes,
      };
}

class CreateMentalHealthData {
  final int patientId;
  final int? deliveryId;
  final int phq2Score1;
  final int phq2Score2;
  final int totalScore;
  final String riskLevel;
  final String? notes;

  const CreateMentalHealthData({
    required this.patientId,
    this.deliveryId,
    required this.phq2Score1,
    required this.phq2Score2,
    required this.totalScore,
    required this.riskLevel,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        if (deliveryId != null) 'delivery_id': deliveryId,
        'phq2_score_1': phq2Score1,
        'phq2_score_2': phq2Score2,
        'total_score': totalScore,
        'risk_level': riskLevel,
        if (notes != null) 'notes': notes,
      };
}

class DeliveryRepository {
  final AppDatabase _db;
  final Dio _dio;

  DeliveryRepository(this._db, this._dio);

  Future<List<Delivery>> getDeliveries(int patientId) async {
    final query = _db.select(_db.deliveries)
      ..where((t) => t.patientId.equals(patientId))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<Delivery> getDeliveryById(int id) async {
    return (_db.select(_db.deliveries)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<Delivery> createDelivery(CreateDeliveryData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = DateTime.now().millisecondsSinceEpoch;

    try {
      final response = await _dio.post('/deliveries', data: jsonData);
      final body = response.data as Map<String, dynamic>;
      final remoteId = body['id'] as int?;

      await _db.into(_db.deliveries).insertOnConflictUpdate(
        DeliveriesCompanion.insert(
          id: Value(remoteId ?? id),
          patientId: data.patientId,
          pregnancyId: data.pregnancyId,
          date: data.date,
          location: data.location,
          deliveredBy: data.deliveredBy,
          complications: Value(data.complications),
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.deliveries)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.deliveries).insert(
        DeliveriesCompanion.insert(
          id: Value(id),
          patientId: data.patientId,
          pregnancyId: data.pregnancyId,
          date: data.date,
          location: data.location,
          deliveredBy: data.deliveredBy,
          complications: Value(data.complications),
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_delivery',
          endpoint: '/deliveries',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.deliveries)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }
}

class NewbornRepository {
  final AppDatabase _db;
  final Dio _dio;

  NewbornRepository(this._db, this._dio);

  Future<List<Newborn>> getNewborns(int deliveryId) async {
    final query = _db.select(_db.newborns)
      ..where((t) => t.deliveryId.equals(deliveryId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<Newborn> createNewborn(CreateNewbornData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = DateTime.now().millisecondsSinceEpoch;

    try {
      final response = await _dio.post('/newborns', data: jsonData);
      final body = response.data as Map<String, dynamic>;
      final remoteId = body['id'] as int?;

      await _db.into(_db.newborns).insertOnConflictUpdate(
        NewbornsCompanion.insert(
          id: Value(remoteId ?? id),
          deliveryId: data.deliveryId,
          name: data.name,
          sex: Value(data.sex),
          birthWeight: Value(data.birthWeight),
          apgarScore: Value(data.apgarScore),
          crying: Value(data.crying),
          breastfeeding: Value(data.breastfeeding),
          status: data.status,
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.newborns)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.newborns).insert(
        NewbornsCompanion.insert(
          id: Value(id),
          deliveryId: data.deliveryId,
          name: data.name,
          sex: Value(data.sex),
          birthWeight: Value(data.birthWeight),
          apgarScore: Value(data.apgarScore),
          crying: Value(data.crying),
          breastfeeding: Value(data.breastfeeding),
          status: data.status,
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_newborn',
          endpoint: '/newborns',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.newborns)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }
}

class PostnatalRepository {
  final AppDatabase _db;
  final Dio _dio;

  PostnatalRepository(this._db, this._dio);

  Future<List<PostnatalVisit>> getPostnatalVisits(int deliveryId) async {
    final query = _db.select(_db.postnatalVisits)
      ..where((t) => t.deliveryId.equals(deliveryId))
      ..orderBy([(t) => OrderingTerm(expression: t.visitDate, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<PostnatalVisit> createPostnatalVisit(CreatePostnatalVisitData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = DateTime.now().millisecondsSinceEpoch;

    try {
      final response = await _dio.post('/postnatal-visits', data: jsonData);
      final body = response.data as Map<String, dynamic>;
      final remoteId = body['id'] as int?;

      await _db.into(_db.postnatalVisits).insertOnConflictUpdate(
        PostnatalVisitsCompanion.insert(
          id: Value(remoteId ?? id),
          deliveryId: data.deliveryId,
          newbornId: Value(data.newbornId),
          visitDate: data.visitDate,
          visitNumber: data.visitNumber,
          motherStatus: Value(data.motherStatus),
          newbornWeight: Value(data.newbornWeight),
          breastfeedingStatus: Value(data.breastfeedingStatus),
          muac: Value(data.muac),
          physicalExam: Value(data.physicalExam),
          labs: Value(data.labs),
          mentalHealthNotes: Value(data.mentalHealthNotes),
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.postnatalVisits)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.postnatalVisits).insert(
        PostnatalVisitsCompanion.insert(
          id: Value(id),
          deliveryId: data.deliveryId,
          newbornId: Value(data.newbornId),
          visitDate: data.visitDate,
          visitNumber: data.visitNumber,
          motherStatus: Value(data.motherStatus),
          newbornWeight: Value(data.newbornWeight),
          breastfeedingStatus: Value(data.breastfeedingStatus),
          muac: Value(data.muac),
          physicalExam: Value(data.physicalExam),
          labs: Value(data.labs),
          mentalHealthNotes: Value(data.mentalHealthNotes),
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_postnatal_visit',
          endpoint: '/postnatal-visits',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.postnatalVisits)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }
}

class MentalHealthRepository {
  final AppDatabase _db;
  final Dio _dio;

  MentalHealthRepository(this._db, this._dio);

  Future<List<MentalHealthScreen>> getMentalHealthScreens(int patientId) async {
    final query = _db.select(_db.mentalHealthScreens)
      ..where((t) => t.patientId.equals(patientId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<MentalHealthScreen> createMentalHealthScreen(CreateMentalHealthData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = DateTime.now().millisecondsSinceEpoch;

    try {
      final response = await _dio.post('/mental-health', data: jsonData);
      final body = response.data as Map<String, dynamic>;
      final remoteId = body['id'] as int?;

      await _db.into(_db.mentalHealthScreens).insertOnConflictUpdate(
        MentalHealthScreensCompanion.insert(
          id: Value(remoteId ?? id),
          patientId: data.patientId,
          deliveryId: Value(data.deliveryId),
          phq2Score1: data.phq2Score1,
          phq2Score2: data.phq2Score2,
          totalScore: data.totalScore,
          riskLevel: data.riskLevel,
          notes: Value(data.notes),
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.mentalHealthScreens)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.mentalHealthScreens).insert(
        MentalHealthScreensCompanion.insert(
          id: Value(id),
          patientId: data.patientId,
          deliveryId: Value(data.deliveryId),
          phq2Score1: data.phq2Score1,
          phq2Score2: data.phq2Score2,
          totalScore: data.totalScore,
          riskLevel: data.riskLevel,
          notes: Value(data.notes),
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_mental_health',
          endpoint: '/mental-health',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.mentalHealthScreens)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }
}

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dioProvider),
  );
});

final newbornRepositoryProvider = Provider<NewbornRepository>((ref) {
  return NewbornRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dioProvider),
  );
});

final postnatalRepositoryProvider = Provider<PostnatalRepository>((ref) {
  return PostnatalRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dioProvider),
  );
});

final mentalHealthRepositoryProvider = Provider<MentalHealthRepository>((ref) {
  return MentalHealthRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dioProvider),
  );
});

final deliveriesProvider = FutureProvider.family<List<Delivery>, int>((ref, patientId) async {
  final repo = ref.watch(deliveryRepositoryProvider);
  return repo.getDeliveries(patientId);
});

final deliveryByIdProvider = FutureProvider.family<Delivery?, int>((ref, id) async {
  final repo = ref.watch(deliveryRepositoryProvider);
  try {
    return await repo.getDeliveryById(id);
  } catch (_) {
    return null;
  }
});

final newbornsProvider = FutureProvider.family<List<Newborn>, int>((ref, deliveryId) async {
  final repo = ref.watch(newbornRepositoryProvider);
  return repo.getNewborns(deliveryId);
});

final postnatalVisitsProvider = FutureProvider.family<List<PostnatalVisit>, int>((ref, deliveryId) async {
  final repo = ref.watch(postnatalRepositoryProvider);
  return repo.getPostnatalVisits(deliveryId);
});

final mentalHealthProvider = FutureProvider.family<List<MentalHealthScreen>, int>((ref, patientId) async {
  final repo = ref.watch(mentalHealthRepositoryProvider);
  return repo.getMentalHealthScreens(patientId);
});

class CreateDeliveryNotifier extends StateNotifier<AsyncValue<Delivery?>> {
  final DeliveryRepository _repo;

  CreateDeliveryNotifier(this._repo) : super(const AsyncData(null));

  Future<Delivery> create(CreateDeliveryData data) async {
    state = const AsyncLoading();
    try {
      final delivery = await _repo.createDelivery(data);
      state = AsyncData(delivery);
      return delivery;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createDeliveryProvider =
    StateNotifierProvider<CreateDeliveryNotifier, AsyncValue<Delivery?>>((ref) {
  return CreateDeliveryNotifier(ref.read(deliveryRepositoryProvider));
});

class CreateNewbornNotifier extends StateNotifier<AsyncValue<Newborn?>> {
  final NewbornRepository _repo;

  CreateNewbornNotifier(this._repo) : super(const AsyncData(null));

  Future<Newborn> create(CreateNewbornData data) async {
    state = const AsyncLoading();
    try {
      final newborn = await _repo.createNewborn(data);
      state = AsyncData(newborn);
      return newborn;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createNewbornProvider =
    StateNotifierProvider<CreateNewbornNotifier, AsyncValue<Newborn?>>((ref) {
  return CreateNewbornNotifier(ref.read(newbornRepositoryProvider));
});

class CreatePostnatalVisitNotifier extends StateNotifier<AsyncValue<PostnatalVisit?>> {
  final PostnatalRepository _repo;

  CreatePostnatalVisitNotifier(this._repo) : super(const AsyncData(null));

  Future<PostnatalVisit> create(CreatePostnatalVisitData data) async {
    state = const AsyncLoading();
    try {
      final visit = await _repo.createPostnatalVisit(data);
      state = AsyncData(visit);
      return visit;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createPostnatalVisitProvider =
    StateNotifierProvider<CreatePostnatalVisitNotifier, AsyncValue<PostnatalVisit?>>((ref) {
  return CreatePostnatalVisitNotifier(ref.read(postnatalRepositoryProvider));
});

class CreateMentalHealthNotifier extends StateNotifier<AsyncValue<MentalHealthScreen?>> {
  final MentalHealthRepository _repo;

  CreateMentalHealthNotifier(this._repo) : super(const AsyncData(null));

  Future<MentalHealthScreen> create(CreateMentalHealthData data) async {
    state = const AsyncLoading();
    try {
      final screen = await _repo.createMentalHealthScreen(data);
      state = AsyncData(screen);
      return screen;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createMentalHealthProvider =
    StateNotifierProvider<CreateMentalHealthNotifier, AsyncValue<MentalHealthScreen?>>((ref) {
  return CreateMentalHealthNotifier(ref.read(mentalHealthRepositoryProvider));
});
