/// @file update_user_preferences_use_case.dart
/// @description Caso de uso para actualizar las preferencias del usuario.
/// @module User
/// @layer Domain
library;

import '../../dtos/user/update_preferences_request_dto.dart';
import '../../entities/user.dart';
import '../../interfaces/usecases/user/i_update_user_preferences_use_case.dart';
import '../../repositories/i_user_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// UPDATE USER PREFERENCES USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Actualiza las preferencias del usuario autenticado.
///
/// [implements] IUpdateUserPreferencesUseCase
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] IUserRepository.
class UpdateUserPreferencesUseCase implements IUpdateUserPreferencesUseCase {
  final IUserRepository _repository;

  const UpdateUserPreferencesUseCase({required IUserRepository repository})
      : _repository = repository;

  /// [param] dto — preferencias a actualizar.
  /// [returns] [User] con las preferencias actualizadas.
  @override
  Future<User> execute(UpdatePreferencesRequestDto dto) =>
      _repository.updatePreferences(dto);
}
