/// @file get_user_by_id_use_case.dart
/// @description Caso de uso para obtener el perfil público de un usuario por ID.
/// @module User
/// @layer Domain
library;

import '../../entities/user.dart';
import '../../interfaces/usecases/user/i_get_user_by_id_use_case.dart';
import '../../repositories/i_user_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GET USER BY ID USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Obtiene el perfil público de un usuario por su ID.
///
/// [implements] IGetUserByIdUseCase
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] IUserRepository.
class GetUserByIdUseCase implements IGetUserByIdUseCase {
  final IUserRepository _repository;

  const GetUserByIdUseCase({required IUserRepository repository})
      : _repository = repository;

  /// [param] userId — MongoDB ObjectId del usuario.
  /// [returns] [User] con el perfil público del usuario.
  /// [throws]  AppError.notFound si el usuario no existe.
  @override
  Future<User> execute(String userId) => _repository.getUserById(userId);
}
