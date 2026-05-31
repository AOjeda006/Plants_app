/// @file refresh_token_use_case_test.dart
/// @description Tests del use case de auto-refresh del token JWT.
/// @module Auth
/// @layer Domain
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plants_app/core/storage/auth_local_data_source.dart';
import 'package:plants_app/domain/entities/user.dart';
import 'package:plants_app/domain/repositories/i_auth_repository.dart';
import 'package:plants_app/domain/usecases/auth/refresh_token_use_case.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _FakeLocal extends AuthLocalDataSource {
  String? token;
  _FakeLocal(this.token);

  @override
  Future<String?> getAccessToken() async => token;
}

class _FakeRepository implements IAuthRepository {
  bool refreshCalled = false;

  @override
  Future<({User user, String token})> refreshToken() async {
    refreshCalled = true;
    return (
      user: User(
        id:        'u1',
        name:      'Test',
        email:     'test@example.com',
        role:      'user',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      token: 'new_token',
    );
  }

  @override
  Future<({User user, String token})> register({
    required String name,
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<User> validateToken() async => throw UnimplementedError();

  @override
  Future<void> logout() async => throw UnimplementedError();
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _makeJwt(int expSecondsFromNow) {
  String b64(String s) => base64Url.encode(utf8.encode(s)).replaceAll('=', '');
  final exp = DateTime.now().add(Duration(seconds: expSecondsFromNow)).millisecondsSinceEpoch ~/ 1000;
  final header = b64(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}));
  final body   = b64(jsonEncode({'exp': exp}));
  return '$header.$body.sig';
}

// ─── Suite ────────────────────────────────────────────────────────────────────

void main() {
  group('RefreshTokenUseCase.execute()', () {
    test('si no hay token guardado → devuelve false sin llamar al repo', () async {
      final repo  = _FakeRepository();
      final local = _FakeLocal(null);
      final useCase = RefreshTokenUseCase(repository: repo, local: local);

      final result = await useCase.execute();

      expect(result, isFalse);
      expect(repo.refreshCalled, isFalse);
    });

    test('si quedan ≥ 7 días para expirar → NO llama a refresh', () async {
      final repo  = _FakeRepository();
      final local = _FakeLocal(_makeJwt(15 * 24 * 60 * 60)); // 15 días
      final useCase = RefreshTokenUseCase(repository: repo, local: local);

      final result = await useCase.execute();

      expect(result, isFalse);
      expect(repo.refreshCalled, isFalse);
    });

    test('si quedan < 7 días para expirar → llama a refresh y devuelve true', () async {
      final repo  = _FakeRepository();
      final local = _FakeLocal(_makeJwt(3 * 24 * 60 * 60)); // 3 días
      final useCase = RefreshTokenUseCase(repository: repo, local: local);

      final result = await useCase.execute();

      expect(result, isTrue);
      expect(repo.refreshCalled, isTrue);
    });

    test('si el token no contiene exp legible → NO llama a refresh', () async {
      final repo  = _FakeRepository();
      final local = _FakeLocal('header.payload_invalido.sig');
      final useCase = RefreshTokenUseCase(repository: repo, local: local);

      final result = await useCase.execute();

      expect(result, isFalse);
      expect(repo.refreshCalled, isFalse);
    });
  });
}
