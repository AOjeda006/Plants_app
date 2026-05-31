/// @file i_user_mapper.dart
/// @description Interfaz del mapper de usuario. Define el contrato de conversión
/// entre UserModel (capa de datos) y User (entidad de dominio).
/// Los repositorios dependen de esta interfaz, no de la implementación concreta.
/// @module Core
/// @layer Data
library;

import '../../domain/entities/user.dart';
import '../models/user_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I USER MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato de conversión bidireccional UserModel ↔ User.
///
/// [implements] registrar implementación en container.dart.
abstract interface class IUserMapper {
  /// Convierte un [UserModel] (serialización de API) a una entidad [User] de dominio.
  User toEntity(UserModel model);

  /// Convierte una entidad [User] de dominio a [UserModel] para serialización.
  UserModel toModel(User entity);
}
