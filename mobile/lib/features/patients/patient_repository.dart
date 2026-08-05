import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/database.dart';
import '../../core/storage/database_provider.dart';

class CreatePatientData {
  final String fullName;
  final String? dateOfBirth;
  final String? phone;
  final String? address;
  final String? facility;
  final String? bloodGroup;
  final String? allergies;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const CreatePatientData({
    required this.fullName,
    this.dateOfBirth,
    this.phone,
    this.address,
    this.facility,
    this.bloodGroup,
    this.allergies,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (facility != null) 'facility': facility,
        if (bloodGroup != null) 'blood_group': bloodGroup,
        if (allergies != null) 'allergies': allergies,
        if (emergencyContactName != null) 'emergency_contact_name': emergencyContactName,
        if (emergencyContactPhone != null) 'emergency_contact_phone': emergencyContactPhone,
      };
}

class PatientRepository {
  final AppDatabase _db;
  final Dio _dio;

  PatientRepository(this._db, this._dio);

  Future<List<Patient>> getPatients() async {
    await syncFromServer();
    final query = _db.select(_db.patients)
      ..orderBy([(t) => OrderingTerm(expression: t.fullName, mode: OrderingMode.asc)]);
    return query.get();
  }

  /// Fetches patients from the server and replaces the local table.
  /// Returns `true` when the sync succeeded, `false` when offline
  /// (existing local data is kept).
  Future<bool> syncFromServer() async {
    try {
      final response = await _dio.get('/api/v1/patients');
      final list = response.data as List<dynamic>;
      final now = DateTime.now();

      // The server now scopes records by the authenticated user's role/district,
      // so we replace the local table to avoid showing stale/wrong-district data.
      await _db.delete(_db.patients).go();

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final id = map['id'] as int;
        final createdAt =
            DateTime.tryParse(map['created_at'] as String? ?? '') ?? now;
        await _db.into(_db.patients).insert(
          PatientsCompanion.insert(
            id: Value(id),
            fullName: map['full_name'] as String,
            dateOfBirth: Value(map['date_of_birth'] as String?),
            phone: Value(map['phone'] as String?),
            address: Value(map['address'] as String?),
            facility: Value(map['facility'] as String?),
            bloodGroup: Value(map['blood_group'] as String?),
            allergies: Value(map['allergies'] as String?),
            emergencyContactName: Value(map['emergency_contact_name'] as String?),
            emergencyContactPhone: Value(map['emergency_contact_phone'] as String?),
            createdAt: createdAt,
          ),
        );
      }
      return true;
    } catch (_) {
      // Network error — return local data
      return false;
    }
  }

  Future<Patient> createPatient(CreatePatientData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;

    try {
      final response = await _dio.post('/api/v1/patients', data: jsonData);
      final body = response.data as Map<String, dynamic>;
      final remoteId = body['id'] as int?;

      await _db.into(_db.patients).insertOnConflictUpdate(
        PatientsCompanion.insert(
          id: Value(remoteId ?? id),
          fullName: data.fullName,
          dateOfBirth: Value(data.dateOfBirth),
          phone: Value(data.phone),
          address: Value(data.address),
          facility: Value(data.facility),
          bloodGroup: Value(data.bloodGroup),
          allergies: Value(data.allergies),
          emergencyContactName: Value(data.emergencyContactName),
          emergencyContactPhone: Value(data.emergencyContactPhone),
          createdAt: now,
        ),
      );

      final savedId = remoteId ?? id;
      return (_db.select(_db.patients)..where((t) => t.id.equals(savedId)))
          .getSingle();
    } on DioException {
      await _db.into(_db.patients).insert(
        PatientsCompanion.insert(
          id: Value(id),
          fullName: data.fullName,
          dateOfBirth: Value(data.dateOfBirth),
          phone: Value(data.phone),
          address: Value(data.address),
          facility: Value(data.facility),
          bloodGroup: Value(data.bloodGroup),
          allergies: Value(data.allergies),
          emergencyContactName: Value(data.emergencyContactName),
          emergencyContactPhone: Value(data.emergencyContactPhone),
          createdAt: now,
        ),
      );

      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'create_patient',
          endpoint: '/api/v1/patients',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );

      return (_db.select(_db.patients)..where((t) => t.id.equals(id)))
          .getSingle();
    }
  }

  Future<Patient> getPatientById(int id) async {
    return (_db.select(_db.patients)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<void> updatePatient(int id, CreatePatientData data) async {
    final jsonData = data.toJson();
    final now = DateTime.now();

    try {
      await _dio.put('/api/v1/patients/$id', data: jsonData);
    } on DioException {
      await _db.into(_db.pendingOps).insert(
        PendingOpsCompanion.insert(
          operationType: 'update_patient',
          endpoint: '/api/v1/patients/$id',
          payload: jsonEncode(jsonData),
          createdAt: now,
        ),
      );
    }

    (_db.update(_db.patients)..where((t) => t.id.equals(id)))
        .write(PatientsCompanion(
      fullName: Value(data.fullName),
      dateOfBirth: Value(data.dateOfBirth),
      phone: Value(data.phone),
      address: Value(data.address),
      facility: Value(data.facility),
      bloodGroup: Value(data.bloodGroup),
      allergies: Value(data.allergies),
      emergencyContactName: Value(data.emergencyContactName),
      emergencyContactPhone: Value(data.emergencyContactPhone),
    ));
  }
}

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return PatientRepository(db, dio);
});

final patientsProvider = FutureProvider<List<Patient>>((ref) async {
  final repo = ref.watch(patientRepositoryProvider);
  return repo.getPatients();
});

final patientByIdProvider =
    FutureProvider.family<Patient, int>((ref, id) async {
  final repo = ref.watch(patientRepositoryProvider);
  return repo.getPatientById(id);
});

class CreatePatientNotifier extends StateNotifier<AsyncValue<Patient?>> {
  final PatientRepository _repo;

  CreatePatientNotifier(this._repo) : super(const AsyncData(null));

  Future<Patient> create(CreatePatientData data) async {
    state = const AsyncLoading();
    try {
      final patient = await _repo.createPatient(data);
      state = AsyncData(patient);
      return patient;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createPatientProvider =
    StateNotifierProvider<CreatePatientNotifier, AsyncValue<Patient?>>((ref) {
  return CreatePatientNotifier(ref.read(patientRepositoryProvider));
});
