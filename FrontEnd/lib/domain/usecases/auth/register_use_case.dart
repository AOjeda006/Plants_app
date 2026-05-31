/// @file register_use_case.dart
/// @description Implementación del caso de uso de registro.
/// @module Core
/// @layer Domain
library;

import '../../dtos/auth/register_request_dto.dart';
import '../../entities/user.dart';
import '../../interfaces/usecases/auth/i_register_use_case.dart';
import '../../repositories/i_auth_repository.dart';

/// [implements] IRegisterUseCase
/// [dependencies] IAuthRepository
class RegisterUseCase implements IRegisterUseCase {
  final IAuthRepository _repository;
  const RegisterUseCase({required IAuthRepository repository}) : _repository = repository;

  @override
  Future<({User user, String token})> execute(RegisterRequestDto dto) =>
      _repository.register(name: dto.name, email: dto.email, password: dto.password);
}
