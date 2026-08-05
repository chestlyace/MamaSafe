import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/features/auth/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  group('AuthRepository signup requests', () {
    late MockDio dio;
    late AuthRepository repo;

    setUp(() {
      dio = MockDio();
      repo = AuthRepository(dio);
    });

    test('supervisor signup sends JSON payload', () async {
      when(() => dio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/api/v1/auth/supervisor-signup'),
                statusCode: 200,
                data: const {},
              ));

      await repo.supervisorSignup(
        fullName: 'Sup Test',
        username: 'suptest',
        password: 'suptest',
        district: 'yaounde 5',
        region: 'West',
        whatsappNumber: '676940247',
      );

      final captured = verify(() => dio.post(
            '/api/v1/auth/supervisor-signup',
            data: any(named: 'data'),
            options: captureAny(named: 'options'),
          )).captured;
      expect(captured.single, isNull);
    });

    test('chw signup sends JSON payload', () async {
      when(() => dio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/api/v1/auth/chw-signup'),
                statusCode: 200,
                data: const {},
              ));

      await repo.chwSignup(
        fullName: 'CHW Test',
        username: 'chwtest',
        password: 'chwtest',
        facility: 'Clinic A',
        whatsappNumber: '676940247',
        inviteCode: 'abcd-1234',
      );

      final captured = verify(() => dio.post(
            '/api/v1/auth/chw-signup',
            data: any(named: 'data'),
            options: captureAny(named: 'options'),
          )).captured;
      expect(captured.single, isNull);
    });
  });
}
