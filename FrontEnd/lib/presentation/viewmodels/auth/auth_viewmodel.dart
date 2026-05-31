/// @file auth_viewmodel.dart
/// @description ViewModel de autenticación. Gestiona el estado de auth de la app:
/// usuario actual, estado de carga, errores, y la lógica de login/register/logout.
/// Depende SOLO de interfaces de use cases — nunca de implementaciones concretas.
/// @module Core
/// @layer Presentation
library;

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/interfaces/usecases/auth/i_login_use_case.dart';
import '../../../domain/interfaces/usecases/auth/i_logout_use_case.dart';
import '../../../domain/interfaces/usecases/auth/i_refresh_token_use_case.dart';
import '../../../domain/interfaces/usecases/auth/i_register_use_case.dart';
import '../../../domain/interfaces/usecases/auth/i_validate_token_use_case.dart';
import '../../../domain/dtos/auth/login_request_dto.dart';
import '../../../domain/dtos/auth/register_request_dto.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH STATE
// ═══════════════════════════════════════════════════════════════════════════════

/// Estado de autenticación del usuario.
enum AuthStatus {
  /// Estado inicial antes de verificar la sesión.
  initial,

  /// Verificando sesión (splash screen).
  checking,

  /// Usuario autenticado.
  authenticated,

  /// Usuario no autenticado (pantalla de login/register).
  unauthenticated,
}

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH VIEWMODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// ViewModel de autenticación. Extiende [ChangeNotifier] para Provider.
///
/// Estado gestionado:
///  - [status]        — estado de la sesión (AuthStatus).
///  - [currentUser]   — usuario autenticado actual (null si no hay sesión).
///  - [isLoading]     — true mientras hay una operación async en curso.
///  - [error]         — último error ocurrido (null si no hay error).
///
/// [injectable] registrar en container.dart.
/// [dependencies] ILoginUseCase, IRegisterUseCase, IValidateTokenUseCase,
///                ILogoutUseCase, IRefreshTokenUseCase.
class AuthViewModel extends ChangeNotifier {
  final ILoginUseCase          _loginUseCase;
  final IRegisterUseCase       _registerUseCase;
  final IValidateTokenUseCase  _validateTokenUseCase;
  final ILogoutUseCase         _logoutUseCase;
  final IRefreshTokenUseCase   _refreshTokenUseCase;

  AuthViewModel({
    required ILoginUseCase          loginUseCase,
    required IRegisterUseCase       registerUseCase,
    required IValidateTokenUseCase  validateTokenUseCase,
    required ILogoutUseCase         logoutUseCase,
    required IRefreshTokenUseCase   refreshTokenUseCase,
  })  : _loginUseCase          = loginUseCase,
        _registerUseCase       = registerUseCase,
        _validateTokenUseCase  = validateTokenUseCase,
        _logoutUseCase         = logoutUseCase,
        _refreshTokenUseCase   = refreshTokenUseCase;

  // ─── Estado ───────────────────────────────────────────────────────────────────

  AuthStatus _status    = AuthStatus.initial;
  User?      _currentUser;
  bool       _isLoading = false;
  AppError?  _error;

  AuthStatus get status      => _status;
  User?      get currentUser => _currentUser;
  bool       get isLoading   => _isLoading;
  AppError?  get error       => _error;

  bool get isAuthenticated  => _status == AuthStatus.authenticated;
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;

  // ─── Verificar sesión (Splash) ────────────────────────────────────────────────

  /// Valida el token almacenado al arrancar la app y, si quedan menos de 7
  /// días para expirar, lo renueva silenciosamente.
  ///
  /// Política de tolerancia a fallos del refresh:
  ///  - Si `IRefreshTokenUseCase` lanza `AppError` con `requiresReauth=true`
  ///    (401/404), se trata como sesión expirada → `unauthenticated`.
  ///  - Si lanza por red/timeout (cold start de Render), se mantiene el
  ///    token actual y se autoriza la sesión — el siguiente arranque
  ///    reintentará. Evita echar al usuario por un fallo transitorio.
  ///
  /// El refresh es una optimización; nunca bloquea la apertura de la app.
  /// El watchdog absoluto vive en SplashPage (90 s); aquí solo
  /// implementamos la categorización correcta de errores y logs de
  /// diagnóstico explícitos para inspeccionar qué rama se tomó.
  ///
  /// Actualiza [status] a [AuthStatus.authenticated] o [AuthStatus.unauthenticated].
  Future<void> checkSession() async {
    _setStatus(AuthStatus.checking);

    try {
      final user = await _validateTokenUseCase.execute();
      _currentUser = user;

      // Auto-refresh silencioso si <7d para expirar. Errores de red NO
      // invalidan la sesión: el token vigente sigue siendo válido.
      try {
        await _refreshTokenUseCase.execute();
        debugPrint('[AuthViewModel] checkSession: refresh ok');
      } on AppError catch (e) {
        if (e.requiresReauth) {
          debugPrint('[AuthViewModel] checkSession: refresh unauthorized (${e.statusCode}) — redirecting to login');
          rethrow;
        }
        // Network/server transitorio: continuar autenticado con token actual.
        debugPrint('[AuthViewModel] checkSession: refresh skipped due to network/transient error (${e.code.name}) — keeping current token');
      }

      _setStatus(AuthStatus.authenticated);
    } on AppError catch (e) {
      if (e.requiresReauth) {
        debugPrint('[AuthViewModel] checkSession: validate-token unauthorized — unauthenticated');
        _setStatus(AuthStatus.unauthenticated);
      } else {
        debugPrint('[AuthViewModel] checkSession: validate-token failed (${e.code.name}) — unauthenticated');
        _setError(e);
        _setStatus(AuthStatus.unauthenticated);
      }
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────────

  /// Autentica al usuario. Actualiza [status] a [AuthStatus.authenticated] si tiene éxito.
  ///
  /// [returns] true si el login fue exitoso, false si hubo error.
  Future<bool> login({required String email, required String password}) async {
    _startLoading();

    try {
      final result = await _loginUseCase.execute(
        LoginRequestDto(email: email, password: password),
      );
      _currentUser = result.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AppError catch (e) {
      _setError(e);
      return false;
    } finally {
      _stopLoading();
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────────

  /// Registra un nuevo usuario y lo autentica directamente.
  ///
  /// [returns] true si el registro fue exitoso.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _startLoading();

    try {
      final result = await _registerUseCase.execute(
        RegisterRequestDto(name: name, email: email, password: password),
      );
      _currentUser = result.user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AppError catch (e) {
      _setError(e);
      return false;
    } finally {
      _stopLoading();
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────────

  /// Cierra la sesión llamando al `ILogoutUseCase` profundo: éste ya
  /// orquesta DELETE fcm-token remoto, FirebaseMessaging.deleteToken
  /// local, socket.disconnect, cache Hive.clearAll y secure_storage clear.
  /// Aquí solo reseteamos el estado del propio ViewModel.
  ///
  /// El call site (SettingsPage/MyProfilePage/AccountManagementPage)
  /// debe, tras este `logout()`, llamar a `appProviderGeneration.value++`
  /// y navegar con `pushNamedAndRemoveUntil('/login', false)` para
  /// reconstruir el árbol de Providers.
  Future<void> logout() async {
    await _logoutUseCase.execute();
    _currentUser = null;
    _error       = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ─── Refrescar el usuario actual ─────────────────────────────────────────────

  /// Actualiza el [User] actual tras una modificación (preferencias,
  /// perfil, banner, etc.) y notifica a los listeners. Se invoca
  /// típicamente desde `SettingsPage` después de
  /// `PUT /users/me/preferences` para evitar inconsistencias con otras
  /// partes de la UI que consulten `currentUser.preferences`.
  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  // ─── Helpers de estado ────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(AppError error) {
    _error = error;
    notifyListeners();
  }

  void _startLoading() {
    _isLoading = true;
    _error     = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }
}
