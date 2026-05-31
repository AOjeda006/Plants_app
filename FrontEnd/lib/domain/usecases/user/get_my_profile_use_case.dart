/// @file get_my_profile_use_case.dart
/// @description Caso de uso para obtener el perfil del usuario autenticado.
/// @module User
/// @layer Domain
library;

import '../../entities/user.dart';
import '../../interfaces/usecases/user/i_get_my_profile_use_case.dart';
import '../../repositories/i_user_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GET MY PROFILE USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Obtiene el perfil completo del usuario autenticado.
///
/// [implements] IGetMyProfileUseCase
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] IUserRepository.
class GetMyProfileUseCase implements IGetMyProfileUseCase {
  final IUserRepository _repository;

  const GetMyProfileUseCase({required IUserRepository repository})
      : _repository = repository;

  /// [returns] [User] con el perfil completo del usuario autenticado.
  /// [throws]  AppError.unauthorized si el token ha expirado.
  @override
  Future<User> execute() => _repository.getMyProfile();
}
