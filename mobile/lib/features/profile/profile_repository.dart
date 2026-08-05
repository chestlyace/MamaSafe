import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../auth/user.dart';

class ProfileUpdate {
  final String? fullName;
  final String? whatsappNumber;
  final String? facility;
  final String? district;
  final String? region;

  const ProfileUpdate({
    this.fullName,
    this.whatsappNumber,
    this.facility,
    this.district,
    this.region,
  });

  /// Only non-null fields are sent; an empty WhatsApp clears the value.
  Map<String, dynamic> toPayload() => {
        if (fullName != null) 'full_name': fullName,
        if (whatsappNumber != null)
          'whatsapp_number': whatsappNumber!.isEmpty ? null : whatsappNumber,
        if (facility != null) 'facility': facility,
        if (district != null) 'district': district,
        if (region != null) 'region': region,
      };

  ProfileUpdate copyWith({
    String? fullName,
    String? whatsappNumber,
    String? facility,
    String? district,
    String? region,
  }) {
    return ProfileUpdate(
      fullName: fullName ?? this.fullName,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      facility: facility ?? this.facility,
      district: district ?? this.district,
      region: region ?? this.region,
    );
  }
}

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<User> fetchMe() async {
    final response = await _dio.get('/api/v1/users/me');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> updateMe(ProfileUpdate update) async {
    final response =
        await _dio.patch('/api/v1/users/me', data: update.toPayload());
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post('/api/v1/users/me/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

final profileProvider = FutureProvider<User>((ref) async {
  return ref.watch(profileRepositoryProvider).fetchMe();
});

class UpdateProfileNotifier extends StateNotifier<AsyncValue<User?>> {
  final ProfileRepository _repo;

  UpdateProfileNotifier(this._repo) : super(const AsyncData(null));

  Future<User?> update(ProfileUpdate update) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.updateMe(update);
      state = AsyncData(user);
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updateProfileProvider =
    StateNotifierProvider<UpdateProfileNotifier, AsyncValue<User?>>((ref) {
  return UpdateProfileNotifier(ref.read(profileRepositoryProvider));
});

class ChangePasswordNotifier extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repo;

  ChangePasswordNotifier(this._repo) : super(const AsyncData(null));

  Future<void> change({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final changePasswordProvider =
    StateNotifierProvider<ChangePasswordNotifier, AsyncValue<void>>((ref) {
  return ChangePasswordNotifier(ref.read(profileRepositoryProvider));
});
