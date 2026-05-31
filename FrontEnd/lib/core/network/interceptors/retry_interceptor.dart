/// @file retry_interceptor.dart
/// @description Interceptor Dio con reintento automático y backoff exponencial con jitter.
/// Solo reintenta errores de red y 5xx (errores recuperables).
/// NO reintenta 4xx (errores del cliente) ni cancelaciones.
/// @module Core
/// @layer Core
library;

import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../../errors/app_error.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTES DE BACKOFF
// ═══════════════════════════════════════════════════════════════════════════════

/// Espera base entre reintentos (duplica en cada intento).
const Duration _kBaseDelay = Duration(seconds: 1);

/// Espera máxima entre reintentos (cap del backoff).
const Duration _kMaxDelay = Duration(seconds: 30);

/// Factor de crecimiento del backoff exponencial.
const double _kBackoffFactor = 2.0;

// ═══════════════════════════════════════════════════════════════════════════════
// RETRY INTERCEPTOR
// ═══════════════════════════════════════════════════════════════════════════════

/// Interceptor Dio que reintenta peticiones fallidas con backoff exponencial + jitter.
///
/// Configuración:
/// - [maxRetries]  número máximo de reintentos (por defecto 3).
/// - [retryOn5xx]  si true, reintenta errores 5xx del servidor (por defecto true).
/// - [retryOnNetwork] si true, reintenta errores de conectividad (por defecto true).
///
/// Algoritmo: `delay = min(base * factor^intento, max) + jitter(0..1s)`
///
/// Errores que NUNCA se reintentan:
///  - 4xx (errores del cliente: credenciales, validación, not found…)
///  - Cancelaciones ([DioExceptionType.cancel])
///  - Errores ya clasificados como [AppError]
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final bool retryOn5xx;
  final bool retryOnNetwork;

  /// Generador de números aleatorios para el jitter.
  final math.Random _rng = math.Random();

  RetryInterceptor({
    this.maxRetries    = 3,
    this.retryOn5xx    = true,
    this.retryOnNetwork = true,
  });

  // ─── onError ─────────────────────────────────────────────────────────────────

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = _getAttempt(err.requestOptions);

    if (!_shouldRetry(err) || attempt >= maxRetries) {
      // No se puede o no se debe reintentar: propaga el error.
      handler.next(err);
      return;
    }

    // Calcular espera con backoff exponencial + jitter aleatorio hasta 1 s.
    final delay = _computeDelay(attempt);
    await Future<void>.delayed(delay);

    // Incrementar contador de intentos y reintentar la petición original.
    final options = err.requestOptions
      ..extra[_kAttemptKey] = attempt + 1;

    try {
      // Reutilizamos la misma instancia Dio a través del DioException.
      final response = await err.requestOptions.extra[_kDioKey]
          // ignore: avoid_dynamic_calls
          ?.fetch(options) as Response<dynamic>?;

      if (response != null) {
        handler.resolve(response);
        return;
      }
    } catch (_) {
      // Si el reintento también falla, propaga el error original.
    }

    handler.next(err);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Clave interna usada para almacenar el número de intentos en [RequestOptions.extra].
  static const String _kAttemptKey = '_retry_attempt';

  /// Clave interna para la referencia a Dio (inyectada por [ApiClient]).
  static const String _kDioKey = '_dio_instance';

  /// Devuelve el intento actual (0 = primera vez, 1 = primer reintento, …).
  int _getAttempt(RequestOptions options) =>
      (options.extra[_kAttemptKey] as int?) ?? 0;

  /// true si el error es recuperable y se puede reintentar.
  bool _shouldRetry(DioException err) {
    // Cancelaciones y errores de cliente (4xx) nunca se reintentan.
    if (err.type == DioExceptionType.cancel) return false;

    final status = err.response?.statusCode;

    // Error del cliente (4xx) → no reintentar.
    if (status != null && status >= 400 && status < 500) return false;

    // El error ya fue clasificado como AppError (e.g. por AuthInterceptor) → no reintentar.
    if (err.error is AppError) return false;

    // Errores de red (sin respuesta): timeout, sin conexión, etc.
    if (retryOnNetwork && err.response == null) return true;

    // Errores 5xx del servidor.
    if (retryOn5xx && status != null && status >= 500) return true;

    return false;
  }

  /// Calcula la espera con backoff exponencial cap + jitter uniforme [0, 1s].
  Duration _computeDelay(int attempt) {
    final exponential = _kBaseDelay * math.pow(_kBackoffFactor, attempt);
    final capped = exponential > _kMaxDelay ? _kMaxDelay : exponential;
    final jitterMs = _rng.nextInt(1000); // jitter hasta 1 segundo
    return capped + Duration(milliseconds: jitterMs);
  }
}
