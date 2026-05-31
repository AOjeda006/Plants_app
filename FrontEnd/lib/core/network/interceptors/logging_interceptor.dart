/// @file logging_interceptor.dart
/// @description Interceptor Dio que registra peticiones y respuestas en consola.
/// Enmascara automáticamente campos sensibles (password, token, Authorization)
/// para no exponer PII en los logs de desarrollo.
/// Solo activo cuando IS_PRODUCTION=false (ver AppConfig).
/// @module Core
/// @layer Core
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CAMPOS SENSIBLES — Nunca se loguean en claro
// ═══════════════════════════════════════════════════════════════════════════════

/// Claves de cabecera o body que se enmascaran en los logs.
/// Añadir aquí cualquier campo nuevo que contenga datos sensibles.
const Set<String> _kSensitiveKeys = {
  'authorization',
  'password',
  'newPassword',
  'currentPassword',
  'token',
  'accessToken',
  'refreshToken',
  'fcmToken',
};

/// Valor sustituido por campos sensibles en el log.
const String _kMasked = '***MASKED***';

// ═══════════════════════════════════════════════════════════════════════════════
// LOGGING INTERCEPTOR
// ═══════════════════════════════════════════════════════════════════════════════

/// Interceptor Dio para logging de tráfico HTTP en desarrollo.
///
/// Registra:
///  - [onRequest]  → método, URL, cabeceras (maskeadas), body (maskeado).
///  - [onResponse] → status code, URL, body (maskeado).
///  - [onError]    → status code, URL, mensaje de error.
///
/// No activa logs en producción ([AppConfig.isProduction] == true).
class LoggingInterceptor extends Interceptor {
  // ─── onRequest ───────────────────────────────────────────────────────────────

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!AppConfig.instance.isProduction) {
      final method  = options.method.toUpperCase();
      final uri     = options.uri;
      final headers = _maskMap(options.headers);
      final body    = _maskValue(options.data);

      debugPrint('[HTTP] --> $method $uri');
      debugPrint('[HTTP]     Headers: $headers');
      if (options.data != null) {
        debugPrint('[HTTP]     Body:    $body');
      }
    }

    handler.next(options);
  }

  // ─── onResponse ──────────────────────────────────────────────────────────────

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (!AppConfig.instance.isProduction) {
      final status = response.statusCode;
      final uri    = response.requestOptions.uri;
      final body   = _maskValue(response.data);

      debugPrint('[HTTP] <-- $status $uri');
      debugPrint('[HTTP]     Body: $body');
    }

    handler.next(response);
  }

  // ─── onError ─────────────────────────────────────────────────────────────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!AppConfig.instance.isProduction) {
      final status  = err.response?.statusCode ?? 'N/A';
      final uri     = err.requestOptions.uri;
      final message = err.message ?? err.type.name;

      debugPrint('[HTTP] <!> $status $uri — $message');
    }

    handler.next(err);
  }

  // ─── Helpers de masking ───────────────────────────────────────────────────────

  /// Enmascara recursivamente un valor dinámico (Map, List o primitivo).
  dynamic _maskValue(dynamic value) {
    if (value is Map<String, dynamic>) return _maskMap(value);
    if (value is Map)                  return _maskMap(Map<String, dynamic>.from(value));
    if (value is List)                 return value.map(_maskValue).toList();
    return value;
  }

  /// Sustituye por [_kMasked] cualquier clave incluida en [_kSensitiveKeys].
  Map<String, dynamic> _maskMap(Map<Object?, Object?> original) {
    return {
      for (final entry in original.entries)
        entry.key.toString(): _kSensitiveKeys.contains(
          entry.key.toString().toLowerCase(),
        )
            ? _kMasked
            : _maskValue(entry.value),
    };
  }
}
