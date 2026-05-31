/// @file i_login_use_case.dart
/// @description Interfaz del caso de uso de login.
/// @module Core
/// @layer Domain
library;

import '../../../dtos/auth/login_request_dto.dart';
import '../../../entities/user.dart';

/// Contrato del caso de uso de autenticación.
abstract interface class ILoginUseCase {
  /// Autentica al usuario con email y contraseña.
  ///
  /// [returns] entidad [User] autenticada junto con el token JWT.
  /// [throws] AppError.unauthorized — credenciales incorrectas.
  Future<({User user, String token})> execute(LoginRequestDto dto);
}
