/// @file login_use_case.dart
/// @description Implementación del caso de uso de login.
/// @module Core
/// @layer Domain
library;

import '../../dtos/auth/login_request_dto.dart';
import '../../entities/user.dart';
import '../../interfaces/usecases/auth/i_login_use_case.dart';
import '../../repositories/i_auth_repository.dart';

/// [implements] ILoginUseCase
/// [dependencies] IAuthRepository
class LoginUseCase implements ILoginUseCase {
  final IAuthRepository _repository;
  const LoginUseCase({required IAuthRepository repository}) : _repository = repository;

  @override
  Future<({User user, String token})> execute(LoginRequestDto dto) =>
      _repository.login(email: dto.email, password: dto.password);
}
