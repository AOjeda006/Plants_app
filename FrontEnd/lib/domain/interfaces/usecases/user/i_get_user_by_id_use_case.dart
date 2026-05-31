/// @file i_get_user_by_id_use_case.dart
/// @description Interfaz: Obtiene el perfil público de un usuario por ID.
/// @module User
/// @layer Domain
library;

import '../../../../domain/entities/user.dart';

abstract interface class IGetUserByIdUseCase {
  /// Obtiene el perfil público de un usuario por ID.
  ///
  /// [throws] AppError.notFound si el usuario no existe.
  Future<User> execute(String userId);
}
