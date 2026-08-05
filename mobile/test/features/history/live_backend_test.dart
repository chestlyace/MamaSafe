import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/core/storage/database.dart';
import 'package:mamasafe/features/assessment/assessment_repository.dart';
import 'package:mamasafe/features/history/history_repository.dart';
import 'package:mamasafe/features/patients/patient_repository.dart';

// Live-backend smoke test. Run explicitly with:
//   LD_LIBRARY_PATH=$HOME/.local/lib flutter test \
//     test/features/history/live_backend_test.dart \
//     --dart-define=RUN_LIVE=true
// Requires the backend from mobile/.env to be reachable.
void main() {
  const base = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.1.121:8000');
  const username = String.fromEnvironment('API_USER', defaultValue: 'admin');
  const password = String.fromEnvironment('API_PASS', defaultValue: 'ChangeMe@2025');
  const runLive = bool.fromEnvironment('RUN_LIVE');

  test('full history pipeline against live backend', () async {
    final dio = Dio(BaseOptions(baseUrl: base, connectTimeout: const Duration(seconds: 5)));

    final login = await dio.post('/api/v1/auth/login',
        data: {'username': username, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType));
    final token = login.data['access_token'] as String;
    dio.options.headers['Authorization'] = 'Bearer $token';

    final db = AppDatabase.forTesting(NativeDatabase.memory());

    try {
      final assessments = await AssessmentRepository(db, dio).getAssessments();
      expect(assessments, isNotEmpty,
          reason: 'backend returned no assessments — nothing to display');

      final patients = await PatientRepository(db, dio).getPatients();
      expect(patients, isNotEmpty);

      final history = await HistoryRepository(db).getHistory();
      expect(history, isNotEmpty);
      for (final item in history.take(5)) {
        print('HISTORY ITEM: ${item.type} | ${item.title} | ${item.riskLevel} | ${item.date}');
      }
    } finally {
      await db.close();
    }
  }, timeout: const Timeout(Duration(seconds: 30)), skip: !runLive);
}
