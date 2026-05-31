/// @file auth_repository_impl.dart
/// @description Implementación del repositorio de autenticación.
/// Coordina AuthRemoteDataSource (API) y AuthLocalDataSource (SecureStorage).
/// Convierte los Map crudos de la API a entidades de dominio usando IUserMapper.
/// @module Core
/// @layer Data
library;

import '../../core/storage/auth_local_data_source.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote/auth_remote_data_source.dart';
import '../i_mappers/i_user_mapper.dart';
import '../models/user_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación concreta de [IAuthRepository].
///
/// [implements] IAuthRepository
/// [injectable] registrar en container.dart.
/// [dependencies] AuthRemoteDataSource, AuthLocalDataSource, IUserMapper.
class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource  _remote;
  final AuthLocalDataSource   _local;
  final IUserMapper           _mapper;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource  local,
    required IUserMapper          mapper,
  })  : _remote = remote,
        _local  = local,
        _mapper = mapper;

  // ─── Register ────────────────────────────────────────────────────────────────

  @override
  Future<({User user, String token})> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _remote.register(
      name: name, email: email, password: password,
    );
    final user  = _mapper.toEntity(UserModel.fromJson(data['user'] as Map<String, dynamic>));
    final token = data['token'] as String;

    // Persistir sesión localmente tras registro exitoso.
    await _local.saveTokens(
      accessToken: token,
      userId:      user.id,
    );

    return (user: user, token: token);
  }

  // ─── Login ────────────────────────────────────────────────────────────────────

  @override
  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) async {
    final data  = await _remote.login(email: email, password: password);
    final user  = _mapper.toEntity(UserModel.fromJson(data['user'] as Map<String, dynamic>));
    final token = data['token'] as String;

    await _local.saveTokens(
      accessToken: token,
      userId:      user.id,
    );

    return (user: user, token: token);
  }

  // ─── Validate token ───────────────────────────────────────────────────────────

  @override
  Future<User> validateToken() async {
    final data = await _remote.validateToken();
    // El endpoint GET /auth/validate-token devuelve el user object
    // DIRECTAMENTE (sin wrapper `{user: ...}`), mientras que
    // /auth/login y /auth/refresh sí lo envuelven. Toleramos ambos
    // formatos por robustez: sin esta normalización un cast erróneo
    // lanzaría TypeError, que `AuthViewModel.checkSession` no capturaría
    // (try/catch solo atrapa AppError), y la sesión nunca pasaría a
    // `authenticated` pese al validate-token 200 del backend.
    final userMap = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;
    return _mapper.toEntity(UserModel.fromJson(userMap));
  }

  // ─── Refresh token ────────────────────────────────────────────────────────────

  @override
  Future<({User user, String token})> refreshToken() async {
    final data  = await _remote.refreshToken();
    final user  = _mapper.toEntity(UserModel.fromJson(data['user'] as Map<String, dynamic>));
    final token = data['token'] as String;

    // Sustituye el token guardado por el nuevo. Mantiene userId y refreshToken
    // existentes (saveTokens omite los argumentos opcionales no pasados).
    await _local.saveTokens(accessToken: token);

    return (user: user, token: token);
  }

  // ─── Logout ───────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() => _local.clear();
}
