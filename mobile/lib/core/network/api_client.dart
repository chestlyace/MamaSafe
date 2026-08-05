import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_interceptors.dart';

const String apiPrefix = '/api/v1';

Dio _createDio() {
  final dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(AuthInterceptor());
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
}

final dioProvider = Provider<Dio>((ref) => _createDio());
