/// @file i_get_my_profile_use_case.dart
/// @description Interfaz: Obtiene el perfil del usuario autenticado.
/// @module User
/// @layer Domain
library;

import '../../../../domain/entities/user.dart';

abstract interface class IGetMyProfileUseCase {
  /// Obtiene el perfil del usuario autenticado.
  ///
  /// [throws] AppError.unauthorized si el token ha expirado.
  Future<User> execute();
}
