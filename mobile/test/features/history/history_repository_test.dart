import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/core/storage/database.dart';
import 'package:mamasafe/features/history/history_repository.dart';

void main() {
  late AppDatabase db;
  late HistoryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = HistoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertAssessment({
    required int id,
    String? patientRef,
    String riskLevel = 'high',
    DateTime? createdAt,
  }) async {
    await db.into(db.assessments).insert(AssessmentsCompanion.insert(
          id: Value(id),
          patientRef: Value(patientRef),
          age: 25,
          systolicBp: 120,
          diastolicBp: 80,
          bloodSugar: 90,
          bodyTemp: 36.5,
          heartRate: 75,
          riskLevel: riskLevel,
          probHigh: 0.9,
          probLow: 0.05,
          probMid: 0.05,
          createdAt: createdAt ?? DateTime(2026, 8, 1),
        ));
  }

  Future<void> insertPatient({
    required int id,
    required String fullName,
    String? phone,
    DateTime? createdAt,
  }) async {
    await db.into(db.patients).insert(PatientsCompanion.insert(
          id: Value(id),
          fullName: fullName,
          dateOfBirth: const Value(null),
          phone: Value(phone),
          address: const Value(null),
          facility: const Value(null),
          bloodGroup: const Value(null),
          allergies: const Value(null),
          emergencyContactName: const Value(null),
          emergencyContactPhone: const Value(null),
          createdAt: createdAt ?? DateTime(2026, 8, 2),
        ));
  }

  group('HistoryRepository.getHistory', () {
    test('returns assessments, patients, and pregnancies', () async {
      await insertAssessment(id: 1, patientRef: 'P001');
      await insertPatient(id: 2, fullName: 'Amina Diallo');
      await db.into(db.pregnancies).insert(PregnanciesCompanion.insert(
            id: const Value(3),
            patientName: 'Fatou Ndiaye',
            patientRef: const Value(null),
            age: 28,
            gestationalAgeWeeks: const Value(null),
            status: 'active',
            riskLevel: const Value(null),
            createdAt: DateTime(2026, 8, 3),
          ));

      final items = await repo.getHistory();

      expect(items, hasLength(3));
      expect(items.map((i) => i.type),
          containsAll(['assessment', 'patient', 'pregnancy']));
    });

    test('sorts items by date descending', () async {
      await insertAssessment(
          id: 1, patientRef: 'old', createdAt: DateTime(2026, 7, 1));
      await insertAssessment(
          id: 2, patientRef: 'new', createdAt: DateTime(2026, 8, 1));

      final items = await repo.getHistory();

      expect(items.map((i) => i.title), ['new', 'old']);
    });

    test('filters by risk level', () async {
      await insertAssessment(id: 1, patientRef: 'A', riskLevel: 'high');
      await insertAssessment(id: 2, patientRef: 'B', riskLevel: 'low');

      final items = await repo.getHistory(riskFilter: 'high');

      expect(items, hasLength(1));
      expect(items.single.title, 'A');
    });

    test('filters by type', () async {
      await insertAssessment(id: 1, patientRef: 'A');
      await insertPatient(id: 2, fullName: 'B');

      final assessments = await repo.getHistory(typeFilter: 'assessment');
      expect(assessments.map((i) => i.type), ['assessment']);

      final patients = await repo.getHistory(typeFilter: 'patient');
      expect(patients.map((i) => i.type), ['patient']);
    });

    test('searches across title fields', () async {
      await insertPatient(id: 1, fullName: 'Amina Diallo');
      await insertPatient(id: 2, fullName: 'Fatou Ndiaye');

      final items = await repo.getHistory(search: 'amina');

      expect(items, hasLength(1));
      expect(items.single.title, 'Amina Diallo');
    });

    test('filters by date range', () async {
      await insertAssessment(
          id: 1, patientRef: 'in-range', createdAt: DateTime(2026, 8, 10));
      await insertAssessment(
          id: 2, patientRef: 'out-of-range', createdAt: DateTime(2026, 9, 10));

      final items = await repo.getHistory(
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
      );

      expect(items, hasLength(1));
      expect(items.single.title, 'in-range');
    });

    test('returns empty list when nothing matches', () async {
      await insertAssessment(id: 1, patientRef: 'A', riskLevel: 'high');

      final items = await repo.getHistory(riskFilter: 'mid');

      expect(items, isEmpty);
    });
  });
}
