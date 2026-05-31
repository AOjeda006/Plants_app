/// @file i_auth_repository.dart
/// @description Interfaz del repositorio de autenticación.
/// Define el contrato que los use cases de auth consumen.
/// La implementación concreta vive en data/repositories/auth_repository_impl.dart.
/// @module Core
/// @layer Domain
library;

import '../entities/user.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I AUTH REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato del repositorio de autenticación.
///
/// Los use cases de auth dependen de esta interfaz, nunca de la implementación.
/// Devuelve entidades [User] — los modelos y la persistencia son detalles de data.
abstract interface class IAuthRepository {
  /// Registra un nuevo usuario y devuelve la entidad creada.
  ///
  /// [throws] AppError.validation si los datos no superan validación.
  /// [throws] AppError.network si no hay conexión.
  Future<({User user, String token})> register({
    required String name,
    required String email,
    required String password,
  });

  /// Autentica al usuario y devuelve la entidad junto con el token JWT.
  ///
  /// [throws] AppError.unauthorized si las credenciales son incorrectas.
  Future<({User user, String token})> login({
    required String email,
    required String password,
  });

  /// Valida el token almacenado y devuelve el usuario autenticado actual.
  ///
  /// [throws] AppError.unauthorized si el token es inválido o ha expirado.
  Future<User> validateToken();

  /// Renueva el token JWT actual con expiración fresca (30d) y persiste el
  /// nuevo token en almacenamiento seguro.
  ///
  /// [throws] AppError.unauthorized si el token actual ha expirado/inválido.
  /// [throws] AppError.notFound si el usuario ya no existe (soft-deleted).
  Future<({User user, String token})> refreshToken();

  /// Cierra la sesión local (borra tokens del almacenamiento seguro).
  Future<void> logout();
}
