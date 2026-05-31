/// @file auth_interceptor.dart
/// @description Interceptor Dio que inyecta el Bearer token en cada petición saliente.
/// Lee el token mediante un proveedor inyectado (tokenProvider) para no acoplarse
/// a la implementación concreta de almacenamiento.
/// En caso de 401 lanza AppError.unauthorized para que el ViewModel redirija al login.
/// @module Core
/// @layer Core
library;

import 'package:dio/dio.dart';

import '../../errors/app_error.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH INTERCEPTOR
// ═══════════════════════════════════════════════════════════════════════════════

/// Interceptor Dio que gestiona la autenticación de cada petición.
///
/// Funciones:
///  1. [onRequest]  — añade `Authorization: Bearer <token>` si hay sesión activa.
///  2. [onError]    — convierte respuestas 401 en [AppError.unauthorized].
///
/// [dependencies] tokenProvider: función async que devuelve el access token
///                guardado en almacenamiento seguro (o null si no hay sesión).
class AuthInterceptor extends Interceptor {
  /// Proveedor de token: se inyecta desde el DI container.
  /// Devuelve el access token vigente o null si el usuario no está autenticado.
  final Future<String?> Function() tokenProvider;

  const AuthInterceptor({required this.tokenProvider});

  // ─── onRequest ───────────────────────────────────────────────────────────────

  /// Añade la cabecera Authorization antes de enviar la petición.
  ///
  /// Si no hay token (usuario sin sesión), la petición continúa sin cabecera
  /// para que el backend devuelva el 401 correspondiente (endpoints protegidos).
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenProvider();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  // ─── onError ─────────────────────────────────────────────────────────────────

  /// Convierte una respuesta 401 en [AppError.unauthorized].
  ///
  /// Esto unifica el manejo de sesión expirada en todos los ViewModels:
  /// solo necesitan capturar AppError y verificar [AppError.requiresReauth].
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expirado o inválido → forzar re-autenticación.
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response:       err.response,
          type:           DioExceptionType.badResponse,
          error:          AppError.unauthorized(
            err.response?.data?['message'] as String? ?? 'Session expired. Please log in again.',
          ),
        ),
      );
      return;
    }

    // Cualquier otro error sigue la cadena de interceptores.
    handler.next(err);
  }
}
