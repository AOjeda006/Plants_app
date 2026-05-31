/// @file logout_use_case_test.dart
/// @description Tests del LogoutUseCase profundo.
/// Verifica el orden de las llamadas, la tolerancia a fallos de cada paso
/// y que `AuthRepository.logout` (secure_storage) se ejecuta siempre al final.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/core/network/socket_client.dart';
import 'package:plants_app/core/storage/cache_local_data_source.dart';
import 'package:plants_app/domain/dtos/user/update_preferences_request_dto.dart';
import 'package:plants_app/domain/dtos/user/update_profile_request_dto.dart';
import 'package:plants_app/domain/entities/user.dart';
import 'package:plants_app/domain/repositories/i_auth_repository.dart';
import 'package:plants_app/domain/repositories/i_user_repository.dart';
import 'package:plants_app/domain/usecases/auth/logout_use_case.dart';

// ─── Mocks manuales ─────────────────────────────────────────────────────────

class _MockAuthRepo implements IAuthRepository {
  final List<String> calls = [];
  AppError?          throwOnLogout;

  @override
  Future<void> logout() async {
    calls.add('logout');
    if (throwOnLogout != null) throw throwOnLogout!;
  }

  @override
  Future<({User user, String token})> login({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<({User user, String token})> register({
    required String name,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<({User user, String token})> refreshToken() => throw UnimplementedError();

  @override
  Future<User> validateToken() => throw UnimplementedError();
}

class _MockUserRepo implements IUserRepository {
  final List<String> calls = [];
  AppError?          throwOnDelete;

  @override
  Future<void> deleteFcmToken() async {
    calls.add('deleteFcmToken');
    if (throwOnDelete != null) throw throwOnDelete!;
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount(String password, {bool preserveContent = false}) =>
      throw UnimplementedError();

  @override
  Future<String> exportData() => throw UnimplementedError();

  @override
  Future<User> getMyProfile() => throw UnimplementedError();

  @override
  Future<User> getUserById(String userId) => throw UnimplementedError();

  @override
  Future<User> updatePreferences(UpdatePreferencesRequestDto dto) =>
      throw UnimplementedError();

  @override
  Future<User> updateProfile(UpdateProfileRequestDto dto) =>
      throw UnimplementedError();
}

class _MockSocket extends SocketClient {
  final List<String> calls = [];
  _MockSocket() : super(tokenProvider: () async => 'token');

  @override
  void disconnect() {
    calls.add('disconnect');
  }
}

/// Mock de CacheLocalDataSource — extends (la clase es concreta) y solo
/// sobreescribe `clearAll`. El resto de métodos nunca se invocan en este
/// flujo, así que `initialize()` no hace falta llamarlo en setUp.
class _MockCache extends CacheLocalDataSource {
  final List<String> calls = [];

  @override
  Future<void> clearAll() async {
    calls.add('clearAll');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  group('LogoutUseCase', () {
    late _MockAuthRepo auth;
    late _MockUserRepo user;
    late _MockSocket   socket;
    late _MockCache    cache;
    late LogoutUseCase useCase;

    setUp(() {
      auth   = _MockAuthRepo();
      user   = _MockUserRepo();
      socket = _MockSocket();
      cache  = _MockCache();
      useCase = LogoutUseCase(
        authRepository: auth,
        userRepository: user,
        socketClient:   socket,
        cache:          cache,
      );
    });

    test('execute() invoca deleteFcmToken → disconnect → clearAll → authRepo.logout en orden', () async {
      await useCase.execute();

      expect(user.calls,   ['deleteFcmToken']);
      expect(socket.calls, ['disconnect']);
      expect(cache.calls,  ['clearAll']);
      expect(auth.calls,   ['logout']);
    });

    test('si deleteFcmToken falla (red), los siguientes pasos se ejecutan igual', () async {
      user.throwOnDelete = AppError.network('offline');

      await useCase.execute();

      expect(user.calls,   ['deleteFcmToken']);
      // Pese al fallo, el resto del flujo sigue:
      expect(socket.calls, ['disconnect']);
      expect(cache.calls,  ['clearAll']);
      expect(auth.calls,   ['logout']);
    });

    test('si authRepo.logout falla, propaga (último paso obligatorio para invalidar la sesión local)', () async {
      auth.throwOnLogout = AppError.unknown('storage error');

      await expectLater(useCase.execute(), throwsA(isA<AppError>()));

      // Aun así, los pasos anteriores se ejecutaron:
      expect(user.calls,   ['deleteFcmToken']);
      expect(socket.calls, ['disconnect']);
      expect(cache.calls,  ['clearAll']);
    });
  });
}
