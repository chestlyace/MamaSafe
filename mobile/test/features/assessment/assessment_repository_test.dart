import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/core/storage/database.dart';
import 'package:mamasafe/features/assessment/assessment_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AppDatabase db;
  late MockDio dio;
  late AssessmentRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dio = MockDio();
    repo = AssessmentRepository(db, dio);
  });

  tearDown(() async {
    await db.close();
  });

  Map<String, dynamic> remoteAssessment({int id = 1, String risk = 'high risk'}) =>
      {
        'id': id,
        'patient_ref': 'P00$id',
        'age': 25,
        'systolic_bp': 120,
        'diastolic_bp': 80,
        'blood_sugar': 90,
        'body_temp': 36.5,
        'heart_rate': 75,
        'risk_level': risk,
        'prob_high': 0.9,
        'prob_low': 0.05,
        'prob_mid': 0.05,
        'recommendation': 'IMMEDIATE REFERRAL REQUIRED',
        'created_at': '2026-08-01T10:00:00Z',
      };

  Response<List<dynamic>> okResponse(List<dynamic> data) {
    return Response<List<dynamic>>(
      requestOptions: RequestOptions(path: '/api/v1/assessments'),
      data: data,
      statusCode: 200,
    );
  }

  group('AssessmentRepository.getAssessments', () {
    test('syncs remote assessments into the local DB with normalized risk',
        () async {
      when(() => dio.get('/api/v1/assessments',
              queryParameters: {'skip': 0, 'limit': 100}))
          .thenAnswer((_) async => okResponse([
                remoteAssessment(id: 1, risk: 'high risk'),
                remoteAssessment(id: 2, risk: 'low risk'),
              ]));

      final results = await repo.getAssessments();

      expect(results, hasLength(2));
      expect(results.map((a) => a.id), containsAll([1, 2]));
      expect(results.any((a) => a.riskLevel == 'high'), isTrue);
      expect(results.first.recommendation, isA<String>());

      final stored = await (db.select(db.assessments)
            ..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
      expect(stored.map((a) => a.riskLevel), ['high', 'low']);
    });

    test('normalizes mid risk and keeps unknown values', () async {
      when(() => dio.get('/api/v1/assessments',
              queryParameters: {'skip': 0, 'limit': 100}))
          .thenAnswer((_) async => okResponse([
                remoteAssessment(id: 1, risk: 'mid risk'),
                remoteAssessment(id: 2, risk: 'weird'),
              ]));

      await repo.getAssessments();

      final stored = await (db.select(db.assessments)
            ..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
      expect(stored.map((a) => a.riskLevel), ['mid', 'weird']);
    });

    test('falls back to local data when the network fails', () async {
      await db.into(db.assessments).insert(AssessmentsCompanion.insert(
            id: const Value(1),
            patientRef: const Value('LOCAL'),
            age: 30,
            systolicBp: 110,
            diastolicBp: 70,
            bloodSugar: 95,
            bodyTemp: 36.4,
            heartRate: 72,
            riskLevel: 'pending',
            probHigh: 0.0,
            probLow: 0.0,
            probMid: 0.0,
            createdAt: DateTime(2026, 7, 1),
          ));

      when(() => dio.get('/api/v1/assessments',
              queryParameters: {'skip': 0, 'limit': 100}))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/v1/assessments'),
      ));

      final results = await repo.getAssessments();

      expect(results, hasLength(1));
      expect(results.single.patientRef, 'LOCAL');
      expect(results.single.riskLevel, 'pending');
    });
  });

  group('AssessmentRepository.createAssessment', () {
    test('posts to the versioned endpoint and stores normalized risk', () async {
      when(() => dio.post('/api/v1/assessments', data: any(named: 'data')))
          .thenAnswer((_) async => Response<Map<String, dynamic>>(
                requestOptions:
                    RequestOptions(path: '/api/v1/assessments'),
                data: {
                  'id': 7,
                  ...remoteAssessment(id: 7, risk: 'high risk'),
                },
                statusCode: 200,
              ));

      final created = await repo.createAssessment(const CreateAssessmentData(
        age: 25,
        systolicBp: 120,
        diastolicBp: 80,
        bloodSugar: 90,
        bodyTemp: 36.5,
        heartRate: 75,
      ));

      expect(created.id, 7);
      expect(created.riskLevel, 'high');
      verify(() => dio.post('/api/v1/assessments', data: any(named: 'data')))
          .called(1);
    });
  });
}
