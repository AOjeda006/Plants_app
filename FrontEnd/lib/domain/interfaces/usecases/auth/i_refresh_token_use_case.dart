/// @file i_refresh_token_use_case.dart
/// @description Interfaz del caso de uso de auto-refresh del token JWT.
/// @module Core
/// @layer Domain
library;

/// Contrato del caso de uso que decide y ejecuta el auto-refresh del token
/// almacenado.
///
/// Comportamiento:
/// - Lee el token actual del almacenamiento seguro.
/// - Decodifica el `exp` (sin verificar firma — eso es del backend).
/// - Si quedan ≥ [refreshThresholdDays] días para expirar → no hace nada
///   y devuelve `false`.
/// - Si quedan menos → llama a `POST /auth/refresh`. Si éxito persiste el
///   nuevo token y devuelve `true`. Si error, propaga la excepción.
///
/// Si no hay token guardado, devuelve `false` sin lanzar.
abstract interface class IRefreshTokenUseCase {
  /// Ejecuta la decisión de refresh.
  ///
  /// [refreshThresholdDays] Si quedan menos de esta cantidad de días para
  /// expirar, se renueva. Por defecto 7d (el JWT vive 30d, se renueva
  /// silenciosamente en la última semana).
  ///
  /// [returns] `true` si se renovó el token; `false` si no era necesario.
  /// [throws] AppError.unauthorized si el backend rechaza el refresh (401).
  /// [throws] AppError.notFound si el usuario fue soft-deleted (404).
  Future<bool> execute({double refreshThresholdDays = 7.0});
}
