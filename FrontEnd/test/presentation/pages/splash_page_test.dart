/// @file splash_page_test.dart
/// @description Widget tests de SplashPage. Cubre el watchdog de 90 s:
/// si `checkSession` no termina en ese plazo, el splash muestra una
/// pantalla de error explícita que permite reintentar o continuar con
/// el token actual, evitando el spinner infinito ante un cold start
/// anómalo del backend.
/// @module Auth
/// @layer Presentation
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'package:plants_app/core/errors/app_error.dart';
import 'package:plants_app/core/storage/auth_local_data_source.dart';
import 'package:plants_app/domain/dtos/auth/login_request_dto.dart';
import 'package:plants_app/domain/dtos/auth/register_request_dto.dart';
import 'package:plants_app/domain/entities/user.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_login_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_logout_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_refresh_token_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_register_use_case.dart';
import 'package:plants_app/domain/interfaces/usecases/auth/i_validate_token_use_case.dart';
import 'package:plants_app/presentation/pages/splash_page.dart';
import 'package:plants_app/presentation/viewmodels/auth/auth_viewmodel.dart';

// ─── Stubs / mocks ────────────────────────────────────────────────────────────

class _StubLogin implements ILoginUseCase {
  @override
  Future<({User user, String token})> execute(LoginRequestDto dto) async =>
      throw UnimplementedError();
}

class _StubRegister implements IRegisterUseCase {
  @override
  Future<({User user, String token})> execute(RegisterRequestDto dto) async =>
      throw UnimplementedError();
}

class _StubLogout implements ILogoutUseCase {
  @override
  Future<void> execute() async {}
}

class _StubRefresh implements IRefreshTokenUseCase {
  @override
  Future<bool> execute({double refreshThresholdDays = 7.0}) async => false;
}

/// validateToken que nunca termina — simula un cold start patológico de
/// Render que excede los 90 s del watchdog.
class _HangingValidate implements IValidateTokenUseCase {
  final Completer<User> _completer = Completer<User>();
  @override
  Future<User> execute() => _completer.future;
}

/// validateToken rápido que devuelve un user válido — control para
/// verificar que cuando todo va bien el watchdog NO interfiere.
class _OkValidate implements IValidateTokenUseCase {
  @override
  Future<User> execute() async => User(
        id:        'user-001',
        name:      'Test',
        email:     't@t.com',
        role:      'user',
        createdAt: DateTime.utc(2026, 1, 1),
      );
}

/// AuthLocalDataSource sustituido por un stub en memoria. Se registra
/// en GetIt para que el watchdog del splash lea aquí en lugar de
/// SecureStorage real.
class _MemoryAuthLocal extends AuthLocalDataSource {
  _MemoryAuthLocal({required String? token}) : _token = token;
  final String? _token;

  @override
  Future<String?> getAccessToken() async => _token;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _sl = GetIt.instance;

void _registerLocal({required String? token}) {
  if (_sl.isRegistered<AuthLocalDataSource>()) {
    _sl.unregister<AuthLocalDataSource>();
  }
  _sl.registerSingleton<AuthLocalDataSource>(_MemoryAuthLocal(token: token));
}

AuthViewModel _makeVm(IValidateTokenUseCase validate) => AuthViewModel(
      loginUseCase:          _StubLogin(),
      registerUseCase:       _StubRegister(),
      validateTokenUseCase:  validate,
      logoutUseCase:         _StubLogout(),
      refreshTokenUseCase:   _StubRefresh(),
    );

/// Envuelve la SplashPage con MaterialApp + Provider y rutas mockeadas
/// (`/home` y `/login` muestran un Text identificable para aserciones).
Widget _wrap(AuthViewModel vm) => MaterialApp(
      home: ChangeNotifierProvider<AuthViewModel>.value(
        value: vm,
        child: const SplashPage(),
      ),
      routes: {
        '/home':  (_) => const Scaffold(body: Text('HOME')),
        '/login': (_) => const Scaffold(body: Text('LOGIN')),
      },
    );

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  // Evita que flutter_secure_storage intente acceder al canal nativo en
  // tests (lo sustituimos en GetIt por _MemoryAuthLocal).
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  tearDown(() {
    if (_sl.isRegistered<AuthLocalDataSource>()) {
      _sl.unregister<AuthLocalDataSource>();
    }
  });

  group('SplashPage watchdog', () {
    testWidgets(
      'si checkSession se cuelga >90 s → muestra pantalla de error con Reintentar/Continuar',
      (tester) async {
        _registerLocal(token: 'jwt.cached.token');
        final vm = _makeVm(_HangingValidate());

        await tester.pumpWidget(_wrap(vm));
        // Estado inicial: spinner.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Avanzamos el reloj 91 s — el watchdog debería disparar a los 90 s.
        await tester.pump(const Duration(seconds: 91));

        // Muestra la pantalla de error explícita.
        expect(find.text('No se pudo conectar con el servidor'), findsOneWidget);
        expect(find.byKey(const ValueKey('splash_retry_button')), findsOneWidget);
        expect(find.byKey(const ValueKey('splash_offline_button')), findsOneWidget);
        // Sin navegar aún.
        expect(find.text('HOME'),  findsNothing);
        expect(find.text('LOGIN'), findsNothing);
      },
    );

    testWidgets(
      'tras pantalla de error: tap "Continuar sin conexión" con token → /home',
      (tester) async {
        _registerLocal(token: 'jwt.cached.token');
        final vm = _makeVm(_HangingValidate());

        await tester.pumpWidget(_wrap(vm));
        await tester.pump(const Duration(seconds: 91));
        // Pantalla de error visible — pulsar "Continuar sin conexión".
        await tester.tap(find.byKey(const ValueKey('splash_offline_button')));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        expect(find.text('HOME'),  findsOneWidget);
      },
    );

    testWidgets(
      'tras pantalla de error: tap "Continuar sin conexión" sin token → /login',
      (tester) async {
        _registerLocal(token: null);
        final vm = _makeVm(_HangingValidate());

        await tester.pumpWidget(_wrap(vm));
        await tester.pump(const Duration(seconds: 91));
        await tester.tap(find.byKey(const ValueKey('splash_offline_button')));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        expect(find.text('LOGIN'), findsOneWidget);
      },
    );

    testWidgets(
      'si checkSession termina antes del watchdog → navega normalmente',
      (tester) async {
        _registerLocal(token: 'jwt.cached.token');
        final vm = _makeVm(_OkValidate());

        await tester.pumpWidget(_wrap(vm));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('HOME'), findsOneWidget);
        expect(vm.isAuthenticated, isTrue);
      },
    );
  });

  // ── Categorización en checkSession ─────────────────────────────────────────

  group('AuthViewModel.checkSession() — categorización 401 vs network', () {
    testWidgets('refresh devuelve AppError.network → mantiene sesión', (tester) async {
      // Test mínimo de regresión: validateToken OK + refresh transitorio
      // → authenticated. Cubierto en auth_viewmodel_test.dart, replicado
      // aquí para fijar el contrato desde el SplashPage.
      _registerLocal(token: 'jwt.cached.token');

      final vm = AuthViewModel(
        loginUseCase:          _StubLogin(),
        registerUseCase:       _StubRegister(),
        validateTokenUseCase:  _OkValidate(),
        logoutUseCase:         _StubLogout(),
        refreshTokenUseCase:   _ThrowingRefresh(AppError.network('offline')),
      );

      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('HOME'), findsOneWidget);
      expect(vm.isAuthenticated, isTrue);
    });

    testWidgets('refresh devuelve AppError.unauthorized → redirige a /login', (tester) async {
      _registerLocal(token: 'jwt.cached.token');

      final vm = AuthViewModel(
        loginUseCase:          _StubLogin(),
        registerUseCase:       _StubRegister(),
        validateTokenUseCase:  _OkValidate(),
        logoutUseCase:         _StubLogout(),
        refreshTokenUseCase:   _ThrowingRefresh(AppError.unauthorized('expired')),
      );

      await tester.pumpWidget(_wrap(vm));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('LOGIN'), findsOneWidget);
      expect(vm.isAuthenticated, isFalse);
    });
  });
}

class _ThrowingRefresh implements IRefreshTokenUseCase {
  _ThrowingRefresh(this._error);
  final AppError _error;
  @override
  Future<bool> execute({double refreshThresholdDays = 7.0}) async => throw _error;
}
