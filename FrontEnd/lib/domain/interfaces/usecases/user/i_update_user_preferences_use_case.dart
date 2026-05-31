/// @file i_update_user_preferences_use_case.dart
/// @description Interfaz: Actualiza las preferencias del usuario.
/// @module User
/// @layer Domain
library;

import '../../../../domain/dtos/user/update_preferences_request_dto.dart';
import '../../../../domain/entities/user.dart';

abstract interface class IUpdateUserPreferencesUseCase {
  /// Actualiza las preferencias del usuario autenticado.
  ///
  /// [param] dto — preferencias a actualizar.
  /// [returns] [User] con las preferencias actualizadas.
  Future<User> execute(UpdatePreferencesRequestDto dto);
}
