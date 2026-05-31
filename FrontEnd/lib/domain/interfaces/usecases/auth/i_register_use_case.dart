/// @file i_register_use_case.dart
/// @description Interfaz del caso de uso de registro de usuario.
/// @module Core
/// @layer Domain
library;

import '../../../dtos/auth/register_request_dto.dart';
import '../../../entities/user.dart';

/// Contrato del caso de uso de registro.
///
/// El ViewModel depende de esta interfaz, no de la implementación concreta.
abstract interface class IRegisterUseCase {
  /// Registra un nuevo usuario.
  ///
  /// [returns] entidad [User] creada junto con el token JWT.
  /// [throws] AppError.validation — datos inválidos.
  /// [throws] AppError.network    — sin conexión.
  Future<({User user, String token})> execute(RegisterRequestDto dto);
}
