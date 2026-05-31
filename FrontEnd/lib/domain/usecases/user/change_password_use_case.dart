/// @file change_password_use_case.dart
/// @description Caso de uso para cambiar la contraseña del usuario autenticado.
/// @module User
/// @layer Domain
library;

import '../../interfaces/usecases/user/i_change_password_use_case.dart';
import '../../repositories/i_user_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CHANGE PASSWORD USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Cambia la contraseña del usuario autenticado.
///
/// [implements] IChangePasswordUseCase
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] IUserRepository.
class ChangePasswordUseCase implements IChangePasswordUseCase {
  final IUserRepository _repository;

  const ChangePasswordUseCase({required IUserRepository repository})
      : _repository = repository;

  /// [param] currentPassword — contraseña actual del usuario.
  /// [param] newPassword     — nueva contraseña deseada.
  /// [throws] AppError.validation si la contraseña actual es incorrecta.
  @override
  Future<void> execute(String currentPassword, String newPassword) =>
      _repository.changePassword(currentPassword, newPassword);
}
