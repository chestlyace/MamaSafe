import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';
import 'user.dart';

const _jwtTokenKey = 'jwt_token';
const _userRoleKey = 'user_role';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio) : _storage = const FlutterSecureStorage();

  Future<void> _storeSession(User user, String token) async {
    await _storage.write(key: _jwtTokenKey, value: token);
    await _storage.write(key: _userRoleKey, value: user.role.name);
  }

  Future<User> login(String username, String password) async {
    final response = await _dio.post(
      '/api/v1/auth/login',
      data: {'username': username, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final token = response.data['access_token'] as String;
    final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
    await _storeSession(user, token);
    return user;
  }

  Future<void> supervisorSignup({
    required String fullName,
    required String username,
    required String password,
    required String district,
    String? region,
    String? whatsappNumber,
  }) async {
    await _dio.post(
      '/api/v1/auth/supervisor-signup',
      data: {
        'full_name': fullName,
        'username': username,
        'password': password,
        'district': district,
        if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
        if (whatsappNumber != null && whatsappNumber.trim().isNotEmpty)
          'whatsapp_number': whatsappNumber.trim(),
      },
    );
  }

  Future<void> chwSignup({
    required String fullName,
    required String username,
    required String password,
    String? facility,
    String? whatsappNumber,
    required String inviteCode,
  }) async {
    await _dio.post(
      '/api/v1/auth/chw-signup',
      data: {
        'full_name': fullName,
        'username': username,
        'password': password,
        'invite_code': inviteCode.trim().toUpperCase(),
        if (facility != null && facility.trim().isNotEmpty)
          'facility': facility.trim(),
        if (whatsappNumber != null && whatsappNumber.trim().isNotEmpty)
          'whatsapp_number': whatsappNumber.trim(),
      },
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: _jwtTokenKey);
    await _storage.delete(key: _userRoleKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _jwtTokenKey);
    return token != null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _jwtTokenKey);
  }

  Future<User?> getStoredUser() async {
    final roleName = await _storage.read(key: _userRoleKey);
    if (roleName == null || roleName.isEmpty) return null;
    return userFromRoleName(roleName);
  }

  Future<void> forgotPassword(String username) async {
    await _dio.post('/auth/forgot-password', data: {
      'username': username,
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
      state = AuthState(
        status: AuthStatus.authenticated,
        user: await _repository.getStoredUser(),
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<User> login(String username, String password) async {
    final user = await _repository.login(username, password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
    return user;
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void refreshUser(User user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class LoginAction {
  final AuthNotifier _notifier;

  LoginAction(this._notifier);

  Future<User> call(String username, String password) {
    return _notifier.login(username, password);
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
