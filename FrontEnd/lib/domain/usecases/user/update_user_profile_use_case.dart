/// @file update_user_profile_use_case.dart
/// @description Caso de uso para actualizar el perfil del usuario autenticado.
/// @module User
/// @layer Domain
library;

import '../../dtos/user/update_profile_request_dto.dart';
import '../../entities/user.dart';
import '../../interfaces/usecases/user/i_update_user_profile_use_case.dart';
import '../../repositories/i_user_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// UPDATE USER PROFILE USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Actualiza el perfil del usuario autenticado.
///
/// [implements] IUpdateUserProfileUseCase
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] IUserRepository.
class UpdateUserProfileUseCase implements IUpdateUserProfileUseCase {
  final IUserRepository _repository;

  const UpdateUserProfileUseCase({required IUserRepository repository})
      : _repository = repository;

  /// [param] dto — campos a actualizar (todos opcionales).
  /// [returns] [User] con los datos actualizados.
  /// [throws]  AppError.validation si los datos no pasan validación del backend.
  @override
  Future<User> execute(UpdateProfileRequestDto dto) =>
      _repository.updateProfile(dto);
}
