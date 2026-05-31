/// @file refresh_token_use_case.dart
/// @description Implementación del caso de uso de auto-refresh del token.
/// Encapsula la decisión "si quedan <7 días para expirar, llamar a /auth/refresh".
/// @module Core
/// @layer Domain
library;

import '../../../core/storage/auth_local_data_source.dart';
import '../../../core/utils/jwt_decoder.dart';
import '../../interfaces/usecases/auth/i_refresh_token_use_case.dart';
import '../../repositories/i_auth_repository.dart';

/// [implements] IRefreshTokenUseCase
/// [dependencies] IAuthRepository, AuthLocalDataSource
class RefreshTokenUseCase implements IRefreshTokenUseCase {
  final IAuthRepository      _repository;
  final AuthLocalDataSource  _local;

  const RefreshTokenUseCase({
    required IAuthRepository     repository,
    required AuthLocalDataSource local,
  })  : _repository = repository,
        _local      = local;

  @override
  Future<bool> execute({double refreshThresholdDays = 7.0}) async {
    final token = await _local.getAccessToken();
    if (token == null || token.isEmpty) return false;

    final daysLeft = jwtDaysUntilExpiry(token);
    // Sin `exp` legible o ya expirado: deja que el backend decida — no
    // intentamos refrescar proactivamente (si daysLeft <= 0 el backend
    // ya rechazará validateToken con 401 y la sesión se limpiará).
    if (daysLeft == null) return false;
    if (daysLeft >= refreshThresholdDays) return false;

    await _repository.refreshToken();
    return true;
  }
}
