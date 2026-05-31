/// @file validate_token_use_case.dart
/// @description Implementación del caso de uso de validación de token.
/// @module Core
/// @layer Domain
library;

import '../../entities/user.dart';
import '../../interfaces/usecases/auth/i_validate_token_use_case.dart';
import '../../repositories/i_auth_repository.dart';

/// [implements] IValidateTokenUseCase
/// [dependencies] IAuthRepository
class ValidateTokenUseCase implements IValidateTokenUseCase {
  final IAuthRepository _repository;
  const ValidateTokenUseCase({required IAuthRepository repository}) : _repository = repository;

  @override
  Future<User> execute() => _repository.validateToken();
}
