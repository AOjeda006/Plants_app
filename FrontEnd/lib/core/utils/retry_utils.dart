/// @file retry_utils.dart
/// @description Generador de backoff exponencial con jitter para reintentos.
/// Usado por RetryInterceptor, SocketClient y servicios que reintentan
/// con backoff exponencial, para evitar duplicar la lógica.
/// @module Core
/// @layer Core
library;

import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════════════════════════
// RETRY UTILS
// ═══════════════════════════════════════════════════════════════════════════════

/// Utilidades estáticas para calcular tiempos de espera con backoff exponencial.
abstract final class RetryUtils {
  static final math.Random _rng = math.Random();

  // ─── Backoff exponencial con jitter ──────────────────────────────────────────

  /// Calcula la duración de espera para el intento número [attempt] (0-based).
  ///
  /// Algoritmo: `min(base * factor^attempt, maxDelay) + jitter[0, jitterMax]`
  ///
  /// [attempt]     — número de intento actual (0 = primera espera).
  /// [base]        — duración base inicial (por defecto 1 s).
  /// [factor]      — factor multiplicador (por defecto 2.0 = exponencial).
  /// [maxDelay]    — tope máximo de espera (por defecto 30 s).
  /// [maxJitter]   — máximo de jitter aleatorio añadido (por defecto 1 s).
  static Duration computeDelay({
    required int attempt,
    Duration base       = const Duration(seconds: 1),
    double factor       = 2.0,
    Duration maxDelay   = const Duration(seconds: 30),
    Duration maxJitter  = const Duration(seconds: 1),
  }) {
    final exponential = base * math.pow(factor, attempt);
    final capped      = exponential > maxDelay ? maxDelay : exponential;
    final jitter      = Duration(milliseconds: _rng.nextInt(maxJitter.inMilliseconds + 1));
    return capped + jitter;
  }

  // ─── Generador de secuencias ─────────────────────────────────────────────────

  /// Devuelve una lista con los delays de cada intento de 0 hasta [maxRetries-1].
  ///
  /// Útil para depuración o para mostrar al usuario el tiempo estimado de reintento.
  static List<Duration> delaySequence({
    required int maxRetries,
    Duration base       = const Duration(seconds: 1),
    double factor       = 2.0,
    Duration maxDelay   = const Duration(seconds: 30),
  }) {
    return List.generate(maxRetries, (attempt) {
      final exp    = base * math.pow(factor, attempt);
      return exp > maxDelay ? maxDelay : exp;
      // Sin jitter aquí para que la secuencia sea determinista (testing/debug).
    });
  }

  // ─── Reintento genérico con Future ───────────────────────────────────────────

  /// Ejecuta [operation] con reintentos automáticos si lanza una excepción.
  ///
  /// [operation]   — función async a reintentar.
  /// [maxRetries]  — número máximo de reintentos (intentos totales = maxRetries + 1).
  /// [shouldRetry] — predicado opcional: si devuelve false, no reintenta ese error.
  ///
  /// Lanza la última excepción si se agotan todos los intentos.
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries        = 3,
    Duration base         = const Duration(seconds: 1),
    double factor         = 2.0,
    Duration maxDelay     = const Duration(seconds: 30),
    bool Function(Object error)? shouldRetry,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        return await operation();
      } catch (error) {
        final retriable = shouldRetry?.call(error) ?? true;

        if (!retriable || attempt >= maxRetries) rethrow;

        final delay = computeDelay(
          attempt: attempt,
          base:     base,
          factor:   factor,
          maxDelay: maxDelay,
        );
        await Future<void>.delayed(delay);
        attempt++;
      }
    }
  }
}
