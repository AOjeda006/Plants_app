/// @file i_update_user_profile_use_case.dart
/// @description Interfaz: Actualiza los datos de perfil del usuario.
/// @module User
/// @layer Domain
library;

import '../../../../domain/dtos/user/update_profile_request_dto.dart';
import '../../../../domain/entities/user.dart';

abstract interface class IUpdateUserProfileUseCase {
  /// Actualiza los datos de perfil del usuario autenticado.
  ///
  /// [param] dto — campos a actualizar (todos opcionales).
  /// [returns] [User] con los datos actualizados.
  Future<User> execute(UpdateProfileRequestDto dto);
}
