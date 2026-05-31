/// @file i_validate_token_use_case.dart
/// @description Interfaz del caso de uso de validación de token JWT.
/// @module Core
/// @layer Domain
library;

import '../../../entities/user.dart';

/// Contrato del caso de uso de validación de sesión.
abstract interface class IValidateTokenUseCase {
  /// Valida el token almacenado y devuelve el usuario autenticado.
  ///
  /// [throws] AppError.unauthorized — token inválido o expirado.
  Future<User> execute();
}
