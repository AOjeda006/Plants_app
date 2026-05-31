/// @file auth_remote_data_source.dart
/// @description Fuente de datos remota para autenticación.
/// Encapsula todas las llamadas HTTP al módulo /auth de la API.
/// Devuelve Maps crudos (el mapper convierte a entidades en el repositorio).
/// Lanza AppError en caso de fallo — lo propaga desde ApiClient.
/// @module Core
/// @layer Data
library;

import 'package:dio/dio.dart' show Options;

import '../../../core/network/api_client.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH REMOTE DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Datasource remoto para las operaciones de autenticación.
///
/// Endpoints cubiertos:
///  - POST /auth/register
///  - POST /auth/login
///  - GET  /auth/validate-token
///  - POST /auth/refresh        (renovación silenciosa del JWT)
///
/// [injectable] registrar en container.dart.
/// [dependencies] ApiClient.
class AuthRemoteDataSource {
  final ApiClient _apiClient;

  const AuthRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  // ─── Register ────────────────────────────────────────────────────────────────

  /// Registra un nuevo usuario.
  ///
  /// [returns] Map con { user, token } tal como lo devuelve la API.
  /// [throws] AppError.validation si los datos no superan validación (422).
  /// [throws] AppError.server si hay error interno (5xx).
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
  }

  // ─── Login ────────────────────────────────────────────────────────────────────

  /// Inicia sesión con email y contraseña.
  ///
  /// [returns] Map con { user, token }.
  /// [throws] AppError.unauthorized si las credenciales son incorrectas (401).
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
  }

  // ─── Validate token ───────────────────────────────────────────────────────────

  /// Valida el token actual y devuelve los datos del usuario autenticado.
  ///
  /// [returns] Map con { user } (el token se envía automáticamente por AuthInterceptor).
  /// [throws] AppError.unauthorized si el token es inválido o ha expirado.
  Future<Map<String, dynamic>> validateToken() async {
    return _apiClient.get<Map<String, dynamic>>('/auth/validate-token');
  }

  // ─── Refresh token ────────────────────────────────────────────────────────────

  /// Renueva el token JWT actual con expiración fresca (30d).
  /// El token actual se envía automáticamente vía AuthInterceptor; el body
  /// es vacío.
  ///
  /// [returns] Map con { user, token } (mismo formato que login/register).
  /// [throws] AppError.unauthorized si el token actual ha expirado o es
  ///          inválido (401).
  /// [throws] AppError.notFound si el usuario fue soft-deleted (404).
  Future<Map<String, dynamic>> refreshToken() async {
    // Timeout corto: el refresh es una optimización; si tarda demasiado,
    // abandonamos y mantenemos el token actual (sigue siendo válido hasta
    // su expiración real). Se aplica como override de receiveTimeout vía
    // Options del request concreto.
    return _apiClient.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: const <String, dynamic>{},
      options: Options(receiveTimeout: kShortReceiveTimeout),
    );
  }
}
