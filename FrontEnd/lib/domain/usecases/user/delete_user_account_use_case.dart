/// @file delete_user_account_use_case.dart
/// @description Caso de uso para eliminar (soft-delete) la cuenta del usuario.
/// @module User
/// @layer Domain
library;

import '../../interfaces/usecases/user/i_delete_user_account_use_case.dart';
import '../../repositories/i_user_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DELETE USER ACCOUNT USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Elimina (soft-delete) la cuenta del usuario autenticado.
///
/// [implements] IDeleteUserAccountUseCase
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] IUserRepository.
class DeleteUserAccountUseCase implements IDeleteUserAccountUseCase {
  final IUserRepository _repository;

  const DeleteUserAccountUseCase({required IUserRepository repository})
      : _repository = repository;

  /// [param] password        — contraseña actual para confirmar la eliminación.
  /// [param] preserveContent — si true, mantiene publicaciones/comentarios de forma anónima.
  /// [throws] AppError.validation si la contraseña es incorrecta.
  @override
  Future<void> execute(String password, {bool preserveContent = false}) =>
      _repository.deleteAccount(password, preserveContent: preserveContent);
}
