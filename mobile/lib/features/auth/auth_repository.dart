import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';
import 'user.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio) : _storage = const FlutterSecureStorage();

  Future<User> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['access_token'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    return User.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password', data: {
      'email': email,
    });
  }
}

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;

  const AuthState({
    this.status = AuthStatus.uninitialized,
    this.user,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> checkAuthStatus() async {
    final loggedIn = await _repository.isLoggedIn();
    if (loggedIn) {
      state = const AuthState(status: AuthStatus.authenticated);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<User> login(String email, String password) async {
    final user = await _repository.login(email, password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
    return user;
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class LoginAction {
  final AuthNotifier _notifier;

  LoginAction(this._notifier);

  Future<User> call(String email, String password) {
    return _notifier.login(email, password);
  }
}

final loginProvider = Provider<LoginAction>((ref) {
  return LoginAction(ref.read(authStateProvider.notifier));
});

class LogoutAction {
  final AuthNotifier _notifier;

  LogoutAction(this._notifier);

  Future<void> call() {
    return _notifier.logout();
  }
}

final logoutProvider = Provider<LogoutAction>((ref) {
  return LogoutAction(ref.read(authStateProvider.notifier));
});
