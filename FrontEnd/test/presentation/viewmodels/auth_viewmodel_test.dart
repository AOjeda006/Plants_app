/// @file auth_viewmodel_test.dart
/// @description Tests unitarios para AuthViewModel.
/// Verifica login, register, logout, checkSession y gestión de errores.
/// Usa mocks manuales de las interfaces de use cases.
/// @module Auth
/// @layer Presentation
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/domain/entities/user.dart';
import 'package:plants_app/domain/dtos/auth/login_request_dto.dart';
import 'package:plants_app/domain/dtos/auth/register_request_dto.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_login_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_register_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_validate_token_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_logout_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_refresh_token_use_case.dart';
import 'package:plants_app/presentation/viewmodels/auth/auth_viewmodel.dart';

// ─── Mocks manuales ───────────────────────────────────────────────────────────

class _MockLoginUseCase implements ILoginUseCase {
  ({User user, String token})? returnValue;
  AppError? throwError;

  @override
  Future<({User user, String token})> execute(LoginRequestDto dto) async {
    if (throwError != null) throw throwError!;
    return returnValue!;
  }
}

class _MockRegisterUseCase implements IRegisterUseCase {
  ({User user, String token})? returnValue;
  AppError? throwError;

  @override
  Future<({User user, String token})> execute(RegisterRequestDto dto) async {
    if (throwError != null) throw throwError!;
    return returnValue!;
  }
}

class _MockValidateTokenUseCase implements IValidateTokenUseCase {
  User? returnValue;
  AppError? throwError;

  @override
  Future<User> execute() async {
    if (throwError != null) throw throwError!;
    return returnValue!;
  }
}

class _MockLogoutUseCase implements ILogoutUseCase {
  @override
  Future<void> execute() async {}
}

class _MockRefreshTokenUseCase implements IRefreshTokenUseCase {
  AppError? throwError;
  bool      didRefresh = false;

  @override
  Future<bool> execute({double refreshThresholdDays = 7.0}) async {
    if (throwError != null) throw throwError!;
    return didRefresh;
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

User _makeUser({String id = 'user-001'}) => User(
      id:        id,
      name:      'Test User',
      email:     'test@example.com',
      role:      'user',
      createdAt: DateTime.utc(2026, 1, 1),
    );

AuthViewModel _makeViewModel({
  _MockLoginUseCase?          login,
  _MockRegisterUseCase?       register,
  _MockValidateTokenUseCase?  validate,
  _MockLogoutUseCase?         logout,
  _MockRefreshTokenUseCase?   refresh,
}) {
  return AuthViewModel(
    loginUseCase:          login    ?? _MockLoginUseCase(),
    registerUseCase:       register ?? _MockRegisterUseCase(),
    validateTokenUseCase:  validate ?? _MockValidateTokenUseCase(),
    logoutUseCase:         logout   ?? _MockLogoutUseCase(),
    refreshTokenUseCase:   refresh  ?? _MockRefreshTokenUseCase(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── checkSession ─────────────────────────────────────────────────────────────

  group('checkSession()', () {
    test('debe pasar a authenticated si el token es válido', () async {
      final validate = _MockValidateTokenUseCase()..returnValue = _makeUser();
      final vm = _makeViewModel(validate: validate);

      await vm.checkSession();

      expect(vm.status, AuthStatus.authenticated);
      expect(vm.currentUser, isNotNull);
      expect(vm.currentUser!.id, 'user-001');
    });

    test('debe pasar a unauthenticated si el token es inválido (requiresReauth)', () async {
      final validate = _MockValidateTokenUseCase()
        ..throwError = AppError.unauthorized('Token expirado');
      final vm = _makeViewModel(validate: validate);

      await vm.checkSession();

      expect(vm.status, AuthStatus.unauthenticated);
      expect(vm.currentUser, isNull);
    });

    test('debe pasar a unauthenticated ante error de red', () async {
      final validate = _MockValidateTokenUseCase()
        ..throwError = AppError.network('Sin conexión');
      final vm = _makeViewModel(validate: validate);

      await vm.checkSession();

      expect(vm.status, AuthStatus.unauthenticated);
    });
  });

  // ── login ─────────────────────────────────────────────────────────────────────

  group('login()', () {
    test('debe devolver true y establecer authenticated si las credenciales son válidas', () async {
      final login = _MockLoginUseCase()
        ..returnValue = (user: _makeUser(), token: 'jwt.token.xyz');
      final vm = _makeViewModel(login: login);

      final result = await vm.login(email: 'test@example.com', password: 'Pass1234!');

      expect(result, isTrue);
      expect(vm.isAuthenticated, isTrue);
      expect(vm.currentUser!.email, 'test@example.com');
      expect(vm.isLoading, isFalse);
    });

    test('debe devolver false y guardar el error si las credenciales son incorrectas', () async {
      final login = _MockLoginUseCase()
        ..throwError = AppError.unauthorized('Credenciales incorrectas');
      final vm = _makeViewModel(login: login);

      final result = await vm.login(email: 'test@example.com', password: 'wrong');

      expect(result, isFalse);
      expect(vm.isAuthenticated, isFalse);
      expect(vm.error, isNotNull);
      expect(vm.isLoading, isFalse);
    });

    test('isLoading debe ser true durante la operación', () async {
      bool? loadingDuringCall;
      final login = _MockLoginUseCase()
        ..returnValue = (user: _makeUser(), token: 'jwt.token.xyz');
      final vm = _makeViewModel(login: login);

      // Escuchar notificaciones para capturar estado intermedio.
      vm.addListener(() { loadingDuringCall ??= vm.isLoading; });

      await vm.login(email: 'x@x.com', password: 'Pass1234!');

      // Después de terminar, isLoading debe ser false.
      expect(vm.isLoading, isFalse);
    });
  });

  // ── register ──────────────────────────────────────────────────────────────────

  group('register()', () {
    test('debe devolver true y autenticar al usuario tras registro exitoso', () async {
      final register = _MockRegisterUseCase()
        ..returnValue = (user: _makeUser(), token: 'jwt.new.token');
      final vm = _makeViewModel(register: register);

      final result = await vm.register(
        name:     'Test User',
        email:    'new@example.com',
        password: 'Pass1234!',
      );

      expect(result, isTrue);
      expect(vm.isAuthenticated, isTrue);
    });

    test('debe devolver false y guardar error si el email ya existe (409)', () async {
      final register = _MockRegisterUseCase()
        ..throwError = AppError.server('Email ya registrado');
      final vm = _makeViewModel(register: register);

      final result = await vm.register(
        name: 'User', email: 'dup@example.com', password: 'Pass1234!',
      );

      expect(result, isFalse);
      expect(vm.error, isNotNull);
    });
  });

  // ── logout ────────────────────────────────────────────────────────────────────

  group('logout()', () {
    test('debe limpiar el usuario y pasar a unauthenticated', () async {
      final login = _MockLoginUseCase()
        ..returnValue = (user: _makeUser(), token: 'jwt');
      final vm = _makeViewModel(login: login);

      await vm.login(email: 'x@x.com', password: 'Pass!');
      expect(vm.isAuthenticated, isTrue);

      await vm.logout();

      expect(vm.isUnauthenticated, isTrue);
      expect(vm.currentUser, isNull);
      expect(vm.error, isNull);
    });
  });

  // ── clearError ────────────────────────────────────────────────────────────────

  group('clearError()', () {
    test('debe limpiar el error acumulado', () async {
      final login = _MockLoginUseCase()
        ..throwError = AppError.unauthorized('Error');
      final vm = _makeViewModel(login: login);

      await vm.login(email: 'x@x.com', password: 'wrong');
      expect(vm.error, isNotNull);

      vm.clearError();
      expect(vm.error, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════════
  // Auto-refresh del token JWT en checkSession()
  // ═══════════════════════════════════════════════════════════════════════════════

  group('checkSession() — auto-refresh del token', () {
    test('si validateToken OK y refresh ejecuta sin error → autenticado', () async {
      final validate = _MockValidateTokenUseCase()..returnValue = _makeUser();
      final refresh  = _MockRefreshTokenUseCase()..didRefresh = true;
      final vm = _makeViewModel(validate: validate, refresh: refresh);

      await vm.checkSession();

      expect(vm.status,      AuthStatus.authenticated);
      expect(vm.currentUser, isNotNull);
    });

    test('si refresh devuelve false (token aún vigente) → autenticado', () async {
      final validate = _MockValidateTokenUseCase()..returnValue = _makeUser();
      final refresh  = _MockRefreshTokenUseCase()..didRefresh = false;
      final vm = _makeViewModel(validate: validate, refresh: refresh);

      await vm.checkSession();

      expect(vm.status, AuthStatus.authenticated);
    });

    test('si refresh lanza network error → MANTIENE sesión (no echa al usuario)', () async {
      final validate = _MockValidateTokenUseCase()..returnValue = _makeUser();
      final refresh  = _MockRefreshTokenUseCase()
        ..throwError = AppError.network('Sin conexión');
      final vm = _makeViewModel(validate: validate, refresh: refresh);

      await vm.checkSession();

      // Network error NO requiere reauth → sigue autenticado con token actual.
      expect(vm.status,      AuthStatus.authenticated);
      expect(vm.currentUser, isNotNull);
    });

    test('si refresh lanza 401 → invalida sesión (unauthenticated)', () async {
      final validate = _MockValidateTokenUseCase()..returnValue = _makeUser();
      final refresh  = _MockRefreshTokenUseCase()
        ..throwError = AppError.unauthorized('Token rechazado');
      final vm = _makeViewModel(validate: validate, refresh: refresh);

      await vm.checkSession();

      expect(vm.status, AuthStatus.unauthenticated);
    });
  });
}
