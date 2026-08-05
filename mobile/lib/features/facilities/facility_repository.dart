import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';

class CreateFacilityData {
  final String name;
  final String location;
  final String district;
  final String? contactPhone;
  final double? latitude;
  final double? longitude;

  const CreateFacilityData({
    required this.name,
    required this.location,
    required this.district,
    this.contactPhone,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'level': 'health_center',
        'district': district,
        'address': location,
        if (contactPhone != null) 'phone': contactPhone,
      };
}

class FacilityRepository {
  final AppDatabase _db;
  final Dio _dio;

  FacilityRepository(this._db, this._dio);

  Future<List<Facility>> getFacilities() async {
    try {
      final response = await _dio.get('/facilities');
      final list = response.data as List<dynamic>;
      final now = DateTime.now();

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final id = map['id'] as int;
        await _db.into(_db.facilities).insertOnConflictUpdate(
          FacilitiesCompanion.insert(
            id: Value(id),
            name: map['name'] as String,
            location: map['location'] as String,
            district: map['district'] as String,
            contactPhone: Value(map['contact_phone'] as String?),
            latitude: Value((map['latitude'] as num?)?.toDouble()),
            longitude: Value((map['longitude'] as num?)?.toDouble()),
            createdAt: now,
          ),
        );
      }
    } catch (_) {
      // Network error — return local data
    }

    final query = _db.select(_db.facilities)
      ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]);
    return query.get();
  }

  Future<Facility> createFacility(CreateFacilityData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;

    try {
      final response = await _dio.post('/facilities', data: jsonData);
      final body = response.data as Map<String, dynamic>;
      final remoteId = body['id'] as int?;

      await _db.into(_db.facilities).insertOnConflictUpdate(
        FacilitiesCompanion.insert(
          id: Value(remoteId ?? id),
          name: data.name,
          location: data.location,
          district: data.district,
          contactPhone: Value(data.contactPhone),
          latitude: Value(data.latitude),
          longitude: Value(data.longitude),
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.facilities)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.facilities).insert(
        FacilitiesCompanion.insert(
          id: Value(id),
          name: data.name,
          location: data.location,
          district: data.district,
          contactPhone: Value(data.contactPhone),
          latitude: Value(data.latitude),
          longitude: Value(data.longitude),
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_facility',
          endpoint: '/facilities',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.facilities)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }
}

final facilityRepositoryProvider = Provider<FacilityRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return FacilityRepository(db, dio);
});

final facilitiesProvider = FutureProvider<List<Facility>>((ref) async {
  final repo = ref.watch(facilityRepositoryProvider);
  return repo.getFacilities();
});
