/// @file app_error.dart
/// @description Clase de error unificada para toda la app.
/// Todos los errores de red, dominio y validación se mapean a AppError
/// para que los ViewModels solo gestionen un único tipo de excepción.
/// @module Core
/// @layer Core
library;

// ═══════════════════════════════════════════════════════════════════════════════
// CÓDIGOS DE ERROR — Coinciden con los codes del backend (HttpException)
// ═══════════════════════════════════════════════════════════════════════════════

/// Códigos semánticos de error que coinciden con los del backend.
/// Facilita mostrar mensajes específicos en la UI según el tipo de fallo.
enum ErrorCode {
  /// Token ausente, expirado o inválido.
  unauthorized,

  /// El recurso pedido no existe.
  notFound,

  /// Los datos enviados no superan validación.
  validation,

  /// Error de conectividad (sin red o timeout).
  network,

  /// Error interno del servidor (5xx).
  server,

  /// Servicio externo no disponible (Cloudinary, WeatherAPI, Firebase).
  externalService,

  /// Error genérico no clasificado.
  unknown,
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP ERROR
// ═══════════════════════════════════════════════════════════════════════════════

/// Error unificado de la aplicación. Implementa [Exception] para poder
/// ser lanzado y capturado con try/catch en toda la app.
///
/// Todos los errores (red, dominio, validación) se convierten a AppError
/// antes de llegar a los ViewModels. Los ViewModels solo manejan AppError.
class AppError implements Exception {
  const AppError({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  /// Código semántico del error.
  final ErrorCode code;

  /// Mensaje legible por el usuario (o para logs en inglés).
  final String message;

  /// Detalles adicionales opcionales (p.ej. lista de errores de validación).
  final dynamic details;

  /// HTTP status code original (si procede de la API).
  final int? statusCode;

  // ─── Factories para los casos comunes ────────────────────────────────────────

  /// Error de autenticación — token ausente, expirado o inválido.
  factory AppError.unauthorized([String message = 'Unauthorized']) =>
      AppError(code: ErrorCode.unauthorized, message: message, statusCode: 401);

  /// El recurso solicitado no existe en el servidor.
  factory AppError.notFound([String message = 'Resource not found']) =>
      AppError(code: ErrorCode.notFound, message: message, statusCode: 404);

  /// Los datos del formulario o petición no son válidos.
  factory AppError.validation(String message, {dynamic details}) =>
      AppError(code: ErrorCode.validation, message: message, details: details, statusCode: 422);

  /// Sin conexión o timeout de red.
  factory AppError.network([String message = 'Network error. Check your connection.']) =>
      AppError(code: ErrorCode.network, message: message);

  /// Error interno del servidor (5xx).
  factory AppError.server([String message = 'Server error. Please try again later.']) =>
      AppError(code: ErrorCode.server, message: message, statusCode: 500);

  /// Un servicio externo (Cloudinary, Weather, Firebase) falló.
  factory AppError.externalService([String message = 'External service unavailable.']) =>
      AppError(code: ErrorCode.externalService, message: message);

  /// Error genérico no clasificado.
  factory AppError.unknown([String message = 'An unexpected error occurred.']) =>
      AppError(code: ErrorCode.unknown, message: message);

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// true si el error requiere que el usuario vuelva a hacer login.
  bool get requiresReauth => code == ErrorCode.unauthorized;

  /// true si se puede reintentar la operación (errores de red o servidor).
  bool get isRetryable =>
      code == ErrorCode.network || code == ErrorCode.server || code == ErrorCode.externalService;

  /// true si se debe mostrar al usuario como error de validación de formulario.
  bool get isValidation => code == ErrorCode.validation;

  @override
  String toString() => 'AppError(${code.name}): $message'
      '${statusCode != null ? ' [$statusCode]' : ''}'
      '${details != null ? ' — details: $details' : ''}';
}
